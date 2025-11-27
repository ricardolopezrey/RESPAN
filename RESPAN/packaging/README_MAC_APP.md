# Building `RESPAN.app` on macOS

RESPAN ships with two conda environments:

- **`respan99`** – development environment used to run PyInstaller.
- **`respan`** – minimal runtime that gets embedded inside the `.app` bundle (extracted into `Contents/MacOS/_internal/respan`).

`Scripts/RESPAN_GUI_DIST.py` already detects whether it is running from a frozen bundle and looks for the embedded environment, so the remaining work is to 1) freeze the GUI with PyInstaller and 2) drop the packed conda env plus helper scripts into `_internal/`.

## 1. Quick start (automated script)

```bash
./packaging/build_macos_app.sh
```

By default the script will:

- pack the `respan` runtime environment with `conda-pack`
- run PyInstaller from the `respan99` dev environment
- extract the runtime into `dist/RESPAN.app/Contents/MacOS/_internal/respan`
- copy the helper scripts (clean launcher + SelfNet tools)

Flags such as `--skip-pack-runtime`, `--skip-pyinstaller`, `--runtime-env <name>`, and `--dev-env <name>` give you more control; run `./packaging/build_macos_app.sh --help` for details.

The manual steps below are still useful if you want to understand or customize each phase.

## 2. Prerequisites

- Xcode command-line tools (`xcode-select --install`)
- Conda (Miniconda/Anaconda)
- Active RESPAN checkout (this repo)

Install build helpers inside the dev environment:

```bash
conda activate respan99
pip install --upgrade pyinstaller==6.11 conda-pack==0.7
```

## 3. Create the embedded `respan` environment

```bash
conda env create -f environment.yml -n respan
conda activate respan
pip install -e .
pip install --upgrade conda-pack
conda-pack -n respan -o packaging/respan_macos_env.tar.gz
```

This tarball contains the full runtime interpreter (including `RESPAN.sitecustomize` and the CuPy CPU stub) and will later be unpacked inside the bundle.

## 4. Freeze the GUI with PyInstaller

```bash
conda activate respan99
pyinstaller packaging/RESPAN_mac.spec --noconfirm --clean
```

Artifacts land in `dist/RESPAN.app`. The spec file already whitelists template YAML files, Elastix parameters, ImageJ macros, and the RESPAN package.

## 5. Assemble `_internal`

```bash
APP_ROOT="dist/RESPAN.app/Contents/MacOS"
mkdir -p "$APP_ROOT/_internal"

# Unpack the runtime env
mkdir -p "$APP_ROOT/_internal"
tar -xzf packaging/respan_macos_env.tar.gz -C "$APP_ROOT/_internal"
# conda-pack produces a top-level "respan" folder, so the path becomes
# Contents/MacOS/_internal/respan/bin/python

# Copy helper scripts that frozen mode expects next to the env
cp RESPAN/Scripts/clean_launcher.py "$APP_ROOT/_internal/"
cp RESPAN/Scripts/SelfNet_Inference.py "$APP_ROOT/_internal/"
cp RESPAN/Scripts/SelfNet_Model_Training.py "$APP_ROOT/_internal/"

# Optional: include nnU-Net CLI installation if you have one prepared
# rsync -av /path/to/nnUNet_install "$APP_ROOT/_internal/"
```

The GUI looks for `clean_launcher.py`, `SelfNet_Inference.py`, and `SelfNet_Model_Training.py` inside `_internal/` when launching nnU-Net, CARE, and SelfNet helpers, so keep these filenames intact.

## 6. Smoke test

```bash
open dist/RESPAN.app
# or run headless for logs
dist/RESPAN.app/Contents/MacOS/RESPAN --help
```

Expect to see the CuPy CPU stub warning on macOS—this is normal because NVIDIA CUDA is not available on Apple hardware.

## 7. (Optional) Codesign & notarize

Before distributing the app, sign it with your Developer ID and notarize:

```bash
codesign --force --deep --options runtime \
  --sign "Developer ID Application: YOUR NAME (TEAMID)" \
  dist/RESPAN.app

xcrun notarytool submit dist/RESPAN.zip \
  --keychain-profile "AC_NOTARY" --wait
```

(Zip the `.app` before submission: `ditto -c -k --sequesterRsrc --keepParent dist/RESPAN.app dist/RESPAN.zip`.)

## 8. Automating the process

For reproducible builds consider wrapping the steps above in a shell script or CI workflow:

1. Create/update `respan` and pack it with `conda-pack`.
2. Run `pyinstaller packaging/RESPAN_mac.spec`.
3. Extract the env, copy helper scripts, and (optionally) `nnUNet_install` into `_internal/`.
4. Codesign/notarize.

That results in a fully self-contained `RESPAN.app` that mirrors the Windows frozen build behaviour while remaining macOS-native.
