import tensorflow as tf
import tensorflow_hub as hub
import matplotlib.pyplot as plt
import requests
from PIL import Image
from io import BytesIO

# 从 URL 下载图片并加载为 PIL.Image 格式
def download_image(url, max_dim=None):
    response = requests.get(url)
    image = Image.open(BytesIO(response.content))
    if max_dim:
        scale = max_dim / max(image.size)
        new_size = (int(image.size[0] * scale), int(image.size[1] * scale))
        image = image.resize(new_size)
    return image

# 将 PIL.Image 转换为 TensorFlow 格式
def image_to_tensor(image):
    image = tf.convert_to_tensor(image)
    image = tf.image.convert_image_dtype(image, tf.float32)  # 归一化到 [0, 1]
    image = tf.expand_dims(image, axis=0)  # 增加批量维度
    return image

# 将 TensorFlow 张量转换为显示格式的图片
def tensor_to_image(tensor):
    tensor = tf.squeeze(tensor, axis=0)  # 移除批量维度
    tensor = tf.image.convert_image_dtype(tensor, dtype=tf.uint8)  # 转换到 [0, 255]
    return Image.fromarray(tensor.numpy())

# 显示图片
def show_images(content_image, style_image, stylized_image):
    plt.figure(figsize=(15, 5))

    plt.subplot(1, 3, 1)
    plt.title("Content Image")
    plt.imshow(content_image)
    plt.axis("off")

    plt.subplot(1, 3, 2)
    plt.title("Style Image")
    plt.imshow(style_image)
    plt.axis("off")

    plt.subplot(1, 3, 3)
    plt.title("Stylized Image")
    plt.imshow(stylized_image)
    plt.axis("off")

    plt.show()

# 加载模型
print("Loading model...")
model = hub.load("https://tfhub.dev/google/magenta/arbitrary-image-stylization-v1-256/2")
print("Model loaded successfully!")

# 下载内容图片和风格图片
content_url = "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fd/Golden_Gate_Bridge_from_Battery_Spencer.jpg/640px-Golden_Gate_Bridge_from_Battery_Spencer.jpg"
style_url = "https://upload.wikimedia.org/wikipedia/commons/0/0a/The_Great_Wave_off_Kanagawa.jpg"

print("Downloading images...")
content_image = download_image(content_url, max_dim=512)
style_image = download_image(style_url, max_dim=256)

# 转换图片为张量格式
content_tensor = image_to_tensor(content_image)
style_tensor = image_to_tensor(style_image)

# 风格迁移
print("Stylizing the image...")
stylized_tensor = model(content_tensor, style_tensor)[0]  # 模型推理

# 转换结果为图片格式
stylized_image = tensor_to_image(stylized_tensor)

# 显示内容图片、风格图片和风格化结果
show_images(content_image, style_image, stylized_image)

# 保存结果
output_path = "stylized_image.png"
stylized_image.save(output_path)
print(f"Stylized image saved to {output_path}")
