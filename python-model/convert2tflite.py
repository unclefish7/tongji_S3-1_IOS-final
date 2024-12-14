import tensorflow as tf

# 将模型保存为 TFLite 格式
converter = tf.lite.TFLiteConverter.from_saved_model("fine_tunable_model")
# 如果需要支持设备端微调，开启转换选项
converter.optimizations = [tf.lite.Optimize.DEFAULT]  # 优化
converter.experimental_enable_resource_variables = True  # 允许资源变量
tflite_model = converter.convert()

# 保存为 .tflite 文件
with open("fine_tunable_model.tflite", "wb") as f:
    f.write(tflite_model)
print("TFLite model saved successfully.")
