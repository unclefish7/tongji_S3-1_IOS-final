import tensorflow as tf

# 替换为你的模型路径
# model_path = "./python/classifier.tflite"
model_path = "./python/pose_classifier.tflite"

# 加载 TFLite 模型
interpreter = tf.lite.Interpreter(model_path=model_path)
interpreter.allocate_tensors()

# 获取模型输入和输出信息
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# 打印输入信息
print("输入信息:")
for detail in input_details:
    print(f"  名称: {detail['name']}")
    print(f"  形状: {detail['shape']}")
    print(f"  数据类型: {detail['dtype']}")

# 打印输出信息
print("\n输出信息:")
for detail in output_details:
    print(f"  名称: {detail['name']}")
    print(f"  形状: {detail['shape']}")
    print(f"  数据类型: {detail['dtype']}")
