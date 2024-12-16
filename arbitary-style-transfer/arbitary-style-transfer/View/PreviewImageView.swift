import SwiftUI

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
                
                ForEach(0..<stylizedImages.count, id: \.self) { index in
                    VStack {
                        Text("风格迁移结果 #\(index + 1)")
                            .font(.headline)
                        
                        NavigationLink(
                            destination: StrengthModifyView(
                                viewModel: viewModel,
                                originalImage: viewModel.originalContentImage ?? UIImage(),
                                stylizedImage: stylizedImages[index]
                            )
                        ) {
                            Image(uiImage: stylizedImages[index])
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                        
                        Text("点击图片调整强度")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("预览生成图片")
        .navigationBarTitleDisplayMode(.inline)
    }
}
