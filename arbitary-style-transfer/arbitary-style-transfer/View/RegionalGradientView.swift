//
//  RegionalGradientView.swift
//  arbitary-style-transfer
//
//  Created by 贾文超 on 2024/12/16.
//

import SwiftUI

enum HorizontalPosition: String, CaseIterable, Identifiable {
    case left, right
    var id: String { self.rawValue }
}

enum VerticalPosition: String, CaseIterable, Identifiable {
    case top, bottom
    var id: String { self.rawValue }
}

enum RadialPosition: String, CaseIterable, Identifiable {
    case center, edge
    var id: String { self.rawValue }
}

struct RegionalGradientView: View {
    @ObservedObject var viewModel: StyleTransferViewModel
    @Binding var path: [NavigationPath]
    @State private var horizontalGradient = false
    @State private var verticalGradient = false
    @State private var radialGradient = false
    @State private var leftHorizontalGradient: Float = 0.0  // 添加左侧横向渐变值
    @State private var rightHorizontalGradient: Float = 1.0  // 添加右侧横向渐变值
    @State private var topVerticalGradient: Float = 0.0  // 添加顶部纵向渐变值
    @State private var bottomVerticalGradient: Float = 1.0  // 添加底部纵向渐变值
    @State private var centerRadialGradient: Float = 0.0  // 添加中心径向渐变值
    @State private var edgeRadialGradient: Float = 1.0  // 添加边缘径向渐变值

    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    if let image = viewModel.blendedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 300)  // 添加最大高度
                            .padding()
                    } else {
                        Text("没有可显示的图片")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, maxHeight: 300)  // 添加占位符高度
                            .padding()
                    }
                    
                    Toggle("横向渐变", isOn: $horizontalGradient)
                    if horizontalGradient {
                        Text("左边界")
                        Slider(value: $leftHorizontalGradient, in: 0...1)  // 绑定左侧横向渐变值
                        Text("右边界")
                        Slider(value: $rightHorizontalGradient, in: 0...1)  // 绑定右侧横向渐变值
                    }
                    
                    Toggle("纵向渐变", isOn: $verticalGradient)
                    if verticalGradient {
                        Text("上边界")
                        Slider(value: $topVerticalGradient, in: 0...1)  // 绑定顶部纵向渐变值
                        Text("下边界")
                        Slider(value: $bottomVerticalGradient, in: 0...1)  // 绑定底部纵向渐变值
                    }
                    
                    Toggle("径向渐变", isOn: $radialGradient)
                    if radialGradient {
                        Text("中心")
                        Slider(value: $centerRadialGradient, in: 0...1)  // 绑定中心径向渐变值
                        Text("边缘")
                        Slider(value: $edgeRadialGradient, in: 0...1)  // 绑定边缘径向渐变值
                    }
                    
                    Button("应用渐变") {
                        if let image = viewModel.blendedImage {
                            print("Applying gradient to blendedImage")
                            viewModel.gradientImage = viewModel.applyGradient(to: image, horizontal: horizontalGradient, vertical: verticalGradient, radial: radialGradient, leftHorizontal: leftHorizontalGradient, rightHorizontal: rightHorizontalGradient, topVertical: topVerticalGradient, bottomVertical: bottomVerticalGradient, centerRadial: centerRadialGradient, edgeRadial: edgeRadialGradient)
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    if let gradientImage = viewModel.gradientImage {
                        Image(uiImage: gradientImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 300)  // 添加最大高度
                            .padding()
                    } else {
                        Text("没有可显示的渐变图片")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, maxHeight: 300)  // 添加占位符高度
                            .padding()
                    }
                }
                .padding()
            }
            
            Button("完成") {
                // 完成按钮的操作
                print("完成按钮被点击")
                if let gradientImage = viewModel.gradientImage {
                    viewModel.finalImage = viewModel.resizeImage(image: gradientImage, targetSize: viewModel.originalImageSize ?? gradientImage.size)
                    path.append(.final)  // 导航到 finalView
                }
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .navigationTitle("区域渐变")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("RegionalGradientView appeared")
            if viewModel.blendedImage == nil {
                print("blendedImage is nil, setting it to originalContentImage")
                viewModel.blendedImage = viewModel.originalContentImage
            } else {
                print("blendedImage is already set")
            }
        }
        .onChange(of: viewModel.blendedImage) { newValue in
            print("blendedImage changed: \(String(describing: newValue))")
        }
        .onChange(of: viewModel.gradientImage) { newValue in
            print("gradientImage changed: \(String(describing: newValue))")
        }
    }
}

