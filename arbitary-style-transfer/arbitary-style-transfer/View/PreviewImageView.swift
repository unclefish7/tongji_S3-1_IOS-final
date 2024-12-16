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
    
    var body: some View {
        NavigationLink(
            destination: StrengthModifyView(
                viewModel: viewModel,
                originalImage: viewModel.originalContentImage ?? UIImage(),
                stylizedImages: stylizedImages
            )
        ) {
            Text("调整风格融合")
                .font(.headline)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding()
    }
}

// 主预览视图
struct PreviewImageView: View {
    @ObservedObject var viewModel: StyleTransferViewModel
    let stylizedImages: [UIImage]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("生成结果预览")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                ForEach(Array(stylizedImages.enumerated()), id: \.offset) { index, image in
                    StyleResultView(
                        index: index,
                        stylizedImage: image
                    )
                }
                
                BlendingButtonView(
                    viewModel: viewModel,
                    stylizedImages: stylizedImages
                )
            }
            .padding()
        }
        .navigationTitle("预览生成图片")
        .navigationBarTitleDisplayMode(.inline)
    }
}
