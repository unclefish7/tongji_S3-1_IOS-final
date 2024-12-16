import SwiftUI

enum NavigationPath {
    case chooseImage
    case preview
    case strengthModify
    case final
}

struct StyleTransferView: View {
    @StateObject private var viewModel = StyleTransferViewModel()
    @State private var path = [NavigationPath]()  // 改为数组类型
    
    var body: some View {
        NavigationStack(path: $path) {  // 使用 path 绑定
            VStack(spacing: 20) {
                Text("任意风格迁移")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding()

                Button {
                    path.append(.chooseImage)  // 添加到导航路径
                } label: {
                    Text("第一步：上传图片")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }

                Spacer()
            }
            .padding()
            .navigationDestination(for: NavigationPath.self) { path in
                switch path {
                case .chooseImage:
                    ChooseImageView(viewModel: viewModel, path: $path)
                case .preview:
                    PreviewImageView(viewModel: viewModel, stylizedImages: viewModel.stylizedImages, path: $path)
                case .strengthModify:
                    StrengthModifyView(viewModel: viewModel, 
                                     originalImage: viewModel.originalContentImage ?? UIImage(), 
                                     stylizedImages: viewModel.stylizedImages,
                                       path: $path)
                case .final:
                    // 预留给最终界面
                    Text("最终结果页面")
                }
            }
        }
    }
}
