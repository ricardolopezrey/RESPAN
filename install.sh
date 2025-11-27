#!/usr/bin/env bash
set -e

########################################
# RESPAN Installation Script - Linux/CUDA
########################################

# CONFIG – edit these if needed
########################################

# Path to your conda/mamba installation
# Common options:
#   $HOME/miniconda3
#   $HOME/mambaforge
#   /opt/conda
CONDA_BASE="$HOME/miniconda3"

# CUDA version for CuPy (11x or 12x)
CUDA_VERSION="11x"

########################################
# Init conda / mamba
########################################

if [ ! -d "$CONDA_BASE" ]; then
  echo "ERROR: CONDA_BASE='$CONDA_BASE' does not exist."
  echo "Edit this script to match your conda/mamba path, or install miniconda:"
  echo "  wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
  echo "  bash Miniconda3-latest-Linux-x86_64.sh"
  exit 1
fi

# Load conda in this shell
source "$CONDA_BASE/etc/profile.d/conda.sh"

# Check for mamba, fall back to conda
if command -v mamba &> /dev/null; then
  INSTALLER="mamba"
else
  INSTALLER="conda"
  echo "Note: mamba not found, using conda (slower). Install mamba for faster installs:"
  echo "  conda install -n base -c conda-forge mamba"
fi

echo "Using $INSTALLER from: $CONDA_BASE"

########################################
# Check CUDA availability
########################################

echo "=== Checking CUDA installation ==="

if command -v nvidia-smi &> /dev/null; then
  echo "NVIDIA driver found:"
  nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv
else
  echo "WARNING: nvidia-smi not found. CUDA may not be available."
  echo "GPU acceleration requires NVIDIA drivers and CUDA toolkit."
fi

if command -v nvcc &> /dev/null; then
  echo "CUDA compiler version:"
  nvcc --version | grep release
else
  echo "WARNING: nvcc not found. Install CUDA toolkit for full GPU support."
fi

########################################
# 1) respan99 environment (main RESPAN env)
########################################

echo ""
echo "=== Creating env: respan99 ==="

$INSTALLER create -n respan99 python=3.10 \
  scikit-image pandas "numpy<2.0" \
  nibabel pyinstaller ipython pyyaml numba \
  dask dask-image ome-zarr zarr memory_profiler trimesh \
  psutil \
  -c conda-forge -y

conda activate respan99

echo "=== Installing pip packages in respan99 ==="

# TensorFlow with CUDA support
pip install "tensorflow>=2.8.0,<2.16.0"

# CuPy with CUDA support
pip install cupy-cuda${CUDA_VERSION}

# PyTorch with CUDA support
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Core RESPAN dependencies
pip install "scipy>=1.7.0" csbdeep pyqt5 "patchify==0.2.3" tifffile

# nnU-Net v2
pip install nnunetv2

conda deactivate

########################################
# 2) Install RESPAN package
########################################

echo ""
echo "=== Installing RESPAN in editable mode ==="

conda activate respan99

# Install RESPAN from current directory
pip install -e .

conda deactivate

########################################
# 3) Set up nnU-Net environment variables
########################################

echo ""
echo "=== Setting up nnU-Net paths ==="

NNUNET_BASE="$(pwd)/nnUNet"

# Create directories if they don't exist
mkdir -p "$NNUNET_BASE/nnUNet_raw"
mkdir -p "$NNUNET_BASE/nnUNet_preprocessed"
mkdir -p "$NNUNET_BASE/nnUNet_results"

echo ""
echo "====================================="
echo "Installation complete!"
echo "====================================="
echo ""
echo "Environment created: respan99"
echo ""
echo "To activate:"
echo "  conda activate respan99"
echo ""
echo "Add these to your ~/.bashrc or ~/.zshrc for nnU-Net:"
echo ""
echo "  export nnUNet_raw=\"$NNUNET_BASE/nnUNet_raw\""
echo "  export nnUNet_preprocessed=\"$NNUNET_BASE/nnUNet_preprocessed\""
echo "  export nnUNet_results=\"$NNUNET_BASE/nnUNet_results\""
echo ""
echo "Verify installation:"
echo "  conda activate respan99"
echo "  python -c \"from RESPAN.Environment import main; main.check_gpu()\""
echo ""
echo "====================================="
