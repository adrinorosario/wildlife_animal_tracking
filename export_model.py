"""
Export BioCLIP-2 visual encoder using old-style ONNX export.
"""
import torch
import open_clip
import os
import sys

def export_model():
    print("Loading BioCLIP 2 model...")
    model_name = 'hf-hub:imageomics/bioclip-2'
    model, _, preprocess_val = open_clip.create_model_and_transforms(model_name, device='cpu')
    model.eval()

    class VisualEncoder(torch.nn.Module):
        def __init__(self, clip_model):
            super().__init__()
            self.visual = clip_model.visual
        
        def forward(self, x):
            return self.visual(x)

    visual = VisualEncoder(model)
    visual.eval()

    dummy = torch.randn(1, 3, 224, 224)
    with torch.no_grad():
        test_out = visual(dummy)
    print(f"PyTorch: shape={test_out.shape}, mag={test_out.norm():.4f}")

    total_params = sum(p.numel() for p in visual.parameters())
    print(f"Params: {total_params:,} ({total_params * 4 / 1024**2:.1f} MB fp32)")

    output_path = 'assets/models/bioclip2_visual_fp32.onnx'
    
    # Force old-style export by monkeypatching
    # In newer torch, torch.onnx.export delegates to the dynamo exporter
    # We need to directly call the old JIT-based exporter
    print("Exporting with old-style JIT exporter...")
    try:
        from torch.onnx import utils as onnx_utils
        onnx_utils.export(
            visual,
            dummy,
            output_path,
            input_names=['pixel_values'],
            output_names=['image_features'],
            opset_version=17,
            do_constant_folding=True,
        )
    except Exception as e1:
        print(f"utils.export failed: {e1}")
        print("Trying _export...")
        try:
            torch.onnx._export(
                visual,
                dummy,
                output_path,
                input_names=['pixel_values'],
                output_names=['image_features'],
                opset_version=17,
                do_constant_folding=True,
            )
        except Exception as e2:
            print(f"_export also failed: {e2}")
            # Last resort: try with dynamo but opset 17
            print("Trying standard export with opset 17...")
            torch.onnx.export(
                visual,
                dummy,
                output_path,
                input_names=['pixel_values'],
                output_names=['image_features'],
                opset_version=17,
            )

    file_size_mb = os.path.getsize(output_path) / (1024 * 1024)
    print(f"\nExported: {output_path} ({file_size_mb:.1f} MB)")
    
    if file_size_mb < 10:
        print("⚠️ File too small!")
        # Check for external data files
        data_file = output_path + '.data'
        if os.path.exists(data_file):
            data_size = os.path.getsize(data_file) / (1024**2)
            print(f"Found external data: {data_file} ({data_size:.1f} MB)")
            # Merge external data into the model
            print("Merging external data into model...")
            import onnx
            onnx_model = onnx.load(output_path)
            # Convert to model with all data internal  
            from onnx.external_data_helper import convert_model_to_external_data, load_external_data_for_model
            load_external_data_for_model(onnx_model, os.path.dirname(output_path))
            onnx.save_model(onnx_model, output_path, save_as_external_data=False)
            new_size = os.path.getsize(output_path) / (1024**2)
            print(f"After merge: {new_size:.1f} MB")
            file_size_mb = new_size
        
        # Also check for *.weight files  
        model_dir = os.path.dirname(output_path)
        for f in os.listdir(model_dir):
            if f.endswith('.weight') or f.endswith('.data') or f.endswith('.pb'):
                fsize = os.path.getsize(os.path.join(model_dir, f)) / (1024**2)
                print(f"  Found: {f} ({fsize:.1f} MB)")
    else:
        print("✅ File size looks correct!")
    
    # Verify
    if file_size_mb >= 10:
        import onnxruntime as ort
        import numpy as np
        
        print("\nVerifying...")
        session = ort.InferenceSession(output_path)
        inp_name = session.get_inputs()[0].name
        result = session.run(None, {inp_name: dummy.numpy()})
        onnx_out = result[0]
        max_diff = abs(test_out.numpy().astype(float) - onnx_out.astype(float)).max()
        print(f"Max diff (vs PyTorch): {max_diff:.6f}")

        # Stability test
        embeddings = []
        for trial in range(5):
            rand = np.random.randn(1, 3, 224, 224).astype(np.float32) * 0.5
            result = session.run(None, {inp_name: rand})
            emb = result[0][0].astype(float)
            emb_n = emb / np.linalg.norm(emb)
            embeddings.append(emb_n)

        cos_sims = []
        for i in range(len(embeddings)):
            for j in range(i+1, len(embeddings)):
                cos_sims.append(np.dot(embeddings[i], embeddings[j]))
        print(f"Stability: pairwise cos_sim min={min(cos_sims):.4f}, max={max(cos_sims):.4f}")
        if max(cos_sims) < 0.90:
            print("✅ Model produces varied outputs - WORKING!")
        else:
            print("⚠️ Model outputs too similar")

if __name__ == "__main__":
    export_model()
