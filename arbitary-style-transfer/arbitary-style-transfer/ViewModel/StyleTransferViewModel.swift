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

    func selectContentImage(_ image: UIImage) {
        contentImage = image
        originalContentImage = image  // 保存原始图片
    }

    func selectStyleImage(_ image: UIImage) {
        styleImages.append(image)
    }

    // 添加图像插值方法
    func interpolateImages(original: UIImage, stylized: UIImage, strength: Float) -> UIImage? {
        guard let originalCG = original.cgImage,
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
        return UIImage(cgImage: resultImage)
    }

    // 多风格融合方法
    func blendMultipleStyles(original: UIImage, stylizedImages: [UIImage], strengths: [Float]) -> UIImage? {
        guard !stylizedImages.isEmpty,
              stylizedImages.count == strengths.count,
              let originalCG = original.cgImage else { return nil }
        
        let width = originalCG.width
        let height = originalCG.height
        let bytesPerPixel = 4
        let bitsPerComponent = 8
        
        var originalPixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
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
        
        // 计算总强度
        let totalStrength = strengths.reduce(0, +)
        let normalizedStrengths = strengths.map { $0 / totalStrength }
        
        // 初始化结果像素为原始图像
        resultPixels = originalPixels
        
        // 对每个风格化图像进行混合
        for (index, stylizedImage) in stylizedImages.enumerated() {
            guard let stylizedCG = stylizedImage.cgImage else { continue }
            var stylizedPixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
            
            let stylizedContext = CGContext(data: &stylizedPixels,
                                          width: width,
                                          height: height,
                                          bitsPerComponent: bitsPerComponent,
                                          bytesPerRow: width * bytesPerPixel,
                                          space: colorSpace,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            stylizedContext?.draw(stylizedCG, in: CGRect(x: 0, y: 0, width: width, height: height))
            
            // 混合像素
            for i in 0..<width * height * bytesPerPixel {
                let currentValue = Float(resultPixels[i])
                let stylizedValue = Float(stylizedPixels[i])
                resultPixels[i] = UInt8(max(0, min(255, currentValue * (1 - normalizedStrengths[index]) + stylizedValue * normalizedStrengths[index])))
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

        for (index, styleImage) in styleImages.enumerated() {
            if let stylized = model.runInference(contentImage: contentImage, styleImage: styleImage) {
                DispatchQueue.main.async {
                    self.stylizedImages.append(stylized)
                    self.processingProgress = Float(index + 1) / Float(self.styleImages.count)
                }
            }
        }

        DispatchQueue.main.async {
            self.isProcessing = false
            self.processingProgress = 1.0
        }

        return !self.stylizedImages.isEmpty
    }
}
