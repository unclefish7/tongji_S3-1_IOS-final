import Foundation
import UIKit

/// ViewModel 负责管理数据流和业务逻辑
class StyleTransferViewModel: ObservableObject {
    private let model = StyleTransferModel()

    @Published var contentImage: UIImage?
    @Published var styleImages: [UIImage] = []
    @Published var stylizedImage: UIImage?
    @Published var stylizedImages: [UIImage] = []
    @Published var isProcessing = false
    @Published var processingProgress: Float = 0.0

    // 添加原始内容图片的引用
    @Published var originalContentImage: UIImage?

    // 添加防抖计时器
    private var blendTimer: Timer?
    // 添加缓存
    private var pixelCache: [String: [UInt8]] = [:]

    @Published var blendedImage: UIImage? // 添加这个属性用于实时显示融合结果

    // 添加属性来存储调整大小后的内容图片和原始尺寸
    @Published var resizedContentImage: UIImage?
    var originalImageSize: CGSize?  // 修改访问级别为 internal

    @Published var gradientImage: UIImage?  // 添加这个属性用于显示渐变结果

    @Published var finalImage: UIImage?  // 添加这个属性用于存储最终结果图片

    func selectContentImage(_ image: UIImage) {
        contentImage = image
        originalContentImage = image  // 保存原始图片
    }

    func selectStyleImage(_ image: UIImage) {
        styleImages.append(image)
    }

    // 添加图像插值方法
    func interpolateImages(original: UIImage, stylized: UIImage, strength: Float) -> UIImage? {
        // 使用 resizedContentImage 而不是原始图片
        guard let resizedOriginal = resizedContentImage else {
            return nil
        }

        guard let originalCG = resizedOriginal.cgImage,
              let stylizedCG = stylized.cgImage else { return nil }
        
        let width = originalCG.width
        let height = originalCG.height
        let bytesPerPixel = 4
        let bitsPerComponent = 8
        
        var originalPixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        var stylizedPixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        var resultPixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &originalPixels,
                              width: width,
                              height: height,
                              bitsPerComponent: bitsPerComponent,
                              bytesPerRow: width * bytesPerPixel,
                              space: colorSpace,
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        context?.draw(originalCG, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let stylizedContext = CGContext(data: &stylizedPixels,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: width * bytesPerPixel,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        stylizedContext?.draw(stylizedCG, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // 执行像素插值
        for i in 0..<width * height * bytesPerPixel {
            let originalValue = Float(originalPixels[i])
            let stylizedValue = Float(stylizedPixels[i])
            let interpolatedValue = originalValue * (1 - strength) + stylizedValue * strength
            resultPixels[i] = UInt8(max(0, min(255, interpolatedValue)))
        }
        
        let resultContext = CGContext(data: &resultPixels,
                                    width: width,
                                    height: height,
                                    bitsPerComponent: bitsPerComponent,
                                    bytesPerRow: width * bytesPerPixel,
                                    space: colorSpace,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let resultImage = resultContext?.makeImage() else { return nil }

        // 如果是最终结果，需要调整回原始大小
        if let originalSize = originalImageSize {
            return resizeImage(image: UIImage(cgImage: resultImage), targetSize: originalSize)
        }

        return UIImage(cgImage: resultImage)
    }

    // 优化后的多风格融合方法
    func blendMultipleStyles(original: UIImage, stylizedImages: [UIImage], strengths: [Float], debounceInterval: TimeInterval = 0.1) {
        // 取消之前的定时器
        blendTimer?.invalidate()
        
        // 创建新的定时器
        blendTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
            self?.performBlending(original: original, stylizedImages: stylizedImages, strengths: strengths)
        }
    }

    // 取消当前的融合操作
    func cancelBlending() {
        blendTimer?.invalidate()
    }
    
    private func performBlending(original: UIImage, stylizedImages: [UIImage], strengths: [Float]) {
        guard !stylizedImages.isEmpty,
              stylizedImages.count == strengths.count,
              let resizedOriginal = resizedContentImage, // 使用调整大小后的图片
              let originalCG = resizedOriginal.cgImage else { return }
        
        let width = originalCG.width
        let height = originalCG.height
        let bytesPerPixel = 4
        let pixelsCount = width * height * bytesPerPixel
        
        // 获取或创建缓存的像素数据
        func getPixelData(for image: UIImage, key: String) -> [UInt8] {
            if let cached = pixelCache[key] {
                return cached
            }
            
            var pixels = [UInt8](repeating: 0, count: pixelsCount)
            if let cgImage = image.cgImage {
                let context = CGContext(data: &pixels,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: width * bytesPerPixel,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
                context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            }
            pixelCache[key] = pixels
            return pixels
        }
        
        // 获取调整大小后的原始图像和风格化图像的像素数据
        let originalPixels = getPixelData(for: resizedOriginal, key: "original")
        let stylizedPixelsArray = stylizedImages.enumerated().map { index, image in
            getPixelData(for: image, key: "style\(index)")
        }
        
        // 计算总强度并标准化
        let totalStrength = strengths.reduce(0, +)
        let normalizedStrengths = totalStrength > 0 ? strengths.map { $0 / totalStrength } : strengths
        
        // 如果所有强度都为 0，则直接返回原始图像
        if totalStrength == 0 {
            DispatchQueue.main.async {
                self.blendedImage = self.originalContentImage
            }
            return
        }
        
        // 第一次融合：基于每个风格自己的强度和原始图像进行融合
        var intermediateImages = [[UInt8]](repeating: [UInt8](repeating: 0, count: pixelsCount), count: stylizedImages.count)
        DispatchQueue.concurrentPerform(iterations: stylizedImages.count) { index in
            for i in 0..<pixelsCount {
                let originalValue = Float(originalPixels[i])
                let stylizedValue = Float(stylizedPixelsArray[index][i])
                let blendedValue = originalValue * (1 - strengths[index]) + stylizedValue * strengths[index]
                intermediateImages[index][i] = UInt8(max(0, min(255, blendedValue)))
            }
        }
        
        // 第二次融合：基于每个风格的强度比例，对上述融合后的多个图像进行二次融合
        var resultPixels = [UInt8](repeating: 0, count: pixelsCount)
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            DispatchQueue.concurrentPerform(iterations: pixelsCount) { i in
                var value: Float = 0.0
                for (index, intermediatePixels) in intermediateImages.enumerated() {
                    value += Float(intermediatePixels[i]) * normalizedStrengths[index]
                }
                resultPixels[i] = UInt8(max(0, min(255, value)))
            }
            
            // 创建结果图像
            let resultContext = CGContext(data: &resultPixels,
                                        width: width,
                                        height: height,
                                        bitsPerComponent: 8,
                                        bytesPerRow: width * bytesPerPixel,
                                        space: CGColorSpaceCreateDeviceRGB(),
                                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            
            if let resultImage = resultContext?.makeImage().flatMap({ UIImage(cgImage: $0) }) {
                DispatchQueue.main.async {
                    self?.blendedImage = resultImage  // 这会触发 StrengthModifyView 中的 onChange
                }
            }
        }
    }
    
    // 清理缓存
    func clearPixelCache(clearBlendedImage: Bool = true) {
        pixelCache.removeAll()
        if clearBlendedImage {
            blendedImage = nil
        }
    }

    func performStyleTransfer() async -> Bool {
        guard let contentImage = contentImage, !styleImages.isEmpty else {
            print("Images not selected.")
            return false
        }

        DispatchQueue.main.async {
            self.isProcessing = true
            self.stylizedImages.removeAll()
            self.processingProgress = 0.0
        }

        let dispatchGroup = DispatchGroup()

        for (index, styleImage) in styleImages.enumerated() {
            dispatchGroup.enter()
            if let result = model.runInference(contentImage: contentImage, styleImage: styleImage) {
                // 保存第一次处理后的调整大小的内容图片
                if index == 0 {
                    DispatchQueue.main.async {
                        self.resizedContentImage = result.resizedContentImage
                        self.originalImageSize = result.originalSize
                    }
                }
                
                DispatchQueue.main.async {
                    self.stylizedImages.append(result.stylizedImage)
                    self.processingProgress = Float(index + 1) / Float(self.styleImages.count)
                    print("Processed style image \(index + 1) of \(self.styleImages.count)")
                    dispatchGroup.leave()
                }
            } else {
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            self.isProcessing = false
            self.processingProgress = 1.0
            print("Style transfer completed. Total stylized images: \(self.stylizedImages.count)")
        }

        // 等待所有异步操作完成
        dispatchGroup.wait()

        return !self.stylizedImages.isEmpty
    }

    // 添加辅助方法来调整图片大小
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let rect = CGRect(origin: .zero, size: targetSize)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? image
    }

    // 添加区域渐变方法
    func applyGradient(to blendedImage: UIImage, horizontal: Bool, vertical: Bool, radial: Bool, leftHorizontal: Float, rightHorizontal: Float, topVertical: Float, bottomVertical: Float, centerRadial: Float, edgeRadial: Float) -> UIImage? {
        guard let originalImage = originalContentImage,
              let originalCG = originalImage.cgImage,
              let blendedCG = blendedImage.cgImage else { return nil }
        
        let width = originalCG.width
        let height = originalCG.height
        let bytesPerPixel = 4
        let bitsPerComponent = 8
        
        var originalPixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        var blendedPixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        var resultPixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let originalContext = CGContext(data: &originalPixels,
                                        width: width,
                                        height: height,
                                        bitsPerComponent: bitsPerComponent,
                                        bytesPerRow: width * bytesPerPixel,
                                        space: colorSpace,
                                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        originalContext?.draw(originalCG, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let blendedContext = CGContext(data: &blendedPixels,
                                       width: width,
                                       height: height,
                                       bitsPerComponent: bitsPerComponent,
                                       bytesPerRow: width * bytesPerPixel,
                                       space: colorSpace,
                                       bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        blendedContext?.draw(blendedCG, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        for y in 0..<height {
            for x in 0..<width {
                let index = (y * width + x) * bytesPerPixel
                var gradientFactor: Float = 1.0
                
                if horizontal {
                    let horizontalGradient = leftHorizontal + (rightHorizontal - leftHorizontal) * Float(x) / Float(width)
                    gradientFactor *= horizontalGradient
                }
                if vertical {
                    let verticalGradient = topVertical + (bottomVertical - topVertical) * Float(y) / Float(height)
                    gradientFactor *= verticalGradient
                }
                if radial {
                    let centerX = Float(width) / 2.0
                    let centerY = Float(height) / 2.0
                    let distance = sqrt(pow(Float(x) - centerX, 2) + pow(Float(y) - centerY, 2))
                    let maxDistance = sqrt(pow(centerX, 2) + pow(centerY, 2))
                    let radialGradient = centerRadial + (edgeRadial - centerRadial) * distance / maxDistance
                    gradientFactor *= radialGradient
                }
                
                for i in 0..<3 {
                    let originalValue = Float(originalPixels[index + i])
                    let blendedValue = Float(blendedPixels[index + i])
                    let interpolatedValue = originalValue * (1 - gradientFactor) + blendedValue * gradientFactor
                    resultPixels[index + i] = UInt8(max(0, min(255, interpolatedValue)))
                }
                resultPixels[index + 3] = originalPixels[index + 3]  // 保持 alpha 通道不变
            }
        }
        
        let resultContext = CGContext(data: &resultPixels,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: width * bytesPerPixel,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let resultImage = resultContext?.makeImage() else { return nil }
        return UIImage(cgImage: resultImage)
    }
}
