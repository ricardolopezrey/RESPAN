"""Global sitecustomize for RESPAN.

This module is imported automatically by Python (if present on sys.path)
before any other site-specific customizations. We use it to silence
third‑party deprecation warnings that we cannot control directly, in
particular the ``FutureWarning`` emitted when importing ``pynvml`` via
PyTorch/nnU‑Net. This keeps the RESPAN logs clean without altering
functional behaviour.
"""

import warnings


# Suppress the noisy pynvml deprecation warning that comes from
# torch.cuda importing ``pynvml``. We still allow other FutureWarnings
# so they remain visible during development.
warnings.filterwarnings(
	"ignore",
	category=FutureWarning,
	message=r".*pynvml package is deprecated.*",
)
