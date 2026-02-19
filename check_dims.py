
import open_clip
import torch

def check_model():
    model_name = 'hf-hub:imageomics/bioclip-2'
    print(f"Creating model: {model_name}")
    model, _, _ = open_clip.create_model_and_transforms(model_name, device='cpu')
    model.eval()

    print(f"Visual Config: {model.visual.image_size}")
    # Inspect embedding dimension
    # Clip models usually have 'embed_dim' attribute
    try:
        print(f"Projected Dim: {model.visual.output_dim}") 
    except AttributeError:
        print("Attribute output_dim not found.")

    # Check output of encode_text
    tokenizer = open_clip.get_tokenizer('hf-hub:imageomics/bioclip-2')
    text = tokenizer(["a photo of a human"])
    with torch.no_grad():
        text_features = model.encode_text(text)
        print(f"Text Feature Shape: {text_features.shape}")
        
    # Check output of encode_image (dummy)
    dummy_image = torch.randn(1, 3, 224, 224)
    with torch.no_grad():
        image_features = model.encode_image(dummy_image)
        print(f"Image Feature Shape: {image_features.shape}")

if __name__ == "__main__":
    check_model()
