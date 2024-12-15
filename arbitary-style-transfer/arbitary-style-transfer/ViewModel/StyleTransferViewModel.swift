import Foundation
import UIKit

/// ViewModel 负责管理数据流和业务逻辑
class StyleTransferViewModel: ObservableObject {
    private let model = StyleTransferModel()

    @Published var contentImage: UIImage?
    @Published var styleImages: [UIImage] = []
    @Published var stylizedImage: UIImage?

    func selectContentImage(_ image: UIImage) {
        contentImage = image
    }

    func selectStyleImage(_ image: UIImage) {
        styleImages.append(image)
    }

    func performStyleTransfer() {
        guard let contentImage = contentImage, !styleImages.isEmpty else {
            print("Images not selected.")
            return
        }
        // 这里只使用第一张风格图片进行风格迁移，后续可以扩展为多风格融合
        stylizedImage = model.runInference(contentImage: contentImage, styleImage: styleImages[0])
        if stylizedImage != nil {
            print("Style transfer successful.")
        } else {
            print("Style transfer failed.")
        }
    }
}
