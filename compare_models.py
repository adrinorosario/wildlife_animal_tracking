"""Compare int8 vs fp32 ONNX model quality with CLIP-normalized inputs."""
import numpy as np
import onnxruntime as ort
import json

def compare():
    with open('species_labels.json') as f:
        labels = json.load(f)
    with open('assets/models/species_embeddings.json') as f:
        text_emb = np.array(json.load(f), dtype=np.float32)

    mean = np.array([0.48145466, 0.4578275, 0.40821073]).reshape(3, 1, 1)
    std = np.array([0.26862954, 0.26130258, 0.27577711]).reshape(3, 1, 1)

    # Create test images: skin tone, green foliage, blue sky
    tests = {
        "skin_tone": ((0.94, 0.78, 0.67), "Should lean toward mammals/humans"),
        "green_foliage": ((0.2, 0.6, 0.2), "Should lean toward plants"),
        "blue_sky": ((0.5, 0.7, 0.95), "Should lean toward birds"),
        "orange_fur": ((0.9, 0.5, 0.1), "Should lean toward mammals"),
    }

    for model_name, path in [("INT8", "assets/models/bioclip2_model_int8.onnx"),
                              ("FP32", "assets/models/bioclip2_visual_fp32.onnx")]:
        print(f"\n{'='*60}")
        print(f"MODEL: {model_name} ({path})")
        print(f"{'='*60}")
        session = ort.InferenceSession(path)
        inp_name = session.get_inputs()[0].name

        for test_name, (rgb, desc) in tests.items():
            img = np.zeros((1, 3, 224, 224), dtype=np.float32)
            img[0, 0] = (rgb[0] - mean[0]) / std[0]
            img[0, 1] = (rgb[1] - mean[1]) / std[1]
            img[0, 2] = (rgb[2] - mean[2]) / std[2]

            result = session.run(None, {inp_name: img})
            emb = result[0][0].astype(np.float64)
            mag = np.linalg.norm(emb)
            emb_n = emb / mag if mag > 0 else emb
            scores = (emb_n @ text_emb.T.astype(np.float64)) * 100.0
            top3 = np.argsort(scores)[::-1][:3]

            print(f"\n  {test_name} ({desc}):")
            print(f"    Magnitude: {mag:.2f}")
            for i, idx in enumerate(top3):
                print(f"    {i+1}. {labels[idx]}: {scores[idx]:.2f}%")
            
            human_idx = labels.index("Human")
            human_rank = int(np.sum(scores > scores[human_idx])) + 1
            print(f"    Human: rank #{human_rank} ({scores[human_idx]:.2f}%)")

if __name__ == "__main__":
    compare()
