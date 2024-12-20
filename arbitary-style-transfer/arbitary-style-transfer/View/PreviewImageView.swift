import SwiftUI

// 单个风格化结果视图组件
struct StyleResultView: View {
    let index: Int
    let stylizedImage: UIImage
    
    var body: some View {
        VStack {
            Text("风格迁移结果 #\(index + 1)")
                .font(.headline)
            
            Image(uiImage: stylizedImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .cornerRadius(10)
                .padding(.horizontal)
        }
    }
}

// 融合按钮视图组件
struct BlendingButtonView: View {
    let viewModel: StyleTransferViewModel
    let stylizedImages: [UIImage]
    @Binding var path: [NavigationPath]  // 改为数组类型
    
    var body: some View {
        Button("调整风格融合") {
            path.append(.strengthModify)  // 使用 append 添加到导航栈
        }
        .font(.headline)
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(10)
        .padding()
    }
}

// 主预览视图
struct PreviewImageView: View {
    @ObservedObject var viewModel: StyleTransferViewModel
    @Binding var path: [NavigationPath]
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(Array(viewModel.stylizedImages.enumerated()), id: \.offset) { index, image in
                        StyleResultView(
                            index: index,
                            stylizedImage: image
                        )
                    }
                }
                .padding()
            }
            
            Button("调整风格融合") {
                path.append(.strengthModify)
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding()
        }
        .navigationTitle("预览生成图片")
        .navigationBarTitleDisplayMode(.inline)
    }
}
