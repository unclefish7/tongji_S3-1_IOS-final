import Foundation
import TensorFlowLite
import UIKit
import CoreImage

struct StyleTransferResult {
    let stylizedImage: UIImage
    let resizedContentImage: UIImage
    let originalSize: CGSize
}

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

        // 动态获取调整后内容图片的高度和宽度
        let contentHeight = Int(contentImage.size.height)
        let contentWidth = Int(contentImage.size.width)

        // 固定风格图片的高度和宽度为256
        let styleHeight = 256
        let styleWidth = 256

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

    /// 运行模型推理，返回风格迁移后的图片和调整大小后的原始图片
    func runInference(contentImage: UIImage, styleImage: UIImage) -> StyleTransferResult? {
        guard let interpreter = interpreter else {
            fatalError("Interpreter is not initialized.")
        }

        do {
            let originalSize = contentImage.size
            // 调整内容图片大小，使其在800x800像素以内，保持比例
            let resizedContentImage = resizeContentImage(image: contentImage, maxSize: CGSize(width: 800, height: 800))

            // 动态调整输入张量形状
            resizeInputTensor(contentImage: resizedContentImage, styleImage: styleImage)

            // 获取动态调整后的张量形状
            let contentTensorShape = try interpreter.input(at: 0).shape
            let styleTensorShape = try interpreter.input(at: 1).shape

            // 将 Tensor.Shape 转换为 [Int]
            let contentTensorShapeArray = contentTensorShape.dimensions
            let styleTensorShapeArray = styleTensorShape.dimensions

            // 调整风格图片尺寸为256x256
            let resizedStyleImage = resizeImage(image: styleImage, targetSize: CGSize(width: 256, height: 256))

            // 预处理图片
            let contentTensor = preprocessImage(image: resizedContentImage, tensorShape: contentTensorShapeArray)
            let styleTensor = preprocessImage(image: resizedStyleImage, tensorShape: styleTensorShapeArray)

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

            // 修改返回值
            if let outputImage = outputImage {
                return StyleTransferResult(
                    stylizedImage: outputImage,
                    resizedContentImage: resizedContentImage,
                    originalSize: originalSize
                )
            }
            return nil
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
        
        guard let ciImage = CIImage(image: image) else {
            fatalError("Cannot create CIImage from UIImage")
        }
        
        // 创建 RGBA 格式的位图上下文
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent),
              let pixelData = cgImage.dataProvider?.data else {
            fatalError("Failed to create bitmap data")
        }
        
        let rawBytes = CFDataGetBytePtr(pixelData)!
        let bytesPerRow = cgImage.bytesPerRow
        var floatArray: [Float] = []
        
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = y * bytesPerRow + x * 4 // RGBA 格式，每像素4字节
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

    /// 调整内容图片尺寸，使其在特定像素以内，保持比例
    private func resizeContentImage(image: UIImage, maxSize: CGSize) -> UIImage {
        guard let ciImage = CIImage(image: image) else {
            return image
        }
        
        let size = image.size
        if size.width <= maxSize.width && size.height <= maxSize.height {
            return image
        }
        
        let widthRatio = maxSize.width / size.width
        let heightRatio = maxSize.height / size.height
        let scale = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let filter = CIFilter(name: "CILanczosScaleTransform")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(scale, forKey: kCIInputScaleKey)
        filter.setValue(1.0, forKey: kCIInputAspectRatioKey)
        
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        let resizedImage = UIImage(cgImage: cgImage)
        print("Resized content image to: \(resizedImage.size.width)x\(resizedImage.size.height)")
        return resizedImage
    }

    /// 调整图片尺寸，保持比例并填充到指定尺寸
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        guard let ciImage = CIImage(image: image) else {
            return image
        }
        
        // 计算适当的缩放比例以覆盖目标尺寸
        let widthRatio = targetSize.width / image.size.width
        let heightRatio = targetSize.height / image.size.height
        let scale = max(widthRatio, heightRatio) // 使用较大的缩放比例以确保填充
        
        // 使用 Lanczos 缩放
        let scaleFilter = CIFilter(name: "CILanczosScaleTransform")!
        scaleFilter.setValue(ciImage, forKey: kCIInputImageKey)
        scaleFilter.setValue(scale, forKey: kCIInputScaleKey)
        scaleFilter.setValue(1.0, forKey: kCIInputAspectRatioKey)
        
        guard let scaledImage = scaleFilter.outputImage else {
            return image
        }
        
        // 计算裁剪区域使图像居中
        let scaledSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let cropX = (scaledSize.width - targetSize.width) / 2
        let cropY = (scaledSize.height - targetSize.height) / 2
        let cropRect = CGRect(x: cropX, y: cropY, width: targetSize.width, height: targetSize.height)
        
        // 裁剪到目标尺寸
        let croppedImage = scaledImage.cropped(to: cropRect)
        
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let cgImage = context.createCGImage(croppedImage, from: croppedImage.extent) else {
            return image
        }
        
        let resizedImage = UIImage(cgImage: cgImage)
        print("Resized style image to: \(resizedImage.size.width)x\(resizedImage.size.height)")
        return resizedImage
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
