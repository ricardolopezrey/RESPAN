"""RESPAN sitecustomize: prefer CUDA/Metal CuPy, fall back to CPU stub otherwise."""

from __future__ import annotations

import os
import platform
import sys
import importlib

try:
    cupy_stub = importlib.import_module("RESPAN.cupy_stub")
except ModuleNotFoundError:  # pragma: no cover - fallback for direct execution
    cupy_stub = importlib.import_module("cupy_stub")

IS_DARWIN = platform.system() == "Darwin"
FORCE_STUB = os.environ.get("RESPAN_FORCE_CUPY_STUB") == "1"


def _install_stub(reason: str) -> None:
    cupy_stub.install(reason)


def _configure_metal_env() -> None:
    os.environ.setdefault("CUPY_ACCELERATORS", "metal")
    os.environ.setdefault("CUPY_CACHE_DIR", os.path.join(os.path.expanduser("~"), ".cupy_cache"))


def _verify_device_support(cupy: object) -> str:
    runtime = cupy.cuda.runtime
    try:
        count = runtime.getDeviceCount()
    except Exception as exc:  # pragma: no cover - backend failures
        raise RuntimeError(f"CuPy backend unavailable: {exc}") from exc
    if count <= 0:
        raise RuntimeError("No GPU devices detected by CuPy.")
    if IS_DARWIN:
        return "Metal (MPS)"
    return "CUDA"


def _initialize_cupy() -> bool:
    if FORCE_STUB:
        _install_stub("RESPAN_FORCE_CUPY_STUB=1")
        return False
    if IS_DARWIN:
        _configure_metal_env()
    try:
        cupy = importlib.import_module("cupy")
    except Exception as exc:  # pragma: no cover - cupy missing
        _install_stub(f"CuPy import failed: {exc}")
        return False
    try:
        backend = _verify_device_support(cupy)
    except Exception as exc:  # pragma: no cover - backend missing
        _install_stub(str(exc))
        sys.stderr.write("Falling back to CuPy CPU stub because GPU backend could not be initialized.\n")
        return False
    else:
        print(f"✓ CuPy initialized using {backend}")
        return True


_initialize_cupy()
