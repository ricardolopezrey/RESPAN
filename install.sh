#!/usr/bin/env bash
set -e

########################################
# RESPAN Installation Script
# Cross-platform: Linux, macOS, Windows (Git Bash/WSL)
########################################

# CONFIG – edit these if needed
########################################

# CUDA version for CuPy on Linux/Windows (11x or 12x)
CUDA_VERSION="11x"

# Environment name
ENV_NAME="respan99"

########################################
# Detect OS
########################################

detect_os() {
  case "$(uname -s)" in
    Linux*)   OS="linux" ;;
    Darwin*)  OS="macos" ;;
    MINGW*|MSYS*|CYGWIN*) OS="windows" ;;
    *)        OS="unknown" ;;
  esac
  echo "$OS"
}

OS=$(detect_os)
echo "Detected OS: $OS"

# Detect architecture (for Apple Silicon)
ARCH=$(uname -m)
echo "Architecture: $ARCH"

########################################
# Find conda installation
########################################

find_conda() {
  # Common conda locations
  local locations=(
    "$CONDA_PREFIX"
    "$HOME/miniconda3"
    "$HOME/anaconda3"
    "$HOME/mambaforge"
    "$HOME/miniforge3"
    "/opt/anaconda3"
    "/opt/miniconda3"
    "/opt/conda"
    "$LOCALAPPDATA/miniconda3"
    "$LOCALAPPDATA/anaconda3"
    "/c/Users/$USER/miniconda3"
    "/c/Users/$USER/anaconda3"
  )

  for loc in "${locations[@]}"; do
    if [ -d "$loc" ] && [ -f "$loc/etc/profile.d/conda.sh" ]; then
      echo "$loc"
      return 0
    fi
  done

  # Try to find via which
  if command -v conda &> /dev/null; then
    local conda_exe=$(which conda)
    local conda_base=$(dirname $(dirname "$conda_exe"))
    if [ -f "$conda_base/etc/profile.d/conda.sh" ]; then
      echo "$conda_base"
      return 0
    fi
  fi

  return 1
}

CONDA_BASE=$(find_conda) || {
  echo "ERROR: Could not find conda installation."
  echo "Please install Miniconda or Anaconda:"
  echo "  https://docs.conda.io/en/latest/miniconda.html"
  exit 1
}

echo "Found conda at: $CONDA_BASE"

# Load conda in this shell
source "$CONDA_BASE/etc/profile.d/conda.sh"

# Check for mamba, fall back to conda
if command -v mamba &> /dev/null; then
  INSTALLER="mamba"
else
  INSTALLER="conda"
  echo "Note: mamba not found, using conda (slower)."
  echo "  Install mamba for faster installs: conda install -n base -c conda-forge mamba"
fi

echo "Using $INSTALLER"

########################################
# Check GPU availability
########################################

echo ""
echo "=== Checking GPU availability ==="

GPU_TYPE="cpu"

if [ "$OS" = "macos" ]; then
  if [ "$ARCH" = "arm64" ]; then
    echo "Apple Silicon detected - MPS (Metal) will be used for PyTorch"
    GPU_TYPE="mps"
  else
    echo "Intel Mac detected - CPU mode"
    GPU_TYPE="cpu"
  fi
elif [ "$OS" = "linux" ] || [ "$OS" = "windows" ]; then
  if command -v nvidia-smi &> /dev/null; then
    echo "NVIDIA GPU detected:"
    nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv 2>/dev/null || true
    GPU_TYPE="cuda"
  else
    echo "No NVIDIA GPU detected - CPU mode"
    GPU_TYPE="cpu"
  fi
fi

echo "GPU mode: $GPU_TYPE"

########################################
# Create conda environment
########################################

echo ""
echo "=== Creating env: $ENV_NAME ==="

# Remove existing environment if it exists
if conda env list | grep -q "^$ENV_NAME "; then
  echo "Environment $ENV_NAME already exists. Removing..."
  conda env remove -n $ENV_NAME -y
fi

$INSTALLER create -n $ENV_NAME python=3.10 \
  scikit-image pandas "numpy<2.0" \
  nibabel ipython pyyaml numba \
  dask dask-image ome-zarr zarr memory_profiler trimesh \
  psutil tifffile \
  -c conda-forge -y

conda activate $ENV_NAME

########################################
# Install platform-specific packages
########################################

echo ""
echo "=== Installing packages for $OS ($GPU_TYPE) ==="

# TensorFlow
if [ "$OS" = "macos" ] && [ "$ARCH" = "arm64" ]; then
  echo "Installing TensorFlow for Apple Silicon..."
  pip install tensorflow-macos tensorflow-metal
else
  echo "Installing TensorFlow..."
  pip install "tensorflow>=2.8.0,<2.16.0"
fi

# PyTorch
echo "Installing PyTorch..."
if [ "$GPU_TYPE" = "cuda" ]; then
  pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
elif [ "$GPU_TYPE" = "mps" ]; then
  # MPS support is included in standard PyTorch for macOS
  pip install torch torchvision torchaudio
else
  # CPU-only
  pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
fi

# CuPy (GPU image processing)
echo "Installing CuPy..."
if [ "$GPU_TYPE" = "cuda" ]; then
  pip install cupy-cuda${CUDA_VERSION}
else
  # CPU fallback or skip on macOS (no CUDA)
  echo "CuPy-CUDA not available on $OS. Some GPU features will be disabled."
  echo "Installing cupy-cpu as fallback..."
  pip install cupy-cpu || echo "cupy-cpu installation failed - continuing without CuPy"
fi

# Core RESPAN dependencies
echo "Installing core dependencies..."
pip install "scipy>=1.7.0" csbdeep pyqt5 "patchify==0.2.3"

# nnU-Net v2
echo "Installing nnU-Net..."
pip install nnunetv2

########################################
# Install RESPAN package
########################################

echo ""
echo "=== Installing RESPAN in editable mode ==="

pip install -e .

conda deactivate

########################################
# Set up nnU-Net directories
########################################

echo ""
echo "=== Setting up nnU-Net paths ==="

NNUNET_BASE="$(pwd)/nnUNet"

mkdir -p "$NNUNET_BASE/nnUNet_raw"
mkdir -p "$NNUNET_BASE/nnUNet_preprocessed"
mkdir -p "$NNUNET_BASE/nnUNet_results"

########################################
# Print summary
########################################

echo ""
echo "====================================="
echo "Installation complete!"
echo "====================================="
echo ""
echo "Platform: $OS ($ARCH)"
echo "GPU mode: $GPU_TYPE"
echo "Environment: $ENV_NAME"
echo ""
echo "To activate:"
echo "  conda activate $ENV_NAME"
echo ""

if [ "$OS" = "windows" ]; then
  echo "Add these environment variables (System Properties > Environment Variables):"
  echo "  nnUNet_raw = $NNUNET_BASE/nnUNet_raw"
  echo "  nnUNet_preprocessed = $NNUNET_BASE/nnUNet_preprocessed"
  echo "  nnUNet_results = $NNUNET_BASE/nnUNet_results"
else
  echo "Add these to your ~/.bashrc or ~/.zshrc:"
  echo ""
  echo "  export nnUNet_raw=\"$NNUNET_BASE/nnUNet_raw\""
  echo "  export nnUNet_preprocessed=\"$NNUNET_BASE/nnUNet_preprocessed\""
  echo "  export nnUNet_results=\"$NNUNET_BASE/nnUNet_results\""
fi

echo ""
echo "Verify installation:"
echo "  conda activate $ENV_NAME"
echo "  python -c \"from RESPAN.Environment import main; main.check_gpu()\""
echo ""

if [ "$OS" = "macos" ]; then
  echo "Note: On macOS, GPU acceleration (CuPy/CUDA) is not available."
  echo "nnU-Net will use MPS (Metal) for inference. Some optional features"
  echo "(neck generation, GPU mesh analysis) will be skipped."
  echo ""
fi

echo "====================================="
