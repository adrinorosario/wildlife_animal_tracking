
import json
import torch
import open_clip

def generate_embeddings():
    print("Loading species labels...")
    try:
        with open('species_labels.json', 'r') as f:
            species_names = json.load(f)
    except FileNotFoundError:
        print("species_labels.json not found.")
        return

    print(f"Loaded {len(species_names)} species.")

    print("Loading BioCLIP 2 model...")
    model_name = 'hf-hub:imageomics/bioclip-2'
    # Use CPU to avoid CUDA dependency issues in this environment if any
    model, _, _ = open_clip.create_model_and_transforms(model_name, device='cpu')
    tokenizer = open_clip.get_tokenizer(model_name)
    model.eval()

    print("Generating prompts...")
    # Assuming the species_labels.json contains just names. 
    # BioCLIP works best with a prompt like "a photo of {name}".
    # The user's script used "a photo of {name}, a type of {supercategory}".
    # Since we only have names in species_labels.json, we will use "a photo of {name}".
    prompts = [f"a photo of {name}" for name in species_names]

    print("Encoding text...")
    batch_size = 100
    all_features = []

    with torch.no_grad():
        for i in range(0, len(prompts), batch_size):
            batch = prompts[i:i+batch_size]
            tokens = tokenizer(batch)
            features = model.encode_text(tokens)
            features /= features.norm(dim=-1, keepdim=True)
            all_features.append(features)
            print(f"Processed {min(i+batch_size, len(prompts))}/{len(prompts)}")

    print("Concatenating features...")
    final_features = torch.cat(all_features).tolist()

    print("Saving embeddings to species_embeddings.json...")
    with open('assets/models/species_embeddings.json', 'w') as f:
        json.dump(final_features, f)

    print("Done!")

if __name__ == "__main__":
    generate_embeddings()
