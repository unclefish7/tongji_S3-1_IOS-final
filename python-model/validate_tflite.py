import tensorflow as tf
import numpy as np
from PIL import Image

# 加载 TFLite 模型
interpreter = tf.lite.Interpreter(model_path="fine_tunable_model.tflite")

# 函数：动态调整输入张量形状
def resize_model_input(interpreter, input_details, image_path, input_index):
    image = Image.open(image_path)
    width, height = image.size
    print(f"Image {image_path} dimensions: {width}x{height}")
    new_shape = [1, height, width, 3]  # 动态调整输入形状
    interpreter.resize_tensor_input(input_details[input_index]['index'], new_shape)
    interpreter.allocate_tensors()  # 重新分配张量缓冲区
    return new_shape

# 函数：预处理图片
def preprocess_image(image_path, target_size=None):
    image = Image.open(image_path)
    if target_size:
        image = image.resize(target_size)
    image = np.asarray(image).astype(np.float32) / 255.0
    return np.expand_dims(image, axis=0)  # 添加批量维度

# 动态调整内容图片输入形状
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# 调整内容图片输入张量形状
content_image_path = "content.jpg"
content_shape = resize_model_input(interpreter, input_details, content_image_path, 0)
content_image = preprocess_image(content_image_path)

# 调整风格图片输入张量形状
style_image_path = "style.jpg"
style_shape = resize_model_input(interpreter, input_details, style_image_path, 1)
style_image = preprocess_image(style_image_path)

# 检查输出张量形状
output_details = interpreter.get_output_details()  # 动态调整后重新获取输出细节
print("Output tensor shape:", output_details[0]['shape'])

# 设置输入张量
interpreter.set_tensor(input_details[0]['index'], content_image)
interpreter.set_tensor(input_details[1]['index'], style_image)

# 执行推理
interpreter.invoke()

# 获取输出张量
stylized_image = interpreter.get_tensor(output_details[0]['index'])

# 动态后处理：根据输入调整输出形状
stylized_image = np.squeeze(stylized_image) * 255  # 去掉批量维度并反归一化
stylized_image = stylized_image.astype(np.uint8)

# 保存结果
Image.fromarray(stylized_image).save("stylized_image_tflite.jpg")
print("Inference complete. Output saved as stylized_image_tflite.jpg.")
