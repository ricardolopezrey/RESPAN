import tensorflow as tf

print("TensorFlow version:", tf.__version__)
print("GPUs:", tf.config.list_physical_devices("GPU"))

with tf.device("/GPU:0"):
    a = tf.random.uniform((2000, 2000))
    b = tf.random.uniform((2000, 2000))
    c = tf.matmul(a, b)

print("OK, result shape:", c.shape)
