import Foundation
import UIKit
import CoreImage

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

    private let ciContext = CIContext()

    func selectContentImage(_ image: UIImage) {
        contentImage = image
        originalContentImage = image  // 保存原始图片
    }

    func selectStyleImage(_ image: UIImage) {
        styleImages.append(image)
    }

    // 重构的多风格融合方法
    func blendMultipleStyles(original: UIImage, stylizedImages: [UIImage], strengths: [Float], debounceInterval: TimeInterval = 0.1) {
        blendTimer?.invalidate()
        
        blendTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
            self?.performCIBlending(original: original, stylizedImages: stylizedImages, strengths: strengths)
        }
    }

    // 取消当前的融合操作
    func cancelBlending() {
        blendTimer?.invalidate()
    }
    
    private func performCIBlending(original: UIImage, stylizedImages: [UIImage], strengths: [Float]) {
        guard !stylizedImages.isEmpty,
              stylizedImages.count == strengths.count,
              let originalCIImage = CIImage(image: original) else { return }
        
        // 过滤掉强度为 0 的风格
        let validStyles = zip(stylizedImages, strengths)
            .enumerated()
            .filter { _, pair in pair.1 > 0 }
            .map { index, pair in (index, pair.0, pair.1) }
        
        // 如果没有有效的风格（所有强度都为 0），返回原始图像
        if validStyles.isEmpty {
            DispatchQueue.main.async {
                self.blendedImage = self.originalContentImage
            }
            return
        }
        
        // 将有效的风格化图像转换为 CIImage
        let validCIImages = validStyles.compactMap { _, image, _ in CIImage(image: image) }
        guard validCIImages.count == validStyles.count else { return }
        
        // 第一阶段：每个有效的风格图像与原始图像按各自强度融合
        let intermediateResults = zip(validCIImages, validStyles).compactMap { (stylizedImage, styleInfo) -> CIImage? in
            guard let blendFilter = CIFilter(name: "CIBlendWithMask") else { return nil }
            
            let strength = styleInfo.2 // 获取风格强度
            let maskColor = CIColor(red: CGFloat(strength), green: CGFloat(strength), blue: CGFloat(strength))
            let maskImage = CIImage(color: maskColor).cropped(to: originalCIImage.extent)
            
            blendFilter.setValue(originalCIImage, forKey: kCIInputBackgroundImageKey)
            blendFilter.setValue(stylizedImage, forKey: kCIInputImageKey)
            blendFilter.setValue(maskImage, forKey: kCIInputMaskImageKey)
            
            return blendFilter.outputImage
        }
        
        guard !intermediateResults.isEmpty else { return }
        
        // 计算有效风格的标准化强度
        let totalValidStrength = validStyles.map { $0.2 }.reduce(0, +)
        let normalizedStrengths = validStyles.map { $0.2 / totalValidStrength }
        
        // 第二阶段：基于有效风格的强度比例融合
        var currentResult = intermediateResults[0]
        
        for i in 1..<intermediateResults.count {
            guard let blendFilter = CIFilter(name: "CIBlendWithMask") else { continue }
            
            let relativeStrength = normalizedStrengths[i] / (normalizedStrengths[i-1] + normalizedStrengths[i])
            let maskColor = CIColor(red: CGFloat(relativeStrength), green: CGFloat(relativeStrength), blue: CGFloat(relativeStrength))
            let maskImage = CIImage(color: maskColor).cropped(to: currentResult.extent)
            
            blendFilter.setValue(currentResult, forKey: kCIInputBackgroundImageKey)
            blendFilter.setValue(intermediateResults[i], forKey: kCIInputImageKey)
            blendFilter.setValue(maskImage, forKey: kCIInputMaskImageKey)
            
            if let output = blendFilter.outputImage {
                currentResult = output
            }
        }
        
        // 渲染最终结果
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            if let cgImage = self?.ciContext.createCGImage(currentResult, from: currentResult.extent) {
                let finalImage = UIImage(cgImage: cgImage)
                DispatchQueue.main.async {
                    self?.blendedImage = finalImage
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
        guard let cgImage = image.cgImage,
              let scaledFilter = CIFilter(name: "CILanczosScaleTransform") else {
            return image
        }
        
        let ciImage = CIImage(cgImage: cgImage)
        
        // 计算缩放比例
        let scale = min(
            targetSize.width / ciImage.extent.width,
            targetSize.height / ciImage.extent.height
        )
        
        // 设置 Lanczos 缩放参数
        scaledFilter.setValue(ciImage, forKey: kCIInputImageKey)
        scaledFilter.setValue(scale, forKey: kCIInputScaleKey)
        scaledFilter.setValue(1.0, forKey: kCIInputAspectRatioKey)
        
        guard let outputImage = scaledFilter.outputImage else { return image }
        
        // 应用锐化滤镜
        guard let sharpenFilter = CIFilter(name: "CIUnsharpMask") else { return image }
        sharpenFilter.setValue(outputImage, forKey: kCIInputImageKey)
        sharpenFilter.setValue(0.5, forKey: kCIInputRadiusKey)        // 锐化半径
        sharpenFilter.setValue(1.0, forKey: kCIInputIntensityKey)     // 锐化强度
        
        guard let finalOutput = sharpenFilter.outputImage,
              let cgFinal = ciContext.createCGImage(finalOutput, from: finalOutput.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgFinal)
    }

    // 添加区域渐变方法
    func applyGradient(to blendedImage: UIImage, horizontal: Bool, vertical: Bool, radial: Bool, leftHorizontal: Float, rightHorizontal: Float, topVertical: Float, bottomVertical: Float, centerRadial: Float, edgeRadial: Float) -> UIImage? {
        guard let originalImage = resizedContentImage,
              let ciOriginal = CIImage(image: originalImage),
              let ciBlended = CIImage(image: blendedImage) else { return nil }
        
        // 创建一个基础遮罩
        var maskImage = CIImage(color: CIColor(red: 1, green: 1, blue: 1))
            .cropped(to: ciOriginal.extent)
        
        var hasGradient = false
        
        if (horizontal) {
            hasGradient = true
            guard let horizontalGradient = CIFilter(name: "CILinearGradient") else { return nil }
            let startVector = CIVector(x: ciOriginal.extent.minX, y: ciOriginal.extent.midY)
            let endVector = CIVector(x: ciOriginal.extent.maxX, y: ciOriginal.extent.midY)
            horizontalGradient.setValue(startVector, forKey: "inputPoint0")
            horizontalGradient.setValue(endVector, forKey: "inputPoint1")
            horizontalGradient.setValue(CIColor(red: CGFloat(leftHorizontal), green: CGFloat(leftHorizontal), blue: CGFloat(leftHorizontal)), forKey: "inputColor0")
            horizontalGradient.setValue(CIColor(red: CGFloat(rightHorizontal), green: CGFloat(rightHorizontal), blue: CGFloat(rightHorizontal)), forKey: "inputColor1")
            
            if let horizontalMask = horizontalGradient.outputImage {
                maskImage = horizontalMask
            }
        }
        
        if (vertical) {
            hasGradient = true
            guard let verticalGradient = CIFilter(name: "CILinearGradient") else { return nil }
            let startVector = CIVector(x: ciOriginal.extent.midX, y: ciOriginal.extent.maxY)  // 交换起点终点
            let endVector = CIVector(x: ciOriginal.extent.midX, y: ciOriginal.extent.minY)
            verticalGradient.setValue(startVector, forKey: "inputPoint0")
            verticalGradient.setValue(endVector, forKey: "inputPoint1")
            verticalGradient.setValue(CIColor(red: CGFloat(topVertical), green: CGFloat(topVertical), blue: CGFloat(topVertical)), forKey: "inputColor0")
            verticalGradient.setValue(CIColor(red: CGFloat(bottomVertical), green: CGFloat(bottomVertical), blue: CGFloat(bottomVertical)), forKey: "inputColor1")
            
            if let verticalMask = verticalGradient.outputImage {
                if (horizontal) {
                    // 如果已经有水平渐变，则使用乘法混合
                    guard let multiply = CIFilter(name: "CIMultiplyCompositing") else { return nil }
                    multiply.setValue(maskImage, forKey: kCIInputBackgroundImageKey)
                    multiply.setValue(verticalMask, forKey: kCIInputImageKey)
                    if let multiplied = multiply.outputImage {
                        maskImage = multiplied
                    }
                } else {
                    maskImage = verticalMask
                }
            }
        }
        
        if (radial) {
            hasGradient = true
            guard let radialGradient = CIFilter(name: "CIGaussianGradient") else { return nil }
            let center = CIVector(x: ciOriginal.extent.midX, y: ciOriginal.extent.midY)
            let radius = Float(max(ciOriginal.extent.width, ciOriginal.extent.height)) * 0.7
            
            radialGradient.setValue(center, forKey: "inputCenter")
            radialGradient.setValue(radius, forKey: "inputRadius")
            // 修正中心和边缘的颜色设置顺序
            radialGradient.setValue(CIColor(red: CGFloat(centerRadial), green: CGFloat(centerRadial), blue: CGFloat(centerRadial)), forKey: "inputColor0")
            radialGradient.setValue(CIColor(red: CGFloat(edgeRadial), green: CGFloat(edgeRadial), blue: CGFloat(edgeRadial)), forKey: "inputColor1")
            
            if let radialMask = radialGradient.outputImage?.cropped(to: ciOriginal.extent) {
                if (horizontal || vertical) {
                    // 如果已经有其他渐变，则使用乘法混合
                    guard let multiply = CIFilter(name: "CIMultiplyCompositing") else { return nil }
                    multiply.setValue(maskImage, forKey: kCIInputBackgroundImageKey)
                    multiply.setValue(radialMask, forKey: kCIInputImageKey)
                    if let multiplied = multiply.outputImage {
                        maskImage = multiplied
                    }
                } else {
                    maskImage = radialMask
                }
            }
        }
        
        // 如果没有启用任何渐变，返回原始的风格迁移图像
        if (!hasGradient) {
            return blendedImage
        }
        
        // 使用遮罩混合原始图像和风格化图像
        guard let blendFilter = CIFilter(name: "CIBlendWithMask") else { return nil }
        blendFilter.setValue(ciOriginal, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(ciBlended, forKey: kCIInputImageKey)
        blendFilter.setValue(maskImage, forKey: kCIInputMaskImageKey)
        
        guard let outputImage = blendFilter.outputImage else { return nil }
        
        // 渲染最终结果
        if let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return nil
    }
    
    func reset() {
        // 重置所有状态
        contentImage = nil
        styleImages.removeAll()
        stylizedImage = nil
        stylizedImages.removeAll()
        originalContentImage = nil
        blendedImage = nil
        resizedContentImage = nil
        gradientImage = nil
        finalImage = nil
        originalImageSize = nil
        clearPixelCache()
    }
}
