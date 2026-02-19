"""
Test BioCLIP model accuracy using Python (ground truth pipeline).
Uses a locally generated test image. This validates embeddings and labels.
"""
import json
import torch
import open_clip
from PIL import Image
import numpy as np

def test_model():
    print("Loading species labels...")
    with open('species_labels.json', 'r') as f:
        species_names = json.load(f)
    print(f"Loaded {len(species_names)} species.")

    print("Loading BioCLIP 2 model...")
    model_name = 'hf-hub:imageomics/bioclip-2'
    model, preprocess_train, preprocess_val = open_clip.create_model_and_transforms(model_name, device='cpu')
    tokenizer = open_clip.get_tokenizer(model_name)
    model.eval()

    # Print the transforms to see what CLIP expects
    print(f"\n--- OFFICIAL CLIP preprocess_val transforms ---")
    print(preprocess_val)

    # Create a synthetic test: encode text prompts directly and see similarity
    print("\n--- TEXT ENCODING DIAGNOSTIC ---")
    test_prompts = [
        "a photo of a human person man woman child Homo sapiens",
        "Human",
        "a photo of Human",
        "a photo of Homo sapiens (Animalia)",
        "a photo of Corvus splendens (Aves)",
        "a photo of Halcyon smyrnensis (Aves)",
        "a photo of Elephas maximus (Mammalia)",
        "a photo of Panthera leo (Mammalia)",
    ]
    tokens = tokenizer(test_prompts)
    with torch.no_grad():
        text_features = model.encode_text(tokens)
        text_features /= text_features.norm(dim=-1, keepdim=True)
    
    # Check pairwise similarity between our Human prompt and wildlife prompts
    human_embedding = text_features[0:1]  # Our actual prompt
    all_sims = (human_embedding @ text_features.T * 100.0).squeeze(0)
    print("Similarity of our Human prompt to other prompts:")
    for i, prompt in enumerate(test_prompts):
        print(f"  '{prompt}': {all_sims[i].item():.2f}%")

    # Load our precomputed text embeddings
    print("\n--- PRECOMPUTED EMBEDDINGS DIAGNOSTIC ---")
    with open('assets/models/species_embeddings.json', 'r') as f:
        text_embeddings = json.load(f)
    text_tensor = torch.tensor(text_embeddings)  # [N, 768]
    print(f"Text embeddings shape: {text_tensor.shape}")
    
    # Check the Human embedding (index 0)
    human_emb = text_tensor[0:1]
    human_norm = human_emb.norm().item()
    print(f"Human embedding norm: {human_norm:.6f}")
    
    # Check if Human embedding from file matches fresh encoding
    fresh_human_tokens = tokenizer(["a photo of a human person man woman child Homo sapiens"])
    with torch.no_grad():
        fresh_human_features = model.encode_text(fresh_human_tokens)
        fresh_human_features /= fresh_human_features.norm(dim=-1, keepdim=True)
    
    cosine_sim = (human_emb @ fresh_human_features.T).item()
    print(f"Cosine similarity (saved vs fresh Human embedding): {cosine_sim:.6f}")
    
    # Check cross-similarities: is our saved Human embedding close to wildlife?
    sims_to_saved = (human_emb @ text_tensor.T * 100.0).squeeze(0)
    topk = torch.topk(sims_to_saved, k=10)
    print("\nTop 10 labels most similar to Human embedding:")
    for i in range(10):
        idx = topk.indices[i].item()
        score = topk.values[i].item()
        label = species_names[idx]
        print(f"  {i+1}. {label}: {score:.2f}%")
    
    # Check variance of all text embeddings
    all_norms = text_tensor.norm(dim=-1)
    print(f"\nText embedding norms - min: {all_norms.min():.4f}, max: {all_norms.max():.4f}, mean: {all_norms.mean():.4f}")
    
    # Check if embeddings are all basically the same
    mean_emb = text_tensor.mean(dim=0, keepdim=True)
    mean_emb /= mean_emb.norm()
    avg_sim_to_mean = (text_tensor @ mean_emb.T).squeeze().mean().item() * 100
    print(f"Average similarity of all embeddings to centroid: {avg_sim_to_mean:.2f}%")
    
    # Show spread
    pairwise_sample = text_tensor[:100] @ text_tensor[:100].T
    off_diag = pairwise_sample[~torch.eye(100, dtype=bool)]
    print(f"Pairwise similarity (first 100) - min: {off_diag.min()*100:.2f}%, max: {off_diag.max()*100:.2f}%, mean: {off_diag.mean()*100:.2f}%")

if __name__ == "__main__":
    test_model()
