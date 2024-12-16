import SwiftUI
import Photos

struct FinalView: View {
    @ObservedObject var viewModel: StyleTransferViewModel
    @Binding var path: [NavigationPath]
    @State private var isZoomed = false  // 添加状态变量用于放大预览
    @State private var saveMessage: String?  // 添加状态变量用于保存信息

    var body: some View {
        VStack {
            if let image = viewModel.finalImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: isZoomed ? .infinity : 300)  // 根据状态变量调整大小
                    .padding()
                    .onTapGesture {
                        withAnimation {
                            isZoomed.toggle()  // 切换放大预览状态
                        }
                    }
            } else {
                Text("没有可显示的图片")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .padding()
            }

            Button("保存图片") {
                // 请求访问权限并保存图片
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
