import os
import numpy as np
import onnxruntime as ort
from tokenizers import Tokenizer
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List

app = FastAPI(title="CulpeoStudio Embedding Sidecar")

MODEL_DIR = os.path.join(os.path.dirname(__file__), "model")
MODEL_PATH = os.path.join(MODEL_DIR, "model.onnx")
TOKENIZER_PATH = os.path.join(MODEL_DIR, "tokenizer.json")


tokenizer = None
ort_session = None

def init_inference():
    global tokenizer, ort_session
    if ort_session is not None:
        return
    if not os.path.exists(MODEL_PATH) or not os.path.exists(TOKENIZER_PATH):
        raise RuntimeError(
            f"Model weights not found. Please run download_model.py first. "
            f"Expected paths: {MODEL_PATH}, {TOKENIZER_PATH}"
        )
    print("Loading tokenizer...")
    tokenizer = Tokenizer.from_file(TOKENIZER_PATH)

    tokenizer.enable_truncation(max_length=256)
    tokenizer.enable_padding(pad_id=0, pad_token="[PAD]")

    print("Loading ONNX runtime session...")

    ort_session = ort.InferenceSession(MODEL_PATH, providers=["CPUExecutionProvider"])

class EmbedRequest(BaseModel):
    texts: List[str]

class EmbedResponse(BaseModel):
    embeddings: List[List[float]]

@app.on_event("startup")
async def startup_event():
    try:
        init_inference()
    except Exception as e:
        print(f"Startup initialization failed: {e}")

@app.post("/embed", response_model=EmbedResponse)
async def embed(request: EmbedRequest):
    if not request.texts:
        return EmbedResponse(embeddings=[])

    try:
        init_inference()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Inference session not initialized: {e}")

    try:

        encodings = tokenizer.encode_batch(request.texts)

        input_ids = np.array([e.ids for e in encodings], dtype=np.int64)
        attention_mask = np.array([e.attention_mask for e in encodings], dtype=np.int64)
        token_type_ids = np.array([e.type_ids for e in encodings], dtype=np.int64)


        inputs = {
            "input_ids": input_ids,
            "attention_mask": attention_mask,
        }


        model_inputs = [inp.name for inp in ort_session.get_inputs()]
        if "token_type_ids" in model_inputs:
            inputs["token_type_ids"] = token_type_ids


        outputs = ort_session.run(None, inputs)

        token_embeddings = outputs[0]


        input_mask_expanded = np.expand_dims(attention_mask, -1).astype(float)
        sum_embeddings = np.sum(token_embeddings * input_mask_expanded, axis=1)
        sum_mask = np.clip(np.sum(input_mask_expanded, axis=1), a_min=1e-9, a_max=None)
        sentence_embeddings = sum_embeddings / sum_mask


        norms = np.linalg.norm(sentence_embeddings, axis=1, keepdims=True)
        norms = np.clip(norms, a_min=1e-9, a_max=None)
        normalized_embeddings = (sentence_embeddings / norms).tolist()

        return EmbedResponse(embeddings=normalized_embeddings)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Embedding generation failed: {e}")

@app.get("/health")
async def health():
    try:
        init_inference()
        return {"status": "ready", "model": "all-MiniLM-L6-v2"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8092)
