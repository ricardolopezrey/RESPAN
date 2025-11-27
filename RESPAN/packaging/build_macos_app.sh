#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
RESPAN_DIR="$PROJECT_ROOT"
PACKAGING_DIR="$PROJECT_ROOT/packaging"
SPEC_FILE="$PACKAGING_DIR/RESPAN_mac.spec"
DIST_APP="$PROJECT_ROOT/dist/RESPAN.app"
APP_ROOT="$DIST_APP/Contents/MacOS"
INTERNAL_DIR="$APP_ROOT/_internal"
RUNTIME_TAR="$PACKAGING_DIR/respan_macos_env.tar.gz"
NNUNET_SRC="$RESPAN_DIR/nnUNet_install"

RUNTIME_ENV="respan"
DEV_ENV="respan99"
PACK_RUNTIME=true
RUN_PYINSTALLER=true
SKIP_NNUNET_COPY=false

usage() {
  cat <<'EOF'
Usage: packaging/build_macos_app.sh [options]

Options:
  --runtime-env NAME     Conda env to embed (default: respan)
  --dev-env NAME         Conda env that has PyInstaller (default: respan99)
  --skip-pack-runtime    Re-use existing packaging/respan_macos_env.tar.gz
  --skip-pyinstaller     Re-use existing dist/RESPAN.app bundle
  --skip-nnunet          Do not copy RESPAN/nnUNet_install into the bundle
  -h, --help             Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --runtime-env)
      RUNTIME_ENV="$2"; shift 2 ;;
    --dev-env)
      DEV_ENV="$2"; shift 2 ;;
    --skip-pack-runtime)
      PACK_RUNTIME=false; shift ;;
    --skip-pyinstaller)
      RUN_PYINSTALLER=false; shift ;;
    --skip-nnunet)
      SKIP_NNUNET_COPY=true; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1 ;;
  esac
done

command -v conda >/dev/null 2>&1 || { echo "conda command not found" >&2; exit 1; }

if [[ ! -f "$SPEC_FILE" ]]; then
  echo "PyInstaller spec file not found at $SPEC_FILE" >&2
  exit 1
fi

mkdir -p "$PACKAGING_DIR"
mkdir -p "$PROJECT_ROOT/dist"

if $PACK_RUNTIME; then
  if [[ -f "$PROJECT_ROOT/setup.py" || -f "$PROJECT_ROOT/pyproject.toml" ]]; then
    echo "[1/4] Ensuring RESPAN is installed inside '$RUNTIME_ENV'..."
    conda run -n "$RUNTIME_ENV" pip install -e "$PROJECT_ROOT" >/dev/null
  else
    echo "[1/4] Skipping pip install -e (setup.py/pyproject.toml not found)"
  fi

  if ! conda run -n "$RUNTIME_ENV" python -c "import conda_pack" >/dev/null 2>&1; then
    echo "      Installing conda-pack inside '$RUNTIME_ENV'..."
    conda run -n "$RUNTIME_ENV" pip install conda-pack >/dev/null
  fi

  echo "[2/4] Packing runtime environment '$RUNTIME_ENV' -> $RUNTIME_TAR"
  conda run -n "$RUNTIME_ENV" conda-pack -o "$RUNTIME_TAR" --force >/dev/null
else
  echo "Skipping runtime packing (using existing $RUNTIME_TAR)"
fi

if $RUN_PYINSTALLER; then
  if ! conda run -n "$DEV_ENV" python -c "import PyInstaller" >/dev/null 2>&1; then
    echo "      Installing PyInstaller inside '$DEV_ENV'..."
    conda run -n "$DEV_ENV" pip install pyinstaller >/dev/null
  fi
  echo "[3/4] Freezing GUI with PyInstaller (env: $DEV_ENV)"
  conda run -n "$DEV_ENV" pyinstaller "$SPEC_FILE" --clean --noconfirm
else
  echo "Skipping PyInstaller build (using existing $DIST_APP)"
fi

if [[ ! -d "$DIST_APP" ]]; then
  echo "Expected bundle not found at $DIST_APP" >&2
  exit 1
fi

echo "[4/4] Assembling embedded environment"
rm -rf "$INTERNAL_DIR"
mkdir -p "$INTERNAL_DIR"
tar -xzf "$RUNTIME_TAR" -C "$INTERNAL_DIR"

cp "$RESPAN_DIR/Scripts/clean_launcher.py" "$INTERNAL_DIR/"
cp "$RESPAN_DIR/Scripts/SelfNet_Inference.py" "$INTERNAL_DIR/"
cp "$RESPAN_DIR/Scripts/SelfNet_Model_Training.py" "$INTERNAL_DIR/"

if [[ -d "$NNUNET_SRC" && $SKIP_NNUNET_COPY = false ]]; then
  rsync -a "$NNUNET_SRC" "$INTERNAL_DIR/"
fi

echo "✅ RESPAN.app ready at $DIST_APP"
echo "Next steps: codesign / notarize if distributing outside your machine."
