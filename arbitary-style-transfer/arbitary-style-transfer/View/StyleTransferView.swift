import SwiftUI

struct StyleTransferView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("任意风格迁移")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding()

                NavigationLink(destination: ChooseImageView()) {
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
        }
    }
}
