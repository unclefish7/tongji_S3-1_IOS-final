import coremltools as ct
import os

def convert_model():
    try:
        # 检查输入文件是否存在
        tflite_model_path = "./saved_model_arbitrary_style_transfer"
        if not os.path.exists(tflite_model_path):
            raise FileNotFoundError("TFLite 模型文件不存在")

        print("开始转换模型...")
        
        # 定义输入规格
        input_size = (1, 256, 256, 3)  # 批次大小, 高度, 宽度, 通道数
        flexible_shape = ct.RangeDim(
            lower_bound=1,
            upper_bound=8192,
            default=256
        )
        
        # 设置输入规格，使用正确的输入名称
        content_input = ct.TensorType(
            shape=(1, flexible_shape, flexible_shape, 3),
            name="content_image",  # 修改为模型中的实际名称
            dtype=float
        )
        style_input = ct.TensorType(
            shape=(1, flexible_shape, flexible_shape, 3),
            name="style_image",  # 这个名称是正确的
            dtype=float
        )
        
        # 使用 mlprogram 格式并设置正确的文件扩展名
        coreml_model = ct.convert(
            model=tflite_model_path,
            source='tensorflow',
            convert_to='mlprogram',  # 必须使用 mlprogram
            minimum_deployment_target=ct.target.iOS17,
            inputs=[content_input, style_input],  # 使用更新后的输入名称
            compute_precision=ct.precision.FLOAT32  # 指定计算精度
        )
        
        # 使用 .mlpackage 扩展名
        coreml_model_path = "./arbitrary_style_transfer.mlpackage"
        coreml_model.save(coreml_model_path)
        
        print(f"转换成功！模型已保存至: {coreml_model_path}")
        return True
        
    except Exception as e:
        print(f"转换过程中出错: {str(e)}")
        return False

if __name__ == "__main__":
    convert_model()
