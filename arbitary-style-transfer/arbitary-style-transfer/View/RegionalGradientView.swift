//
//  RegionalGradientView.swift
//  arbitary-style-transfer
//
//  Created by 贾文超 on 2024/12/16.
//

import SwiftUI

struct RegionalGradientView: View {
    @ObservedObject var viewModel: StyleTransferViewModel
    @Binding var path: [NavigationPath]
    @State private var horizontalGradient = false
    @State private var verticalGradient = false
    @State private var radialGradient = false
    @State private var minGradient: Float = 0.0  // 添加最小渐变值
    @State private var maxGradient: Float = 1.0  // 添加最大渐变值

    var body: some View {
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
            Toggle("纵向渐变", isOn: $verticalGradient)
            Toggle("径向渐变", isOn: $radialGradient)
            
            Text("渐变系数范围")
            Slider(value: $minGradient, in: 0...1)  // 绑定最小渐变值
            Slider(value: $maxGradient, in: 0...1)  // 绑定最大渐变值
            
            Button("应用渐变") {
                if let image = viewModel.blendedImage {
                    print("Applying gradient to blendedImage")
                    viewModel.gradientImage = viewModel.applyGradient(to: image, horizontal: horizontalGradient, vertical: verticalGradient, radial: radialGradient, gradientRange: minGradient...maxGradient)
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

