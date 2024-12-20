//
//  StrengthModifyView.swift
//  arbitary-style-transfer
//
//  Created by 贾文超 on 2024/12/16.
//

import SwiftUI

struct StrengthModifyView: View {
    @ObservedObject var viewModel: StyleTransferViewModel
    @Binding var path: [NavigationPath]  // 改为数组类型
    @State private var strengths: [Float]
    @State private var isLoading = true  // 添加加载状态
    @State private var isSliderEnabled = true  // 添加滑动条启用状态
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: StyleTransferViewModel, path: Binding<[NavigationPath]>) {
        self.viewModel = viewModel
        self._path = path
        // 修改初始强度值为 1.0（满强度）
        self._strengths = State(initialValue: Array(repeating: 1.0,
                                                  count: viewModel.stylizedImages.count))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // 固定在顶部的融合结果预览
                    BlendedImageView(viewModel: viewModel, isLoading: $isLoading)
                        .frame(height: UIScreen.main.bounds.height * 0.4) // 固定高度为屏幕的40%
                    
                    // 可滚动的滑块区域
                    ScrollView {
                        StrengthSlidersView(viewModel: viewModel, 
                                          strengths: $strengths, 
                                          isSliderEnabled: $isSliderEnabled, 
                                          updateImage: updateImage, 
                                          cancelBlending: viewModel.cancelBlending)
                            .padding(.vertical)
                    }
                    
                    // 底部确认按钮
                    ConfirmButton(path: $path, viewModel: viewModel)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("调整风格融合强度")
                        .font(.headline)
                }
            }
        }
        .onAppear {
            isLoading = true
            updateImage()
        }
        .onChange(of: viewModel.blendedImage) { _ in
            isLoading = false
            isSliderEnabled = true  // 启用滑动条
        }
        .onDisappear {
            viewModel.clearPixelCache(clearBlendedImage: false)  // 不清理 blendedImage
        }
    }
    
    private func updateImage() {
        isLoading = true
        isSliderEnabled = false  // 禁用滑动条
        viewModel.blendMultipleStyles(
            original: viewModel.resizedContentImage ?? UIImage(),
            stylizedImages: viewModel.stylizedImages,
            strengths: strengths,
            debounceInterval: 0.1  // 100ms 的防抖间隔
        )
    }
}

struct BlendedImageView: View {
    @ObservedObject var viewModel: StyleTransferViewModel
    @Binding var isLoading: Bool
    
    var body: some View {
        ZStack {
            if let blendedImage = viewModel.blendedImage {
                VStack {
                    Text("融合结果")
                        .font(.headline)
                        .padding(.top, 8)
                    Image(uiImage: blendedImage)
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal)
                }
            }
            
            if isLoading {
                Color.black
                    .opacity(0.5)
                
                ProgressView("正在生成融合效果...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
            }
        }
    }
}

struct StrengthSlidersView: View {
    @ObservedObject var viewModel: StyleTransferViewModel
    @Binding var strengths: [Float]
    @Binding var isSliderEnabled: Bool
    let updateImage: () -> Void
    let cancelBlending: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            ForEach(0..<viewModel.stylizedImages.count, id: \.self) { index in
                VStack {
                    HStack {
                        Image(uiImage: viewModel.stylizedImages[index])
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100)
                        
                        VStack {
                            Text("风格 #\(index + 1)")
                            Slider(value: $strengths[index], in: 0...1) { editing in
                                if !editing {
                                    // 滑动结束时进行图像融合
                                    updateImage()
                                } else {
                                    // 滑动时取消当前的融合操作
                                    cancelBlending()
                                }
                            }
                            .disabled(!isSliderEnabled)  // 根据状态禁用滑动条
                            Text("强度: \(Int(strengths[index] * 100))%")
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ConfirmButton: View {
    @Binding var path: [NavigationPath]
    let viewModel: StyleTransferViewModel
    
    var body: some View {
        Button(action: {
            path.append(.regionalGradient)  // 导航到新的视图并传递 viewModel 实例
        }) {
            Text("确认")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding()
    }
}

