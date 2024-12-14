import tensorflow as tf
import tensorflow_hub as hub

# 加载 TensorFlow Hub 模型
hub_model = hub.load("https://tfhub.dev/google/magenta/arbitrary-image-stylization-v1-256/2")


# 创建 Fine-Tunable 模型
class FineTunableModel(tf.keras.Model):
    def __init__(self, hub_model):
        super(FineTunableModel, self).__init__()
        self.hub_model = hub_model

    def call(self, inputs):
        # 拆解字典输入为位置参数
        content_image = inputs["placeholder"]       # 内容图片
        style_image = inputs["placeholder_1"]      # 风格图片
        outputs = self.hub_model(content_image, style_image)  # 传递为独立张量
        return outputs[0]  # 提取风格化结果

# 实例化 FineTunableModel
model = FineTunableModel(hub_model)

# 定义签名函数，适配输入格式
@tf.function(input_signature=[
    tf.TensorSpec(shape=[None, None, None, 3], dtype=tf.float32),  # 内容图片
    tf.TensorSpec(shape=[None, None, None, 3], dtype=tf.float32)   # 风格图片
])
def stylize(content_image, style_image):
    # 构造输入字典
    inputs = {
        "placeholder": content_image,
        "placeholder_1": style_image
    }
    # 调用 FineTunableModel 进行推理
    stylized_image = model(inputs)
    return {"stylized_image": stylized_image}

# 保存模型为 SavedModel 格式
tf.saved_model.save(
    model,
    "fine_tunable_model",
    signatures={"serving_default": stylize.get_concrete_function()}
)
print("SavedModel successfully saved with Signature.")