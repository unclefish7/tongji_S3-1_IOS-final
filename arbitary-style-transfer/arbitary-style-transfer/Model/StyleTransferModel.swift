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

        // 调整内容图片大小，使其在1000x1000像素以内，保持比例
        let resizedContentImage = resizeContentImage(image: contentImage, maxSize: CGSize(width: 1000, height: 1000))

        // 动态获取调整后内容图片的高度和宽度
        let contentHeight = Int(resizedContentImage.size.height)
        let contentWidth = Int(resizedContentImage.size.width)

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

    /// 运行模型推理，返回风格迁移后的图片
    func runInference(contentImage: UIImage, styleImage: UIImage) -> UIImage? {
        guard let interpreter = interpreter else {
            fatalError("Interpreter is not initialized.")
        }

        do {
            // 调整内容图片大小，使其在1000x1000像素以内，保持比例
            let resizedContentImage = resizeContentImage(image: contentImage, maxSize: CGSize(width: 1000, height: 1000))

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

            // 将 outputImage 缩放回原来输入时的大小
            let scaledOutputImage = resizeImage(image: outputImage!, targetSize: contentImage.size)
            return scaledOutputImage
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

        print("Preprocessing image with target size: \(width)x\(height)")

        guard let cgImage = image.cgImage else {
            fatalError("Cannot get CGImage from image.")
        }

        guard let pixelData = cgImage.dataProvider?.data else {
            fatalError("Cannot get pixel data.")
        }

        let rawBytes = CFDataGetBytePtr(pixelData)!
        let bytesPerPixel = cgImage.bitsPerPixel / cgImage.bitsPerComponent
        let expectedSize = height * width * bytesPerPixel
        let actualSize = CFDataGetLength(pixelData)

        print("Expected pixel data size: \(expectedSize), actual size: \(actualSize)")
        print("Bytes per pixel: \(bytesPerPixel)")

        guard actualSize >= expectedSize else {
            fatalError("Pixel data size is smaller than expected.")
        }

        var floatArray: [Float] = []

        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (y * width + x) * bytesPerPixel
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

    /// 调整内容图片尺寸，使其在1000x1000像素以内，保持比例
    private func resizeContentImage(image: UIImage, maxSize: CGSize) -> UIImage {
        let size = image.size
        
        // 如果图片尺寸已经在限制范围内，直接返回原图
        if size.width <= maxSize.width && size.height <= maxSize.height {
            print("Content image size already within limits: \(size.width)x\(size.height)")
            return image
        }

        let widthRatio  = maxSize.width  / size.width
        let heightRatio = maxSize.height / size.height
        let scaleFactor = min(widthRatio, heightRatio)

        let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)

        let rect = CGRect(origin: .zero, size: newSize)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let resizedImage = newImage else {
            fatalError("Failed to resize content image.")
        }

        print("Resized content image to: \(resizedImage.size.width)x\(resizedImage.size.height)")

        return resizedImage
    }

    /// 调整图片尺寸
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        // 直接将图像调整为目标尺寸
        let rect = CGRect(origin: .zero, size: targetSize)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let resizedImage = newImage else {
            fatalError("Failed to resize image.")
        }

        print("Resized image to: \(resizedImage.size.width)x\(resizedImage.size.height)")

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
