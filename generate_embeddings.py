
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

    prompts = []
    for name in species_names:
        if name == "Human":
            # Add multiple prompts for Human to catch different phrases
            # We will average the embeddings later or just rely on the best match mechanism if we expanded the labels list.
            # But here `species_names` and `prompts` must alignment 1:1 for the current app logic (index based).
            # So we will try to make the SINGLE prompt as robust as possible.
            prompts.append("a photo of a human person man woman child Homo sapiens")
        else:
            prompts.append(f"a photo of {name}")

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
