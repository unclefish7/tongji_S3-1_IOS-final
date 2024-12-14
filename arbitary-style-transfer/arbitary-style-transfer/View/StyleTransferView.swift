import SwiftUI

/// 主界面，显示内容图片、风格图片和结果图片
struct StyleTransferView: View {
    @StateObject private var viewModel = StyleTransferViewModel()
    @State private var showingImagePicker = false
    @State private var imageType = "Content"

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack {
                    Text("Content Image")
                    Image(uiImage: viewModel.contentImage ?? UIImage())
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .background(Color.gray)
                }
                VStack {
                    Text("Style Image")
                    Image(uiImage: viewModel.styleImage ?? UIImage())
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .background(Color.gray)
                }
            }

            Button("Select Content Image") {
                imageType = "Content"
                showingImagePicker = true
            }

            Button("Select Style Image") {
                imageType = "Style"
                showingImagePicker = true
            }

            Button("Run Style Transfer") {
                viewModel.performStyleTransfer()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            if let resultImage = viewModel.stylizedImage {
                Text("Stylized Image")
                Image(uiImage: resultImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(imageType: $imageType, viewModel: viewModel)
        }
        .padding()
    }
}
