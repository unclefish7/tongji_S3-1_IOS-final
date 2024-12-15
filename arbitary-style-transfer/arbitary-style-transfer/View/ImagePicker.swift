import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageType: String
    @ObservedObject var viewModel: StyleTransferViewModel
    var allowsMultipleSelection: Bool = false

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = allowsMultipleSelection ? 0 : 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                        guard let self = self, let uiImage = image as? UIImage else { return }
                        DispatchQueue.main.async {
                            if self.parent.imageType == "Content" {
                                self.parent.viewModel.selectContentImage(uiImage)
                            } else {
                                self.parent.viewModel.selectStyleImage(uiImage)
                            }
                        }
                    }
                }
            }
        }
    }
}
