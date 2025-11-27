"""
Setup file for RESPAN - REStoration and Spine ANalysis
"""

from setuptools import setup, find_packages
import os

# Try to read README if it exists
long_description = "RESPAN - REStoration and Spine ANalysis pipeline for dendritic spines"
readme_path = os.path.join(os.path.dirname(__file__), "RESPAN", "README_ENVIRONMENT.md")
if os.path.exists(readme_path):
    with open(readme_path, "r", encoding="utf-8") as fh:
        long_description = fh.read()

setup(
    name="RESPAN",
    version="1.0.0",
    author="Luke Hammond",
    author_email="luke.hammond@osumc.edu",
    description="A deep learning pipeline for automated restoration, segmentation, and quantification of dendritic spines",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/lahammond/RESPAN",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Science/Research",
        "Topic :: Scientific/Engineering :: Image Processing",
        "Topic :: Scientific/Engineering :: Artificial Intelligence",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
    ],
    python_requires=">=3.8,<3.11",
    install_requires=[
        "numpy>=1.21.0,<2.0.0",
        "scipy>=1.7.0",
        "pandas>=1.3.0",
        "tifffile>=2021.7.2",
        "scikit-image>=0.18.0",
        "nibabel>=3.2.0",
        "trimesh>=3.9.0",
        "patchify>=0.2.3",
        "tensorflow>=2.8.0,<2.16.0",
        "csbdeep>=0.7.0",
        "torch>=1.10.0",
        "torchvision>=0.11.0",
        "dask[complete]>=2022.1.0",
        "dask-image>=2021.12.0",
        "distributed>=2022.1.0",
        "zarr>=2.10.0",
        "ome-zarr>=0.6.0",
        "numcodecs>=0.9.0",
        "PyQt5>=5.15.0",
        "psutil>=5.8.0",
        "pynvml>=11.0.0",
        "memory-profiler>=0.60.0",
        "PyYAML>=5.4.0",
        "matplotlib>=3.4.0",
        "ipython>=7.0.0",
    ],
    extras_require={
        "gpu": ["cupy-cuda11x>=10.0.0"],
        "dev": ["pytest", "black", "flake8"],
    },
    include_package_data=True,
    package_data={
        "RESPAN": [
            "Templates/*.yaml",
            "Elastix_params/*.txt",
            "ImageJ_Macros/*.ijm",
        ],
    },
)
