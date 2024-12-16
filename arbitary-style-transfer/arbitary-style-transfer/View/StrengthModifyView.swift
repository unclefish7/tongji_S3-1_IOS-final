//
//  StrengthModifyView.swift
//  arbitary-style-transfer
//
//  Created by 贾文超 on 2024/12/16.
//

import SwiftUI

struct StrengthModifyView: View {
    @ObservedObject var viewModel: StyleTransferViewModel
    let originalImage: UIImage
    let stylizedImages: [UIImage]
    @Binding var path: [NavigationPath]  // 改为数组类型
    @State private var strengths: [Float]
    @State private var isLoading = true  // 添加加载状态
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: StyleTransferViewModel, originalImage: UIImage, stylizedImages: [UIImage], path: Binding<[NavigationPath]>) {
        self.viewModel = viewModel
        self.originalImage = originalImage
        self.stylizedImages = stylizedImages
        self._path = path
        self._strengths = State(initialValue: Array(repeating: 1.0 / Float(stylizedImages.count),
                                                  count: stylizedImages.count))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack {
                            ZStack {
                                if let blendedImage = viewModel.blendedImage {
                                    VStack {
                                        Text("融合结果")
                                            .font(.headline)
                                        Image(uiImage: blendedImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                    }
                                }
                                
                                if isLoading {
                                    Color.black
                                        .opacity(0.5)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    
                                    ProgressView("正在生成融合效果...")
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .padding()
                                        .background(Color.white.opacity(0.8))
                                        .cornerRadius(10)
                                }
                            }
                            
                            VStack(spacing: 20) {
                                ForEach(0..<stylizedImages.count, id: \.self) { index in
                                    VStack {
                                        HStack {
                                            Image(uiImage: stylizedImages[index])
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 100)
                                            
                                            VStack {
                                                Text("风格 #\(index + 1)")
                                                Slider(value: $strengths[index], in: 0...1) { editing in
                                                    if !editing {
                                                        updateImage()
                                                    }
                                                }
                                                .onChange(of: strengths[index]) { _ in
                                                    updateImage()
                                                }
                                                Text("强度: \(Int(strengths[index] * 100))%")
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    
                    Button(action: {
                        path.append(.final)  // 使用 append 添加到导航栈
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
        }
        .onDisappear {
            viewModel.clearPixelCache()
            viewModel.blendedImage = nil  // 清理融合图像
        }
    }
    
    private func updateImage() {
        isLoading = true
        viewModel.blendMultipleStyles(
            original: originalImage,
            stylizedImages: stylizedImages,
            strengths: strengths,
            debounceInterval: 0.1  // 100ms 的防抖间隔
        )
    }
}

