#!/usr/bin/env bash
set -e

########################################
# CONFIG – edit this if needed
########################################

# Path to your conda/mamba installation
# Common options:
#   $HOME/miniconda3
#   $HOME/mambaforge
CONDA_BASE="/opt/anaconda3"

########################################
# Init conda / mamba
########################################

if [ ! -d "$CONDA_BASE" ]; then
  echo "ERROR: CONDA_BASE='$CONDA_BASE' does not exist. Edit the script to match your conda/mamba path."
  exit 1
fi

# Load conda in this shell
# (This gives us 'conda' and 'mamba' commands)
source "$CONDA_BASE/etc/profile.d/conda.sh"

echo "Using conda from: $CONDA_BASE"

########################################
# 1) respandev environment (Apple Silicon)
########################################

echo "=== Creating env: respandev ==="

mamba create -n respandev python=3.9 \
  scikit-image pandas "numpy=1.23.4" \
  nibabel pyinstaller ipython pyyaml numba \
  dask dask-image ome-zarr zarr memory_profiler trimesh \
  -c conda-forge -y

conda activate respandev

echo "=== Installing pip packages in respandev ==="

# TensorFlow for Apple Silicon (Metal backend)
pip install tensorflow-macos tensorflow-metal

# CuPy with Metal backend (for M1/M2/M3)
#pip install cupy-metal

# Remaining Python packages
pip install "scipy==1.13.1" csbdeep pyqt5 "patchify==0.2.3"

conda deactivate

########################################
# 2) respaninternal environment (Apple Silicon)
########################################

echo "=== Creating env: respaninternal ==="

mamba create -n respaninternal python=3.9 scikit-image opencv -c conda-forge -y

conda activate respaninternal

echo "=== Installing PyTorch (MPS support) in respaninternal ==="

# PyTorch for macOS / Apple Silicon (MPS backend is included automatically)
pip install torch torchvision torchaudio

########################################
# 3) nnUNet v2.3.1 (installed into respaninternal)
########################################

echo "=== Cloning and installing nnUNet v2.3.1 ==="

# Clone into current directory if not already present
if [ ! -d "nnUNet" ]; then
  git clone -b v2.3.1 https://github.com/MIC-DKFZ/nnUNet.git
fi

cd nnUNet
pip install -e .
cd ..

conda deactivate

echo "====================================="
echo "Done!"
echo "Environments created:"
echo "  - respandev"
echo "  - respaninternal (with nnUNet)"
echo ""
echo "Use:"
echo "  conda activate respandev"
echo "  conda activate respaninternal"
echo "====================================="
