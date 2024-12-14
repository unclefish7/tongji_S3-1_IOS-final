import Foundation
import TensorFlowLite
import UIKit

class StyleTransferModel {
    private var interpreter: Interpreter?

    init() {
        loadModel()
    }

    /// 加载 TFLite 模型并初始化 Interpreter
    private func loadModel() {
        guard let modelPath = Bundle.main.path(forResource: "arbitrary_style_transfer", ofType: "tflite") else {
            fatalError("TFLite model not found in project.")
        }

        do {
            // 初始化 Interpreter
            interpreter = try Interpreter(modelPath: modelPath)
            print("TFLite model successfully loaded.")
        } catch {
            fatalError("Failed to load TFLite model: \(error)")
        }
    }

    /// 动态调整输入张量的形状
    func resizeInputTensor(contentImage: UIImage, styleImage: UIImage) {
        guard let interpreter = interpreter else {
            fatalError("Interpreter is not initialized.")
        }

        // 动态获取图片的高度和宽度
        let contentHeight = Int(contentImage.size.height)
        let contentWidth = Int(contentImage.size.width)
        let styleHeight = Int(styleImage.size.height)
        let styleWidth = Int(styleImage.size.width)

        do {
            // 调整内容图片输入张量形状 [1, contentHeight, contentWidth, 3]
            try interpreter.resizeInput(at: 0, to: [1, contentHeight, contentWidth, 3])

            // 调整风格图片输入张量形状 [1, styleHeight, styleWidth, 3]
            try interpreter.resizeInput(at: 1, to: [1, styleHeight, styleWidth, 3])

            // 重新分配张量
            try interpreter.allocateTensors()
            print("Input tensors resized to content: \(contentHeight)x\(contentWidth), style: \(styleHeight)x\(styleWidth).")
        } catch {
            fatalError("Failed to resize input tensors: \(error)")
        }
    }

    /// 运行模型推理，返回风格迁移后的图片
    func runInference(contentImage: UIImage, styleImage: UIImage) -> UIImage? {
        guard let interpreter = interpreter else {
            fatalError("Interpreter is not initialized.")
        }

        do {
            // 动态调整输入张量形状
            resizeInputTensor(contentImage: contentImage, styleImage: styleImage)

            // 获取动态调整后的张量形状
            let contentTensorShape = try interpreter.input(at: 0).shape
            let styleTensorShape = try interpreter.input(at: 1).shape

            // 将 Tensor.Shape 转换为 [Int]
            let contentTensorShapeArray = contentTensorShape.dimensions
            let styleTensorShapeArray = styleTensorShape.dimensions

            // 预处理图片
            let contentTensor = preprocessImage(image: contentImage, tensorShape: contentTensorShapeArray)
            let styleTensor = preprocessImage(image: styleImage, tensorShape: styleTensorShapeArray)

            // 设置输入张量
            try interpreter.copy(contentTensor, toInputAt: 0)
            try interpreter.copy(styleTensor, toInputAt: 1)

            // 执行推理
            try interpreter.invoke()

            // 获取输出张量
            let outputTensor = try interpreter.output(at: 0)

            // 后处理生成的图像数据
            let outputImage = postprocess(data: outputTensor.data, size: CGSize(width: contentTensorShapeArray[2], height: contentTensorShapeArray[1]))
            if outputImage != nil {
                print("Inference successful.")
            } else {
                print("Inference failed.")
            }
            return outputImage
        } catch {
            print("Error during inference: \(error)")
            return nil
        }
    }

    // MARK: - Tensor Processing

    /// 图片预处理：将图片转换为张量数据
    private func preprocessImage(image: UIImage, tensorShape: [Int]) -> Data {
        let height = tensorShape[1]
        let width = tensorShape[2]

        guard let cgImage = image.cgImage else {
            fatalError("Cannot get CGImage from image.")
        }

        guard let pixelData = cgImage.dataProvider?.data else {
            fatalError("Cannot get pixel data.")
        }

        let rawBytes = CFDataGetBytePtr(pixelData)!
        var floatArray: [Float] = []

        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (y * width + x) * 4
                let r = Float(rawBytes[pixelIndex]) / 255.0
                let g = Float(rawBytes[pixelIndex + 1]) / 255.0
                let b = Float(rawBytes[pixelIndex + 2]) / 255.0
                floatArray.append(r)
                floatArray.append(g)
                floatArray.append(b)
            }
        }

        return Data(buffer: UnsafeBufferPointer(start: floatArray, count: floatArray.count))
    }

    /// 图片后处理：将模型输出张量转换为 UIImage
    private func postprocess(data: Data, size: CGSize) -> UIImage? {
        let floatArray = data.withUnsafeBytes {
            Array(UnsafeBufferPointer<Float>(start: $0, count: data.count / MemoryLayout<Float>.size))
        }

        var byteArray: [UInt8] = []
        for value in floatArray {
            byteArray.append(UInt8(min(max(value * 255.0, 0.0), 255.0)))
        }

        return UIImage.fromByteArray(byteArray, width: Int(size.width), height: Int(size.height))
    }
}

// 扩展 UIImage 以支持从字节数组创建图像
extension UIImage {
    static func fromByteArray(_ byteArray: [UInt8], width: Int, height: Int) -> UIImage? {
        let data = Data(byteArray)
        guard let provider = CGDataProvider(data: data as CFData) else { return nil }
        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 24,
            bytesPerRow: width * 3,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        ) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
