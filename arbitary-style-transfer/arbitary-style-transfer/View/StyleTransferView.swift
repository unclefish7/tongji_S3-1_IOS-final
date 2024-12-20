import SwiftUI

enum NavigationPath {
    case chooseImage
    case preview
    case strengthModify
    case final
    case regionalGradient  // 添加新的导航路径
}

struct StyleTransferView: View {
    @StateObject private var viewModel = StyleTransferViewModel()
    @State private var path = [NavigationPath]()  // 改为数组类型
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    Text("艺术风格迁移")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding()
                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 3)
                        .multilineTextAlignment(.center)

                    Button {
                        path.append(.chooseImage)
                    } label: {
                        HStack {
                            Image(systemName: "photo.fill")
                                .font(.title2)
                            Text("开始创作")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .frame(minWidth: 200)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(color: .gray.opacity(0.4), radius: 6, x: 0, y: 4)
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .multilineTextAlignment(.center)
            }
            .navigationDestination(for: NavigationPath.self) { path in
                switch path {
                case .chooseImage:
                    ChooseImageView(viewModel: viewModel, path: $path)
                case .preview:
                    PreviewImageView(viewModel: viewModel, path: $path)  // 直接传递 viewModel
                case .strengthModify:
                    StrengthModifyView(viewModel: viewModel, path: $path)  // 直接传递 viewModel
                case .final:
                    FinalView(viewModel: viewModel, path: $path)  // 添加新的视图
                case .regionalGradient:
                    RegionalGradientView(viewModel: viewModel, path: $path)  // 添加新的视图
                }
            }
        }
    }
}

// 添加按钮动画效果
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
