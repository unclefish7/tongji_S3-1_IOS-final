import tensorflow as tf
import tensorflow_hub as hub

# 步骤 1: 从 TensorFlow Hub 加载模型
def download_and_save_hub_model():
    print("Loading model from TensorFlow Hub...")
    hub_model = hub.load("https://tfhub.dev/google/magenta/arbitrary-image-stylization-v1-256/2")

    # 定义签名函数（显式绑定输入和输出）
    @tf.function
    def stylize(content_image, style_image):
        outputs = hub_model(content_image, style_image)
        return {"stylized_image": outputs[0]}

    # 创建输入张量规格（动态输入支持）
    content_image_spec = tf.TensorSpec(shape=[1, None, None, 3], dtype=tf.float32, name="content_image")
    style_image_spec = tf.TensorSpec(shape=[1, None, None, 3], dtype=tf.float32, name="style_image")

    # 保存为 SavedModel 格式，绑定签名
    tf.saved_model.save(
        hub_model,
        "saved_model_arbitrary_style_transfer",
        signatures={"serving_default": stylize.get_concrete_function(content_image_spec, style_image_spec)}
    )
    print("Model saved as 'saved_model_arbitrary_style_transfer' with explicit signature.")

# 步骤 2: 将 SavedModel 转换为 TFLite 格式
def convert_to_tflite(saved_model_dir, output_tflite_path):
    print(f"Converting model from '{saved_model_dir}' to TFLite format...")
    converter = tf.lite.TFLiteConverter.from_saved_model(saved_model_dir)
    
    # 启用优化（可选）
    converter.optimizations = [tf.lite.Optimize.DEFAULT]  # 启用默认优化
    # 如果需要使用 float16 优化，请取消注释以下行
    # converter.target_spec.supported_types = [tf.float16]

    # 转换为 TFLite 模型
    tflite_model = converter.convert()

    # 保存 TFLite 模型
    with open(output_tflite_path, "wb") as f:
        f.write(tflite_model)
    print(f"TFLite model saved as '{output_tflite_path}'.")

# 主流程
if __name__ == "__main__":
    # 定义路径
    saved_model_dir = "saved_model_arbitrary_style_transfer"
    tflite_model_path = "arbitrary_style_transfer.tflite"

    # 下载并保存 TensorFlow Hub 模型
    download_and_save_hub_model()

    # 转换为 TFLite 模型
    convert_to_tflite(saved_model_dir, tflite_model_path)
