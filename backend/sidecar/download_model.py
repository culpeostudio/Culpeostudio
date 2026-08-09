import os
import urllib.request

MODEL_DIR = os.path.join(os.path.dirname(__file__), "model")

FILES = {
    "model.onnx": "https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/main/onnx/model.onnx",
    "tokenizer.json": "https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/main/tokenizer.json",
}

def download_model():
    os.makedirs(MODEL_DIR, exist_ok=True)
    for filename, url in FILES.items():
        dest = os.path.join(MODEL_DIR, filename)
        if os.path.exists(dest):
            print(f"{filename} already exists, skipping.")
            continue
        print(f"Downloading {filename} from {url}...")
        try:
            urllib.request.urlretrieve(url, dest)
            print(f"Successfully downloaded {filename}.")
        except Exception as e:
            print(f"Failed to download {filename}: {e}")
            raise e

if __name__ == "__main__":
    download_model()
