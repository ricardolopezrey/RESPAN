"""NumPy-backed stand-in for CuPy when CUDA GPUs are unavailable."""

from __future__ import annotations

import sys
import types
import warnings
from typing import Any

import numpy as np
from scipy import ndimage as scipy_ndimage

__all__ = ["install", "CuPyStub"]


class _MemoryPool:
    """No-op memory pool placeholder."""

    def free_all_blocks(self) -> None:
        return None


class _CudaRuntime:
    """Mirror the handful of cuPy.cuda.runtime helpers RESPAN touches."""

    def memGetInfo(self) -> tuple[int, int]:
        return (0, 0)

    def getDeviceCount(self) -> int:  # pragma: no cover - simple stub
        return 0

    def deviceSynchronize(self) -> None:
        return None


class _DummyDevice:
    def __init__(self, device_id: int | None = None) -> None:
        self.id = device_id or 0

    def __enter__(self) -> "_DummyDevice":
        return self

    def __exit__(self, exc_type, exc, exc_tb) -> None:  # type: ignore[override]
        return None

    def use(self) -> "_DummyDevice":
        return self


class _DummyStream:
    def __enter__(self) -> "_DummyStream":
        return self

    def __exit__(self, exc_type, exc, exc_tb) -> None:  # type: ignore[override]
        return None

    def synchronize(self) -> None:
        return None


class _CudaMemory:
    def __init__(self) -> None:
        self._pool = _MemoryPool()

    def get_default_memory_pool(self) -> _MemoryPool:
        return self._pool


class _CudaModule:
    def __init__(self) -> None:
        self.runtime = _CudaRuntime()
        self.memory = _CudaMemory()
        self.Device = _DummyDevice
        self.Stream = _DummyStream


class CuPyStub(types.ModuleType):
    """Simple module object forwarding most attributes to NumPy."""

    def __init__(self) -> None:
        super().__init__("cupy")
        self.__dict__.update(
            ndarray=np.ndarray,
            float32=np.float32,
            float64=np.float64,
            int32=np.int32,
            int64=np.int64,
            uint8=np.uint8,
            uint16=np.uint16,
            bool_=np.bool_,
            pi=np.pi,
            e=np.e,
            __version__="stub",
            _memory_pool=_MemoryPool(),
            cuda=_CudaModule(),
            cupyx=_build_cupyx_namespace(),
        )

    def __getattr__(self, name: str) -> Any:  # pragma: no cover - passthrough
        if hasattr(np, name):
            attr = getattr(np, name)
            setattr(self, name, attr)
            return attr
        raise AttributeError(f"cupy stub does not implement attribute '{name}'")

    def array(self, *args: Any, **kwargs: Any) -> np.ndarray:
        return np.array(*args, **kwargs)

    def asarray(self, *args: Any, **kwargs: Any) -> np.ndarray:
        return np.asarray(*args, **kwargs)

    def zeros(self, *args: Any, **kwargs: Any) -> np.ndarray:
        return np.zeros(*args, **kwargs)

    def ones(self, *args: Any, **kwargs: Any) -> np.ndarray:
        return np.ones(*args, **kwargs)

    def empty(self, *args: Any, **kwargs: Any) -> np.ndarray:
        return np.empty(*args, **kwargs)

    def asnumpy(self, arr: np.ndarray) -> np.ndarray:
        return arr

    def get_array_module(self, _arr: Any) -> types.ModuleType:
        return np

    def get_default_memory_pool(self) -> _MemoryPool:
        return self._memory_pool

    def get_include(self) -> str:
        return ""


def _build_cupyx_namespace() -> types.ModuleType:
    module = types.ModuleType("cupyx")
    scipy_mod = types.ModuleType("cupyx.scipy")
    scipy_mod.ndimage = scipy_ndimage
    module.scipy = scipy_mod
    sys.modules.setdefault("cupyx", module)
    sys.modules.setdefault("cupyx.scipy", scipy_mod)
    sys.modules.setdefault("cupyx.scipy.ndimage", scipy_ndimage)
    return module


def install(reason: str | None = None) -> CuPyStub:
    """Install the stub into ``sys.modules['cupy']`` and warn the user."""

    module = CuPyStub()
    sys.modules["cupy"] = module
    message = "Using CuPy CPU stub (NumPy backend). GPU acceleration is unavailable."
    if reason:
        message = f"{message} Reason: {reason}"
    warnings.warn(message, RuntimeWarning)
    return module


if __name__ == "__main__":  # pragma: no cover - manual smoke test
    cp = install("manual execution")
    print(cp.zeros((2, 2)))
