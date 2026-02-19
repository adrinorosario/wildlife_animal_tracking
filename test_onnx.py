"""
Test the INT8 ONNX model with proper CLIP preprocessing.
This simulates exactly what the Dart app does, but using proper Python CLIP transforms.
"""
import json
import numpy as np
import onnxruntime as ort
import torch
import open_clip
from PIL import Image

def test_onnx_int8():
    print("=== INT8 ONNX MODEL DIAGNOSTIC ===\n")
    
    # Load model
    print("Loading int8 ONNX model...")
    session = ort.InferenceSession('assets/models/bioclip2_model_int8.onnx')
    input_name = session.get_inputs()[0].name
    input_shape = session.get_inputs()[0].shape
    output_shape = session.get_outputs()[0].shape
    print(f"  Input: {input_name}, shape: {input_shape}")
    print(f"  Output: {session.get_outputs()[0].name}, shape: {output_shape}")
    
    # Load labels and embeddings
    with open('species_labels.json', 'r') as f:
        species_names = json.load(f)
    with open('assets/models/species_embeddings.json', 'r') as f:
        text_embeddings = np.array(json.load(f), dtype=np.float32)
    print(f"  Labels: {len(species_names)}, Embeddings: {text_embeddings.shape}")
    
    # Load CLIP transforms for reference
    model_name = 'hf-hub:imageomics/bioclip-2'
    _, _, preprocess_val = open_clip.create_model_and_transforms(model_name, device='cpu')
    
    # Create a synthetic "person-like" image (skin-tone rectangle with face-like features)
    # Since we can't download, we'll generate a controlled test pattern
    print("\n--- Test 1: Random noise (sanity check) ---")
    dummy = np.random.randn(1, 3, 224, 224).astype(np.float32)
    result = session.run(None, {input_name: dummy})
    emb = result[0][0]
    magnitude = np.linalg.norm(emb)
    print(f"  Embedding magnitude: {magnitude:.4f}")
    
    # Normalize and match
    emb_norm = emb / magnitude if magnitude > 0 else emb
    scores = (emb_norm @ text_embeddings.T) * 100.0
    top5_idx = np.argsort(scores)[::-1][:5]
    for i, idx in enumerate(top5_idx):
        print(f"  {i+1}. {species_names[idx]}: {scores[idx]:.2f}%")
    
    # Test 2: Check if ONNX model produces varied outputs for varied inputs
    print("\n--- Test 2: Stability check (5 different random inputs) ---")
    embeddings_produced = []
    for trial in range(5):
        dummy = np.random.randn(1, 3, 224, 224).astype(np.float32) * 0.5
        result = session.run(None, {input_name: dummy})
        emb = result[0][0]
        mag = np.linalg.norm(emb)
        emb_n = emb / mag if mag > 0 else emb
        embeddings_produced.append(emb_n)
        top_idx = np.argsort(emb_n @ text_embeddings.T)[::-1][0]
        top_score = (emb_n @ text_embeddings.T * 100.0)[top_idx]
        print(f"  Trial {trial+1}: mag={mag:.2f}, top={species_names[top_idx]} ({top_score:.1f}%)")
    
    # Check if outputs are all the same (would indicate broken model)
    cos_sims = []
    for i in range(len(embeddings_produced)):
        for j in range(i+1, len(embeddings_produced)):
            cos_sims.append(np.dot(embeddings_produced[i], embeddings_produced[j]))
    print(f"  Pairwise cosine sims between outputs: min={min(cos_sims):.4f}, max={max(cos_sims):.4f}")
    if max(cos_sims) > 0.999:
        print("  ⚠️ WARNING: Model outputs are nearly identical regardless of input!")
        print("  This suggests the model is broken or ignoring input pixels.")
    
    # Test 3: What does a properly normalized image look like?
    print("\n--- Test 3: Properly normalized input (CLIP mean/std) ---")
    mean = np.array([0.48145466, 0.4578275, 0.40821073]).reshape(3, 1, 1)
    std = np.array([0.26862954, 0.26130258, 0.27577711]).reshape(3, 1, 1)
    
    # Simulate a "warm skin tone" image
    # Skin tone RGB ~ (240, 200, 170) / 255 = (0.94, 0.78, 0.67)
    skin = np.zeros((1, 3, 224, 224), dtype=np.float32)
    skin[0, 0, :, :] = (0.94 - mean[0]) / std[0]  # R
    skin[0, 1, :, :] = (0.78 - mean[1]) / std[1]  # G  
    skin[0, 2, :, :] = (0.67 - mean[2]) / std[2]  # B
    
    result = session.run(None, {input_name: skin})
    emb = result[0][0]
    magnitude = np.linalg.norm(emb)
    emb_norm = emb / magnitude if magnitude > 0 else emb
    scores = (emb_norm @ text_embeddings.T) * 100.0
    top5_idx = np.argsort(scores)[::-1][:5]
    
    print(f"  Embedding magnitude: {magnitude:.4f}")
    for i, idx in enumerate(top5_idx):
        print(f"  {i+1}. {species_names[idx]}: {scores[idx]:.2f}%")
    
    # Human rank
    human_idx = species_names.index("Human")
    human_rank = int(np.sum(scores > scores[human_idx])) + 1
    print(f"  Human rank: #{human_rank} ({scores[human_idx]:.2f}%)")

if __name__ == "__main__":
    test_onnx_int8()
