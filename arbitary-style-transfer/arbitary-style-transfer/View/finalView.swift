import SwiftUI
import Photos

struct FinalView: View {
    @ObservedObject var viewModel: StyleTransferViewModel
    @Binding var path: [NavigationPath]
    @State private var isZoomed = false
    @State private var saveMessage: String?

    var body: some View {
        VStack {
            if let image = viewModel.finalImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: isZoomed ? .infinity : 300)
                    .padding()
                    .onTapGesture {
                        withAnimation {
                            isZoomed.toggle()
                        }
                    }
            } else {
                Text("没有可显示的图片")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .padding()
            }

            VStack(spacing: 16) {
                Button("保存图片") {
                    PHPhotoLibrary.requestAuthorization { status in
                        if status == .authorized {
                            if let image = viewModel.finalImage {
                                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                                DispatchQueue.main.async {
                                    saveMessage = "图片已保存"
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                saveMessage = "用户未授权访问照片库"
                            }
                        }
                    }
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("返回首页") {
                    path.removeAll()
                    viewModel.reset()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)

            if let message = saveMessage {
                Text(message)
                    .foregroundColor(.blue)
                    .padding()
            }
        }
        .navigationTitle("最终结果")
        .navigationBarTitleDisplayMode(.inline)
    }
}
