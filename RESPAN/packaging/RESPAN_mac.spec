# -*- mode: python ; coding: utf-8 -*-

from pathlib import Path
import inspect
from PyInstaller.utils.hooks import collect_data_files, collect_submodules

block_cipher = None

try:
    spec_file = Path(__file__).resolve()
except NameError:
    spec_file = Path(inspect.getfile(inspect.currentframe())).resolve()

project_root = spec_file.parents[1]
package_root = project_root
entry_script = package_root / "Scripts" / "RESPAN_GUI_DIST.py"

# Collect template/config resources that need to be available at runtime
package_datas = collect_data_files(
    "RESPAN",
    includes=[
        "Templates/*",
        "Elastix_params/*",
        "Scripts/clean_launcher.py",
        "Scripts/SelfNet_*.py",
        "ImageJ_Macros/*",
    ],
)

# Extra top-level docs (optional but useful for support)
extra_datas = [
    (str(project_root / "README_ENVIRONMENT.md"), "."),
    (str(project_root / "README.md"), ".") if (project_root / "README.md").exists() else None,
]
extra_datas = [item for item in extra_datas if item]

datas = package_datas + extra_datas

hiddenimports = collect_submodules("RESPAN")
hiddenimports += [
    "skimage.io._plugins.tifffile_plugin",
    "skimage.io._plugins",
    "RESPAN.cupy_stub",
    "RESPAN.sitecustomize",
]

analysis = Analysis(
    [str(entry_script)],
    pathex=[str(package_root)],
    binaries=[],
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(analysis.pure, analysis.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    analysis.scripts,
    analysis.binaries,
    analysis.zipfiles,
    analysis.datas,
    [],
    name="RESPAN",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

app = BUNDLE(
    exe,
    name="RESPAN.app",
    icon=None,
    bundle_identifier="org.osumc.respan",
)
