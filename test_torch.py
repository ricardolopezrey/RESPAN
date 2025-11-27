import torch

print("PyTorch version:", torch.__version__)
print("MPS available:", torch.backends.mps.is_available())
print("MPS built:", torch.backends.mps.is_built())

device = torch.device("mps") if torch.backends.mps.is_available() else torch.device("cpu")
print("Using device:", device)

a = torch.randn(2000, 2000, device=device)
b = torch.randn(2000, 2000, device=device)
c = a @ b
print("OK, result shape:", c.shape)
