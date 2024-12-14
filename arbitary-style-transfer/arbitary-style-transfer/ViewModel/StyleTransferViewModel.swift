import Foundation
import UIKit

/// ViewModel 负责管理数据流和业务逻辑
class StyleTransferViewModel: ObservableObject {
    private let model = StyleTransferModel()

    @Published var contentImage: UIImage?
    @Published var styleImage: UIImage?
    @Published var stylizedImage: UIImage?

    func selectContentImage(_ image: UIImage) {
        contentImage = image
    }

    func selectStyleImage(_ image: UIImage) {
        styleImage = image
    }

    func performStyleTransfer() {
        guard let contentImage = contentImage, let styleImage = styleImage else {
            print("Images not selected.")
            return
        }
        stylizedImage = model.runInference(contentImage: contentImage, styleImage: styleImage)
        if stylizedImage != nil {
            print("Style transfer successful.")
        } else {
            print("Style transfer failed.")
        }
    }
}
