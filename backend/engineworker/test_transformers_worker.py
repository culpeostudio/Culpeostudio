from __future__ import annotations

import asyncio
import contextlib
import json
import queue
import sys
import threading
import time
import types
import unittest
from unittest import mock

try:
    from . import transformers_worker as worker
except ImportError:  # unittest discovery with engineworker as its top-level dir
    import transformers_worker as worker


class _Request:
    def __init__(self, disconnected: bool = False) -> None:
        self.disconnected = disconnected

    async def is_disconnected(self) -> bool:
        return self.disconnected


def _finished_stream(
    chunks: list[str], *, output_tokens: int = 0, max_tokens: int = 16
) -> tuple[worker.ModelTokenStream, threading.Event]:
    cancel_event = threading.Event()
    finished_event = threading.Event()
    finished_event.set()
    stream = worker.ModelTokenStream(
        iter(chunks),
        cancel_event,
        finished_event,
        {"output_tokens": output_tokens},
        prompt_tokens=3,
        max_tokens=max_tokens,
    )
    return stream, cancel_event


async def _collect(generator) -> list[str]:
    return [event async for event in generator]


class ModelLoadingLimitTests(unittest.TestCase):
    def _load_options(
        self, limits: tuple[int, ...], cpu_limit: int | None = None
    ) -> dict[str, object]:
        captured: dict[str, object] = {}

        class FakeTokenizer:
            pad_token_id = None
            eos_token_id = 2

        class FakeAutoTokenizer:
            @staticmethod
            def from_pretrained(_model, **_options):
                return FakeTokenizer()

        class FakeModel:
            config = types.SimpleNamespace(max_position_embeddings=4096)

            @staticmethod
            def eval() -> None:
                return None

        class FakeAutoModel:
            @staticmethod
            def from_pretrained(_model, **options):
                captured.update(options)
                return FakeModel()

        fake_transformers = types.ModuleType("transformers")
        fake_transformers.AutoModelForCausalLM = FakeAutoModel
        fake_transformers.AutoTokenizer = FakeAutoTokenizer
        fake_torch = types.ModuleType("torch")
        config = worker.WorkerConfig(
            model="/model",
            context_length=4096,
            kv_cache="native",
            trust_remote_code=False,
            max_sequences=1,
            gpu_max_memory_bytes=limits,
            cpu_max_memory_bytes=cpu_limit,
        )
        with mock.patch.dict(
            sys.modules, {"torch": fake_torch, "transformers": fake_transformers}
        ):
            worker.LocalModel(config)
        return captured

    def test_planned_gpu_bytes_become_transformers_max_memory(self) -> None:
        options = self._load_options((6 << 30, 3 << 30))
        self.assertEqual(options["max_memory"], {0: 6 << 30, 1: 3 << 30})

    def test_cpu_loading_does_not_add_a_gpu_max_memory_map(self) -> None:
        options = self._load_options(())
        self.assertNotIn("max_memory", options)

    def test_hybrid_loading_keeps_planned_cpu_offload_budget(self) -> None:
        options = self._load_options((6 << 30,), 4 << 30)
        self.assertEqual(options["max_memory"], {0: 6 << 30, "cpu": 4 << 30})


class StreamEncodingTests(unittest.IsolatedAsyncioTestCase):
    async def test_completion_preserves_unicode_and_emits_done_once(self) -> None:
        stream, _cancel = _finished_stream(
            ["Grüße ", "👋", " — 東京"], output_tokens=3, max_tokens=3
        )

        events = await _collect(
            worker._completion_stream("cmpl-test", "model-test", stream, _Request())
        )

        self.assertEqual(events.count("data: [DONE]\n\n"), 1)
        self.assertIn("Grüße ", "".join(events))
        self.assertIn("👋", "".join(events))
        self.assertNotIn("\\ud83d", "".join(events))

        payloads = [
            json.loads(event.removeprefix("data: ").strip())
            for event in events
            if event != "data: [DONE]\n\n"
        ]
        text = "".join(item["choices"][0]["text"] for item in payloads[:-1])
        self.assertEqual(text, "Grüße 👋 — 東京")
        self.assertEqual(payloads[-1]["choices"][0]["finish_reason"], "length")

    async def test_chat_stream_marks_first_delta_and_done_once(self) -> None:
        stream, _cancel = _finished_stream(["Hallo", " Welt"], output_tokens=2)

        events = await _collect(
            worker._chat_stream("chat-test", "model-test", stream, _Request())
        )

        self.assertEqual(events.count("data: [DONE]\n\n"), 1)
        first = json.loads(events[0].removeprefix("data: ").strip())
        self.assertEqual(first["choices"][0]["delta"]["role"], "assistant")
        self.assertEqual(first["choices"][0]["delta"]["content"], "Hallo")

    async def test_disconnect_cancels_generation_without_done(self) -> None:
        stream, cancel_event = _finished_stream(["must not be sent"])
        # Pretend the producer is still running so cancellation is observable.
        stream._finished_event.clear()

        events = await _collect(
            worker._completion_stream(
                "cmpl-disconnect", "model-test", stream, _Request(disconnected=True)
            )
        )

        self.assertEqual(events, [])
        self.assertTrue(cancel_event.is_set())


class LifecycleTests(unittest.IsolatedAsyncioTestCase):
    async def test_context_error_before_stream_releases_sequence_slot(self) -> None:
        model = object.__new__(worker.LocalModel)
        model._slots = asyncio.Semaphore(1)

        def reject(_prompt, _request):
            raise worker.ContextLengthError(4000, 512, 4096)

        model._prepare_generation_sync = reject

        with self.assertRaises(worker.ContextLengthError):
            await model.begin_stream("prompt", {"max_tokens": 512})

        await asyncio.wait_for(model._slots.acquire(), timeout=0.2)
        model._slots.release()

    async def test_non_stream_disconnect_stops_decoder_and_keeps_slot(self) -> None:
        class FakeStoppingCriteria:
            pass

        class FakeStoppingCriteriaList(list):
            pass

        fake_transformers = types.ModuleType("transformers")
        fake_transformers.StoppingCriteria = FakeStoppingCriteria
        fake_transformers.StoppingCriteriaList = FakeStoppingCriteriaList

        started = threading.Event()
        stopped = threading.Event()

        class FakeGeneratedTokens:
            shape = (1,)

        class FakeOutput:
            def __getitem__(self, _key):
                return FakeGeneratedTokens()

        class FakeModel:
            def generate(self, **generation):
                started.set()
                criteria = generation["stopping_criteria"]
                while not any(item(None, None) for item in criteria):
                    time.sleep(0.001)
                stopped.set()
                return FakeOutput()

        class FakeTokenizer:
            @staticmethod
            def decode(_tokens, **_kwargs):
                return "partial"

        class FakeTorch:
            @staticmethod
            def inference_mode():
                return contextlib.nullcontext()

        model = object.__new__(worker.LocalModel)
        model.tokenizer = FakeTokenizer()
        model.model = FakeModel()
        model.torch = FakeTorch()
        model._slots = asyncio.Semaphore(1)
        model._prepare_generation_sync = lambda _prompt, _request: (
            worker.PreparedGeneration(
                encoded={},
                prompt_tokens=2,
                max_tokens=5,
                generation={"max_new_tokens": 5},
            )
        )

        async def disconnected() -> bool:
            return started.is_set()

        with mock.patch.dict(sys.modules, {"transformers": fake_transformers}):
            result = await asyncio.wait_for(
                model.generate("prompt", {}, disconnected), timeout=1
            )

        self.assertTrue(stopped.is_set())
        self.assertEqual(result, ("partial", 2, 1))
        await asyncio.wait_for(model._slots.acquire(), timeout=0.2)
        model._slots.release()

    def test_max_completion_tokens_alias_and_max_tokens_precedence(self) -> None:
        class FakeTensor:
            shape = (1, 4)

            def to(self, _device):
                return self

        class FakeTokenizer:
            pad_token_id = 0

            def __call__(self, _prompt, **_kwargs):
                return {"input_ids": FakeTensor()}

        class FakeParameter:
            device = "cpu"

        class FakeModel:
            @staticmethod
            def parameters():
                return iter([FakeParameter()])

        model = object.__new__(worker.LocalModel)
        model.tokenizer = FakeTokenizer()
        model.model = FakeModel()
        model.context_length = 20
        model.config = worker.WorkerConfig("model", 20, "native", False, 1)

        alias = model._prepare_generation_sync(
            "prompt", {"max_completion_tokens": 7, "temperature": 0}
        )
        explicit = model._prepare_generation_sync(
            "prompt",
            {"max_tokens": 3, "max_completion_tokens": 7, "temperature": 0},
        )

        self.assertEqual(alias.max_tokens, 7)
        self.assertEqual(explicit.max_tokens, 3)
        model.context_length = 10
        with self.assertRaises(worker.ContextLengthError):
            model._prepare_generation_sync(
                "prompt", {"max_completion_tokens": 7, "temperature": 0}
            )

    async def test_cancel_event_reaches_transformers_stopping_criteria(self) -> None:
        sentinel = object()

        class FakeStoppingCriteria:
            pass

        class FakeStoppingCriteriaList(list):
            pass

        class FakeTextIteratorStreamer:
            def __init__(self, _tokenizer, *, timeout, **_kwargs) -> None:
                self.timeout = timeout
                self.values: queue.Queue[object] = queue.Queue()

            def __iter__(self):
                return self

            def __next__(self):
                value = self.values.get(timeout=self.timeout)
                if value is sentinel:
                    raise StopIteration
                return str(value)

            def end(self) -> None:
                self.values.put(sentinel)

        fake_transformers = types.ModuleType("transformers")
        fake_transformers.StoppingCriteria = FakeStoppingCriteria
        fake_transformers.StoppingCriteriaList = FakeStoppingCriteriaList
        fake_transformers.TextIteratorStreamer = FakeTextIteratorStreamer

        started = threading.Event()
        stopped = threading.Event()

        class FakeModel:
            def generate(self, **generation):
                started.set()
                criteria = generation["stopping_criteria"]
                while not any(item(None, None) for item in criteria):
                    time.sleep(0.001)
                stopped.set()
                generation["streamer"].end()
                return types.SimpleNamespace(
                    sequences=types.SimpleNamespace(shape=(1, 3))
                )

        class FakeTorch:
            @staticmethod
            def inference_mode():
                return contextlib.nullcontext()

        model = object.__new__(worker.LocalModel)
        model.tokenizer = object()
        model.model = FakeModel()
        model.torch = FakeTorch()
        model._slots = asyncio.Semaphore(0)  # owned by this generation
        prepared = worker.PreparedGeneration(
            encoded={}, prompt_tokens=2, max_tokens=5, generation={}
        )

        with mock.patch.dict(sys.modules, {"transformers": fake_transformers}):
            token_stream = model._launch_stream(prepared)
            self.assertTrue(await asyncio.to_thread(started.wait, 0.5))
            token_stream.cancel()
            self.assertTrue(await asyncio.to_thread(stopped.wait, 0.5))
            self.assertTrue(
                await asyncio.to_thread(token_stream._finished_event.wait, 0.5)
            )


if __name__ == "__main__":
    unittest.main()
