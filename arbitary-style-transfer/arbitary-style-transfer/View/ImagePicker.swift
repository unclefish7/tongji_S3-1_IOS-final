import SwiftUI
import UIKit

/// 图片选择器，用于从相册中选择图片
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageType: String
    var viewModel: StyleTransferViewModel

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            guard let image = info[.originalImage] as? UIImage else { return }
            if parent.imageType == "Content" {
                parent.viewModel.selectContentImage(image)
            } else {
                parent.viewModel.selectStyleImage(image)
            }
            picker.dismiss(animated: true)
        }
    }
}
