# RESPAN Python Environment Setup

This document provides instructions for setting up the Python environment for RESPAN.

## Prerequisites

- Python 3.8, 3.9, or 3.10 (Python 3.10 recommended)
- CUDA 11.x or 12.x (for GPU acceleration on Linux/Windows)
- Conda or Miniconda (recommended) OR pip with virtualenv

## Quick Start (Any Platform)

```bash
# 1. Clone the repository
git clone https://github.com/lahammond/RESPAN.git
cd RESPAN

# 2. Create conda environment
conda env create -f RESPAN/environment.yml -n respan99
conda activate respan99

# 3. Install pip dependencies
pip install -r RESPAN/requirements.txt

# 4. Install RESPAN in editable mode
pip install -e .

# 5. Verify installation
python -c "from RESPAN.Environment import main; main.check_gpu()"
```

## Platform-Specific Setup

### Linux/Windows with NVIDIA GPU

Full GPU acceleration is available:

```bash
# Create environment from yml file
conda env create -f RESPAN/environment.yml -n respan99
conda activate respan99

# Install dependencies (CuPy will use CUDA)
pip install -r RESPAN/requirements.txt

# Install RESPAN
pip install -e .

# Verify GPU
python -c "import cupy; print('CuPy CUDA version:', cupy.cuda.runtime.runtimeGetVersion())"
```

### macOS (Apple Silicon / Intel)

**Note:** CuPy/CUDA is **not available** on macOS. The application automatically falls back to:
- **MPS (Metal Performance Shaders)** for nnU-Net inference on Apple Silicon
- **CPU** for other GPU-accelerated functions

Some optional features (neck generation, GPU mesh analysis) will be skipped with informative warnings, but the full analysis pipeline completes successfully.

```bash
# Create environment
conda env create -f RESPAN/environment.yml -n respan99
conda activate respan99

# Install dependencies (skip CUDA-specific packages)
pip install -r RESPAN/requirements.txt --ignore-installed cupy-cuda11x || true

# Optional: Install CPU fallback for CuPy
pip install cupy-cpu

# Install RESPAN
pip install -e .

# Verify (will show MPS or CPU for PyTorch)
python -c "import torch; print('MPS available:', torch.backends.mps.is_available())"
```

## Alternative: pip + virtualenv

```bash
# Create virtual environment
python -m venv respan_env

# Activate (macOS/Linux)
source respan_env/bin/activate

# Activate (Windows)
# respan_env\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Install RESPAN in development mode
pip install -e .
```

## GPU Support

### CuPy Installation

The project requires CuPy for GPU-accelerated image processing. Install the version matching your CUDA installation:

```bash
# For CUDA 11.x
pip install cupy-cuda11x

# For CUDA 12.x
pip install cupy-cuda12x

# Check CUDA version
nvcc --version  # or nvidia-smi
```

### TensorFlow GPU Support

TensorFlow should automatically detect GPU. Verify with:

```python
import tensorflow as tf
print("GPU Available:", tf.config.list_physical_devices('GPU'))
```

### PyTorch GPU Support

PyTorch installation depends on your CUDA version. Visit https://pytorch.org for specific installation commands.

## nnU-Net Integration

For segmentation functionality, install nnU-Net in a separate environment:

```bash
# Create separate nnU-Net environment
conda create -n respan_nnunet python=3.10
conda activate respan_nnunet

# Install nnU-Net
pip install nnunetv2

# Set environment variables (add to ~/.bashrc or ~/.zshrc)
export nnUNet_raw="/path/to/nnUNet_raw"
export nnUNet_preprocessed="/path/to/nnUNet_preprocessed"
export nnUNet_results="/path/to/nnUNet_results"
```

Alternatively, you can define these paths per dataset inside `Analysis_Settings.yaml` using the `nnUNet` section:

```yaml
nnUNet:
	raw_path: /data/nnUNet_raw
	preprocessed_path: /data/nnUNet_preprocessed
	results_path: /models/nnUNet_results
```

RESPAN will export the corresponding environment variables automatically before launching nnU-Net.

## Development vs. Production

### Development Environment (`respan99`)

Used for active development:

```bash
conda env create -f environment.yml -n respan99
conda activate respan99
```

### Production/Frozen App Environment (`respan`)

The frozen application uses an embedded environment named `respan`. This is automatically managed when building the application with PyInstaller.

## Troubleshooting

### Import Errors

If you encounter import errors:

```bash
# Reinstall RESPAN in editable mode
pip install -e .
```

### CUDA/GPU Issues

1. Verify CUDA installation: `nvidia-smi`
2. Check CuPy compatibility: `python -c "import cupy; print(cupy.cuda.runtime.runtimeGetVersion())"`
3. Ensure driver is up-to-date

### Memory Issues

For large datasets, adjust Dask/GPU settings in `Analysis_Settings.yaml`:
- Reduce `GPU_block_size`
- Enable Dask parallelization
- Increase system swap space

### macOS-Specific Issues

GPU acceleration (CuPy/CUDA) is **not available** on macOS. The application automatically handles this:

- **nnU-Net inference**: Uses MPS (Metal Performance Shaders) on Apple Silicon, or CPU fallback
- **Spine analysis**: GPU-only features (neck generation, mesh analysis) are skipped with warnings
- **Full pipeline**: Completes successfully with all core measurements

If you see warnings like "GPU neck extension requested but CuPy/CUDA is unavailable", this is expected behavior on macOS.

```bash
# For macOS, skip cupy-cuda and use CPU fallback
pip install -r requirements.txt --ignore-installed cupy-cuda11x || true
pip install cupy-cpu  # Optional CPU fallback
```

### OpenMP Conflicts (macOS)

If you encounter `OMP: Error #15` about multiple OpenMP libraries:

```bash
# Add to your shell config (~/.zshrc or ~/.bashrc)
export KMP_DUPLICATE_LIB_OK=TRUE
```

## Environment Variables

Set these for full functionality:

```bash
# nnU-Net paths
export nnUNet_raw="/path/to/nnUNet_raw"
export nnUNet_preprocessed="/path/to/nnUNet_preprocessed"
export nnUNet_results="/path/to/nnUNet_results"

# Optional: Elastix for spine tracking
export ELASTIX_PATH="/path/to/elastix_5_2"

# Optional: Vaa3D for SWC generation
export VAA3D_PATH="/path/to/Vaa3D"
```

## Testing Your Installation

```python
from RESPAN.Environment import *

# Check GPU availability
main.check_gpu()

# Initialize test settings
settings, locations = main.initialize_RESPAN("/path/to/test/data")
print("Environment configured successfully!")
```

## Updating Dependencies

```bash
# Update conda environment
conda env update -f environment.yml --prune

# Update pip packages
pip install -r requirements.txt --upgrade
```

## Additional Resources

- **CARE Models:** https://github.com/CSBDeep/CSBDeep
- **SelfNet:** See project documentation
- **nnU-Net:** https://github.com/MIC-DKFZ/nnUNet
- **Elastix:** https://elastix.lumc.nl/

## Getting Help

If you encounter issues:

1. Check the main RESPAN documentation
2. Review log files in your data directory
3. File an issue on the GitHub repository
4. Contact: luke.hammond@osumc.edu
