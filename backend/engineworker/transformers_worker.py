#!/usr/bin/env python3
"""Small local-only OpenAI-compatible worker for Transformers checkpoints.

The Go supervisor starts this file with a fixed argv in an isolated virtual
environment. Model weights are loaded exactly as stored; only the generation
KV-cache implementation may be changed.
"""

from __future__ import annotations

import argparse
import asyncio
import json
import queue
import secrets
import threading
import time
import uuid
from dataclasses import dataclass
from typing import Any, AsyncIterator, Awaitable, Callable, Iterator


@dataclass(frozen=True)
class WorkerConfig:
    model: str
    context_length: int
    kv_cache: str
    trust_remote_code: bool
    max_sequences: int
    # One byte limit per GPU after CUDA/ROCm visibility remapping. Empty keeps
    # the existing CPU-only/autodetected loading behaviour unchanged.
    gpu_max_memory_bytes: tuple[int, ...] = ()
    cpu_max_memory_bytes: int | None = None


@dataclass(frozen=True)
class PreparedGeneration:
    encoded: dict[str, Any]
    prompt_tokens: int
    max_tokens: int
    generation: dict[str, Any]


class ClientDisconnected(Exception):
    """Internal signal used to stop a generation without writing a final event."""


class ModelTokenStream:
    """Async adapter around Transformers' blocking ``TextIteratorStreamer``.

    The model itself runs on one background thread. Pulls from the streamer use
    a short timeout so that the ASGI disconnect state is observed even while a
    model is taking a long time to produce its next token.
    """

    def __init__(
        self,
        streamer: Iterator[str],
        cancel_event: threading.Event,
        finished_event: threading.Event,
        result: dict[str, Any],
        prompt_tokens: int,
        max_tokens: int,
    ) -> None:
        self._streamer = streamer
        self._cancel_event = cancel_event
        self._finished_event = finished_event
        self._result = result
        self.prompt_tokens = prompt_tokens
        self.max_tokens = max_tokens

    @classmethod
    def completed(cls, prompt_tokens: int) -> "ModelTokenStream":
        finished = threading.Event()
        finished.set()
        return cls(iter(()), threading.Event(), finished, {"output_tokens": 0}, prompt_tokens, 0)

    @property
    def output_tokens(self) -> int:
        return int(self._result.get("output_tokens", 0))

    @property
    def finish_reason(self) -> str:
        if self.max_tokens > 0 and self.output_tokens >= self.max_tokens:
            return "length"
        return "stop"

    def cancel(self) -> None:
        self._cancel_event.set()

    async def chunks(
        self, is_disconnected: Callable[[], Awaitable[bool]]
    ) -> AsyncIterator[str]:
        completed = False
        try:
            while True:
                if await is_disconnected():
                    self.cancel()
                    raise ClientDisconnected()

                state, value = await asyncio.to_thread(
                    _next_streamer_value, self._streamer
                )
                if state == "wait":
                    if self._finished_event.is_set():
                        completed = True
                        error = self._result.get("error")
                        if error is not None:
                            raise error
                        return
                    continue
                if state == "done":
                    # TextIteratorStreamer queues its stop marker immediately
                    # before ``generate`` returns. Wait for the producer to
                    # publish its result or error before deciding how to end.
                    while not self._finished_event.is_set():
                        await asyncio.sleep(0)
                    completed = True
                    error = self._result.get("error")
                    if error is not None:
                        raise error
                    return
                if value:
                    yield value
        except asyncio.CancelledError:
            self.cancel()
            raise
        finally:
            # Closing an async response generator is another form of client
            # cancellation. The StoppingCriteria checks this event each step.
            if not completed and not self._finished_event.is_set():
                self.cancel()


class LocalModel:
    def __init__(self, config: WorkerConfig) -> None:
        import torch
        from transformers import AutoModelForCausalLM, AutoTokenizer

        self.torch = torch
        self.config = config
        common = {
            "local_files_only": True,
            "trust_remote_code": config.trust_remote_code,
        }
        self.tokenizer = AutoTokenizer.from_pretrained(config.model, **common)
        # Deliberately no quantization_config/load_in_4bit: checkpoint weights
        # must never be converted as a side effect of starting the engine.
        load_options: dict[str, Any] = {
            "device_map": "auto",
            "torch_dtype": "auto",
            "low_cpu_mem_usage": True,
        }
        if config.gpu_max_memory_bytes:
            # Accelerate accepts runtime-local integer device ordinals and byte
            # values. The Go launcher aligns these ordinals with the worker's
            # CUDA/ROCm visibility mask, so a host GPU ID never leaks here.
            load_options["max_memory"] = {
                index: limit
                for index, limit in enumerate(config.gpu_max_memory_bytes)
            }
            if config.cpu_max_memory_bytes is not None:
                load_options["max_memory"]["cpu"] = config.cpu_max_memory_bytes
        self.model = AutoModelForCausalLM.from_pretrained(
            config.model, **load_options, **common
        )
        self.model.eval()
        if self.tokenizer.pad_token_id is None:
            self.tokenizer.pad_token_id = self.tokenizer.eos_token_id
        configured_limit = int(
            getattr(self.model.config, "max_position_embeddings", 0) or 0
        )
        self.context_length = config.context_length or configured_limit or 4096
        self._slots = asyncio.Semaphore(max(1, config.max_sequences))

    def prompt_for_messages(self, messages: list[dict[str, Any]]) -> str:
        try:
            return self.tokenizer.apply_chat_template(
                messages, tokenize=False, add_generation_prompt=True
            )
        except (AttributeError, ValueError, TypeError):
            parts = []
            for message in messages:
                role = str(message.get("role", "user"))
                content = message.get("content", "")
                if isinstance(content, list):
                    content = " ".join(
                        str(item.get("text", ""))
                        for item in content
                        if isinstance(item, dict) and item.get("type") == "text"
                    )
                parts.append(f"{role}: {content}")
            parts.append("assistant:")
            return "\n".join(parts)

    async def generate(
        self,
        prompt: str,
        request: dict[str, Any],
        is_disconnected: Callable[[], Awaitable[bool]] | None = None,
    ) -> tuple[str, int, int]:
        async with self._slots:
            cancel_event = threading.Event()
            generation_task = asyncio.create_task(
                asyncio.to_thread(
                    self._generate_sync, prompt, request, cancel_event
                )
            )
            disconnect_check = is_disconnected
            try:
                while not generation_task.done():
                    await asyncio.wait({generation_task}, timeout=0.05)
                    if (
                        not generation_task.done()
                        and disconnect_check is not None
                        and await disconnect_check()
                    ):
                        cancel_event.set()
                        # One signal is enough. Keep the sequence slot until the
                        # decoder observes it and exits.
                        disconnect_check = None
                return await asyncio.shield(generation_task)
            except asyncio.CancelledError:
                cancel_event.set()
                await _wait_for_cancelled_generation(generation_task)
                raise
            except Exception:
                cancel_event.set()
                await _wait_for_cancelled_generation(generation_task)
                raise

    async def begin_stream(
        self, prompt: str, request: dict[str, Any]
    ) -> ModelTokenStream:
        """Validate and start one incremental generation.

        Preparation deliberately happens before the ``StreamingResponse`` is
        created. In particular, a context overflow can therefore still be
        represented by the normal OpenAI-compatible HTTP 422 response.
        """

        await self._slots.acquire()
        slot_owned = True
        try:
            prepared = await asyncio.to_thread(
                self._prepare_generation_sync, prompt, request
            )
            if prepared.max_tokens == 0:
                self._slots.release()
                slot_owned = False
                return ModelTokenStream.completed(prepared.prompt_tokens)

            token_stream = self._launch_stream(prepared)
            slot_owned = False  # The generation thread releases this slot.
            return token_stream
        finally:
            if slot_owned:
                self._slots.release()

    def _generate_sync(
        self,
        prompt: str,
        request: dict[str, Any],
        cancel_event: threading.Event | None = None,
    ) -> tuple[str, int, int]:
        prepared = self._prepare_generation_sync(prompt, request)
        if prepared.max_tokens == 0:
            return "", prepared.prompt_tokens, 0

        generation = dict(prepared.generation)
        if cancel_event is not None:
            generation["stopping_criteria"] = self._event_stopping_criteria(
                cancel_event
            )
        with self.torch.inference_mode():
            output = self.model.generate(**prepared.encoded, **generation)
        generated = output[0, prepared.prompt_tokens:]
        text = self.tokenizer.decode(generated, skip_special_tokens=True)
        return text, prepared.prompt_tokens, int(generated.shape[-1])

    def _prepare_generation_sync(
        self, prompt: str, request: dict[str, Any]
    ) -> PreparedGeneration:
        encoded = self.tokenizer(prompt, return_tensors="pt")
        device = next(self.model.parameters()).device
        encoded = {key: value.to(device) for key, value in encoded.items()}
        prompt_tokens = int(encoded["input_ids"].shape[-1])
        requested_max_tokens = (
            request["max_tokens"]
            if "max_tokens" in request
            else request.get("max_completion_tokens", 256)
        )
        if requested_max_tokens is None:
            requested_max_tokens = 256
        max_tokens = max(0, int(requested_max_tokens))
        if prompt_tokens + max_tokens > self.context_length:
            raise ContextLengthError(prompt_tokens, max_tokens, self.context_length)

        temperature = float(request.get("temperature", 1.0))
        generation: dict[str, Any] = {
            "max_new_tokens": max_tokens,
            "do_sample": temperature > 0,
            "pad_token_id": self.tokenizer.pad_token_id,
        }
        if temperature > 0:
            generation["temperature"] = temperature
            generation["top_p"] = float(request.get("top_p", 1.0))
        if request.get("stop"):
            generation["stop_strings"] = request["stop"]
            generation["tokenizer"] = self.tokenizer
        generation.update(self._cache_arguments())

        return PreparedGeneration(
            encoded=encoded,
            prompt_tokens=prompt_tokens,
            max_tokens=max_tokens,
            generation=generation,
        )

    def _launch_stream(self, prepared: PreparedGeneration) -> ModelTokenStream:
        from transformers import TextIteratorStreamer

        cancel_event = threading.Event()
        finished_event = threading.Event()
        result: dict[str, Any] = {}
        loop = asyncio.get_running_loop()

        streamer = TextIteratorStreamer(
            self.tokenizer,
            skip_prompt=True,
            skip_special_tokens=True,
            timeout=0.1,
        )
        generation = dict(prepared.generation)
        generation.update(
            {
                "streamer": streamer,
                "stopping_criteria": self._event_stopping_criteria(cancel_event),
                "return_dict_in_generate": True,
            }
        )

        def run_generation() -> None:
            try:
                with self.torch.inference_mode():
                    output = self.model.generate(**prepared.encoded, **generation)
                sequences = output.sequences
                result["output_tokens"] = max(
                    0, int(sequences.shape[-1]) - prepared.prompt_tokens
                )
            except BaseException as error:  # surfaced through the response iterator
                result["error"] = error
                # ``generate`` normally closes the streamer. It may fail before
                # doing so (for example on an unsupported cache backend).
                try:
                    streamer.end()
                except BaseException:
                    # The consumer also observes ``finished_event`` and will
                    # therefore not remain blocked if even closing fails.
                    pass
            finally:
                finished_event.set()
                try:
                    loop.call_soon_threadsafe(self._slots.release)
                except RuntimeError:
                    # The process is already shutting down and the loop is gone.
                    pass

        thread = threading.Thread(
            target=run_generation,
            name="transformers-generation",
            daemon=True,
        )
        try:
            thread.start()
        except BaseException:
            raise

        return ModelTokenStream(
            streamer=streamer,
            cancel_event=cancel_event,
            finished_event=finished_event,
            result=result,
            prompt_tokens=prepared.prompt_tokens,
            max_tokens=prepared.max_tokens,
        )

    @staticmethod
    def _event_stopping_criteria(cancel_event: threading.Event):
        from transformers import StoppingCriteria, StoppingCriteriaList

        class EventStoppingCriteria(StoppingCriteria):
            def __call__(self, _input_ids: Any, _scores: Any, **_kwargs: Any) -> bool:
                return cancel_event.is_set()

        return StoppingCriteriaList([EventStoppingCriteria()])

    def _cache_arguments(self) -> dict[str, Any]:
        if self.config.kv_cache == "quanto_4bit":
            return {
                "cache_implementation": "quantized",
                "cache_config": {"backend": "quanto", "nbits": 4},
            }
        if self.config.kv_cache == "offloaded":
            return {"cache_implementation": "offloaded"}
        return {}


class ContextLengthError(ValueError):
    def __init__(self, prompt_tokens: int, max_tokens: int, limit: int) -> None:
        super().__init__(
            f"prompt ({prompt_tokens}) plus max_tokens ({max_tokens}) exceeds "
            f"the effective context limit ({limit})"
        )
        self.prompt_tokens = prompt_tokens
        self.max_tokens = max_tokens
        self.limit = limit


def create_app(model: LocalModel, model_id: str, api_key: str):
    from fastapi import FastAPI, HTTPException, Request
    from fastapi.responses import JSONResponse, StreamingResponse

    app = FastAPI(title="PhiloEngine Transformers Worker", docs_url=None, redoc_url=None)

    @app.middleware("http")
    async def require_internal_bearer(request: Request, call_next):
        supplied = request.headers.get("authorization", "")
        if not secrets.compare_digest(supplied, f"Bearer {api_key}"):
            return JSONResponse(
                status_code=401,
                content={
                    "error": {
                        "message": "invalid internal worker credential",
                        "type": "authentication_error",
                        "code": "invalid_api_key",
                    }
                },
                headers={"WWW-Authenticate": "Bearer"},
            )
        return await call_next(request)

    @app.exception_handler(ContextLengthError)
    async def context_error(_request: Request, error: ContextLengthError):
        return JSONResponse(
            status_code=422,
            content={
                "error": {
                    "message": str(error),
                    "type": "context_length_exceeded",
                    "param": "max_tokens",
                    "code": "context_length_exceeded",
                    "context_limit": error.limit,
                }
            },
        )

    @app.get("/health")
    async def health() -> dict[str, Any]:
        return {"status": "ok", "model": model_id, "context_length": model.context_length}

    @app.get("/v1/models")
    async def models() -> dict[str, Any]:
        return {
            "object": "list",
            "data": [
                {
                    "id": model_id,
                    "object": "model",
                    "created": int(time.time()),
                    "owned_by": "philoengine",
                }
            ],
        }

    @app.post("/v1/completions")
    async def completions(request: Request):
        body = await _json_body(request, HTTPException)
        prompt = body.get("prompt", "")
        if isinstance(prompt, list):
            if len(prompt) != 1:
                raise HTTPException(status_code=422, detail="only one prompt is supported")
            prompt = prompt[0]
        if not isinstance(prompt, str):
            raise HTTPException(status_code=422, detail="prompt must be a string")
        completion_id = "cmpl-" + uuid.uuid4().hex
        if body.get("stream"):
            token_stream = await model.begin_stream(prompt, body)
            return StreamingResponse(
                _completion_stream(completion_id, model_id, token_stream, request),
                media_type="text/event-stream",
                headers={"X-Accel-Buffering": "no", "Cache-Control": "no-cache"},
            )
        text, input_tokens, output_tokens = await model.generate(
            prompt, body, request.is_disconnected
        )
        return {
            "id": completion_id,
            "object": "text_completion",
            "created": int(time.time()),
            "model": model_id,
            "choices": [{"index": 0, "text": text, "finish_reason": "stop"}],
            "usage": _usage(input_tokens, output_tokens),
        }

    @app.post("/v1/chat/completions")
    async def chat_completions(request: Request):
        body = await _json_body(request, HTTPException)
        messages = body.get("messages")
        if not isinstance(messages, list) or not messages:
            raise HTTPException(status_code=422, detail="messages must be a non-empty list")
        prompt = model.prompt_for_messages(messages)
        completion_id = "chatcmpl-" + uuid.uuid4().hex
        if body.get("stream"):
            token_stream = await model.begin_stream(prompt, body)
            return StreamingResponse(
                _chat_stream(completion_id, model_id, token_stream, request),
                media_type="text/event-stream",
                headers={"X-Accel-Buffering": "no", "Cache-Control": "no-cache"},
            )
        text, input_tokens, output_tokens = await model.generate(
            prompt, body, request.is_disconnected
        )
        return {
            "id": completion_id,
            "object": "chat.completion",
            "created": int(time.time()),
            "model": model_id,
            "choices": [
                {
                    "index": 0,
                    "message": {"role": "assistant", "content": text},
                    "finish_reason": "stop",
                }
            ],
            "usage": _usage(input_tokens, output_tokens),
        }

    return app


async def _json_body(request: Any, http_exception: type[Exception]) -> dict[str, Any]:
    try:
        body = await request.json()
    except (json.JSONDecodeError, ValueError) as error:
        raise http_exception(status_code=400, detail="invalid JSON body") from error
    if not isinstance(body, dict):
        raise http_exception(status_code=422, detail="body must be a JSON object")
    return body


def _usage(prompt_tokens: int, completion_tokens: int) -> dict[str, int]:
    return {
        "prompt_tokens": prompt_tokens,
        "completion_tokens": completion_tokens,
        "total_tokens": prompt_tokens + completion_tokens,
    }


async def _completion_stream(
    completion_id: str,
    model_id: str,
    token_stream: ModelTokenStream,
    request: Any,
):
    try:
        async for chunk in token_stream.chunks(request.is_disconnected):
            payload = {
                "id": completion_id,
                "object": "text_completion",
                "created": int(time.time()),
                "model": model_id,
                "choices": [{"index": 0, "text": chunk, "finish_reason": None}],
            }
            yield "data: " + json.dumps(payload, ensure_ascii=False) + "\n\n"
    except ClientDisconnected:
        return
    finally:
        token_stream.cancel()

    final_payload = {
        "id": completion_id,
        "object": "text_completion",
        "created": int(time.time()),
        "model": model_id,
        "choices": [
            {"index": 0, "text": "", "finish_reason": token_stream.finish_reason}
        ],
    }
    yield "data: " + json.dumps(final_payload) + "\n\n"
    yield "data: [DONE]\n\n"


async def _chat_stream(
    completion_id: str,
    model_id: str,
    token_stream: ModelTokenStream,
    request: Any,
):
    first = True
    try:
        async for chunk in token_stream.chunks(request.is_disconnected):
            delta: dict[str, Any] = {"content": chunk}
            if first:
                delta["role"] = "assistant"
                first = False
            payload = {
                "id": completion_id,
                "object": "chat.completion.chunk",
                "created": int(time.time()),
                "model": model_id,
                "choices": [{"index": 0, "delta": delta, "finish_reason": None}],
            }
            yield "data: " + json.dumps(payload, ensure_ascii=False) + "\n\n"
    except ClientDisconnected:
        return
    finally:
        token_stream.cancel()

    final_payload = {
        "id": completion_id,
        "object": "chat.completion.chunk",
        "created": int(time.time()),
        "model": model_id,
        "choices": [
            {"index": 0, "delta": {}, "finish_reason": token_stream.finish_reason}
        ],
    }
    yield "data: " + json.dumps(final_payload) + "\n\n"
    yield "data: [DONE]\n\n"


def _next_streamer_value(streamer: Iterator[str]) -> tuple[str, str]:
    try:
        return "value", next(streamer)
    except queue.Empty:
        return "wait", ""
    except StopIteration:
        # StopIteration must not cross an asyncio Future boundary.
        return "done", ""


async def _wait_for_cancelled_generation(generation_task: asyncio.Task[Any]) -> None:
    """Keep ownership of the model slot until a cancelled decoder really exits."""

    while not generation_task.done():
        try:
            await asyncio.shield(generation_task)
        except asyncio.CancelledError:
            # A second transport cancellation must still not release the slot
            # while the executor thread owns model/GPU state.
            continue
        except Exception:
            return
    try:
        generation_task.result()
    except BaseException:
        # The caller re-raises the original cancellation/monitoring exception.
        pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", required=True)
    parser.add_argument("--served-model-name", required=True)
    parser.add_argument("--host", default="127.0.0.1", choices=["127.0.0.1", "::1"])
    parser.add_argument("--port", required=True, type=int)
    parser.add_argument("--api-key", required=True)
    parser.add_argument("--context-length", type=int, default=0)
    parser.add_argument(
        "--kv-cache", choices=["quanto_4bit", "offloaded", "native"], default="native"
    )
    parser.add_argument("--max-sequences", type=int, default=1)
    parser.add_argument(
        "--gpu-max-memory-bytes", action="append", type=int, default=[]
    )
    parser.add_argument("--cpu-max-memory-bytes", type=int)
    parser.add_argument("--trust-remote-code", action="store_true", default=False)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if args.context_length < 0:
        raise SystemExit("--context-length must not be negative")
    if args.max_sequences < 1:
        raise SystemExit("--max-sequences must be at least one")
    if any(limit <= 0 for limit in args.gpu_max_memory_bytes):
        raise SystemExit("--gpu-max-memory-bytes must be positive")
    if args.cpu_max_memory_bytes is not None and args.cpu_max_memory_bytes <= 0:
        raise SystemExit("--cpu-max-memory-bytes must be positive")
    config = WorkerConfig(
        model=args.model,
        context_length=args.context_length,
        kv_cache=args.kv_cache,
        trust_remote_code=args.trust_remote_code,
        max_sequences=args.max_sequences,
        gpu_max_memory_bytes=tuple(args.gpu_max_memory_bytes),
        cpu_max_memory_bytes=args.cpu_max_memory_bytes,
    )
    model = LocalModel(config)
    app = create_app(model, args.served_model_name, args.api_key)
    import uvicorn

    uvicorn.run(app, host=args.host, port=args.port, log_level="info", access_log=False)


if __name__ == "__main__":
    main()
