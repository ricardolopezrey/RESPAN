# clean_launcher.py

# Set BLOSC env var BEFORE any imports to prevent cpuinfo crash on macOS
import os as _os
_os.environ['BLOSC_NO_HW_DETECTION'] = '1'
print(f"     DEBUG: BLOSC_NO_HW_DETECTION set to {_os.environ['BLOSC_NO_HW_DETECTION']}")

import sys
import os
import site
import subprocess
from pathlib import Path


# Configure PyTorch/nnU-Net for non-CUDA systems (macOS)
# Allow MPS (Apple Silicon GPU) to be used for inference
os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")  # Allow CPU fallback for unsupported MPS ops
os.environ.setdefault("CUDA_VISIBLE_DEVICES", "")  # Disable CUDA (not available on macOS)
os.environ.setdefault("nnUNet_n_proc_DA", "0")  # Disable multiprocessing for data augmentation
os.environ.setdefault("nnUNet_n_proc_segmentation_export", "0")  # Single-process export
os.environ.setdefault("KMP_DUPLICATE_LIB_OK", "TRUE")  # Workaround for OpenMP conflicts
# Reduce risk of OpenMP clashes / oversubscription
os.environ.setdefault("OMP_NUM_THREADS", "1")
os.environ.setdefault("MKL_NUM_THREADS", "1")


def patch_torch_pin_memory():
    """
    Monkey-patch torch.Tensor.pin_memory to be a no-op on non-CUDA systems.

    nnU-Net's data_iterators.py calls pin_memory() unconditionally, but this
    only makes sense for CUDA. On MPS (Apple Silicon) it raises:
        RuntimeError: Attempted to set the storage of a tensor on device "cpu"
        to a storage on different device "mps:0".

    This patch makes pin_memory() return self (no-op) when CUDA is unavailable.
    """
    try:
        import torch
        if not torch.cuda.is_available():
            _original_pin_memory = torch.Tensor.pin_memory

            def safe_pin_memory(self, device=None):
                # pin_memory is only useful for CUDA; on CPU/MPS just return self
                return self

            torch.Tensor.pin_memory = safe_pin_memory
            print("     [clean_launcher] Patched torch.Tensor.pin_memory for non-CUDA device")
    except ImportError:
        pass  # torch not installed, nothing to patch


def clean_environment():
    """Clean Python environment while preserving critical application variables"""
    # Remove user site-packages
    paths_to_remove = []
    for path in sys.path:
        if ('AppData' in path and 'site-packages' in path) or 'Roaming\\Python' in path:
            paths_to_remove.append(path)

    for path in paths_to_remove:
        if path in sys.path:
            sys.path.remove(path)

    # Disable user site
    site.USER_SITE = None
    site.USER_BASE = None

    print(f"     Environment checked: removed {len(paths_to_remove)} conflicting paths")

    # Log nnUNet variables
    nnunet_vars = ['nnUNet_raw', 'nnUNet_preprocessed', 'nnUNet_results']
    for var in nnunet_vars:
        if var in os.environ:
            print(f"     nnUNet variable: {var} = {os.environ[var]}")

    # Ensure Blosc CPU probing does not run (prevents JSONDecodeError on macOS)
    # Redundant check but good for logging
    if 'BLOSC_NO_HW_DETECTION' not in os.environ:
        os.environ['BLOSC_NO_HW_DETECTION'] = '1'
        print("     BLOSC_NO_HW_DETECTION set to 1 for stable nnU-Net launches")
    else:
        print(f"     BLOSC_NO_HW_DETECTION is already set to {os.environ['BLOSC_NO_HW_DETECTION']}")


if __name__ == "__main__":
    clean_environment()
    patch_torch_pin_memory()  # Fix MPS/CPU pin_memory crash before nnU-Net runs

    # Get the target script and remaining arguments
    target_script = sys.argv[1]
    remaining_args = sys.argv[2:]  # All arguments after the target script

    # Check if it's a batch file or Python script
    if target_script.endswith('.bat'):
        # For batch files, run as subprocess
        cmd = [target_script] + remaining_args
        #print(f"Executing batch file: {' '.join(cmd)}")

        # Run with cleaned environment
        env = os.environ.copy()
        result = subprocess.run(cmd, env=env)
        sys.exit(result.returncode)
    else:
        # For Python scripts, execute directly
        sys.argv = [target_script] + remaining_args
        #print(f"Executing Python script: {target_script}")
        exec(open(target_script).read(), {'__name__': '__main__'})