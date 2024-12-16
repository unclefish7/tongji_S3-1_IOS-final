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

    func selectContentImage(_ image: UIImage) {
        contentImage = image
    }

    func selectStyleImage(_ image: UIImage) {
        styleImages.append(image)
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
