//
//  ChooseImageView.swift
//  arbitary-style-transfer
//
//  Created by 贾文超 on 2024/12/16.
//

import SwiftUI

struct ChooseImageView: View {
    @ObservedObject var viewModel: StyleTransferViewModel
    @Binding var path: [NavigationPath]  // 改为数组类型
    @State private var showingImagePicker = false
    @State private var imageType = "Content"

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 30) {
                    // 内容图片上传区域
                    VStack(spacing: 15) {
                        Text("内容图片")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Button {
                            imageType = "Content"
                            showingImagePicker = true
                        } label: {
                            if let contentImage = viewModel.contentImage {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: contentImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 200, height: 200)
                                        .cornerRadius(10)
                                    
                                    // 添加删除按钮
                                    Button {
                                        viewModel.contentImage = nil
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.red)
                                            .background(Circle().fill(Color.white))
                                    }
                                    .offset(x: 8, y: -8)
                                }
                            } else {
                                DashedUploadButton(title: "点击上传内容图片")
                                    .frame(width: 200, height: 200)
                            }
                        }
                    }
                    .padding()
                    
                    // 风格图片上传区域
                    VStack(spacing: 15) {
                        Text("风格图片")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                // 添加风格图片按钮
                                Button {
                                    imageType = "Style"
                                    showingImagePicker = true
                                } label: {
                                    DashedUploadButton(title: "添加风格图片")
                                        .frame(width: 150, height: 150)
                                }
                                
                                // 显示已选择的风格图片
                                ForEach(viewModel.styleImages.indices, id: \.self) { index in
                                    ZStack {
                                        Image(uiImage: viewModel.styleImages[index])
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 150, height: 150)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                        
                                        // 添加删除按钮
                                        Button {
                                            viewModel.styleImages.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.title2)
                                                .foregroundStyle(.red)
                                                .background(
                                                    Circle()
                                                        .fill(.white)
                                                        .frame(width: 24, height: 24)
                                                )
                                                .padding(8)
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                    }
                                    .frame(width: 150, height: 150)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()

                    if viewModel.isProcessing {
                        ProgressView("正在生成图片... \(Int(viewModel.processingProgress * 100))%")
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    }
                }
            }
            
            // 底部固定按钮
            VStack {
                Divider()

                Button("下一步：生成图片") {
                    Task {
                        let success = await viewModel.performStyleTransfer()
                        DispatchQueue.main.async {
                            if success {
                                print("Navigating to preview")
                                path.append(.preview)  // 确保在主线程上更新 path
                            } else {
                                print("Style transfer failed or no stylized images generated")
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(viewModel.isProcessing || viewModel.contentImage == nil || viewModel.styleImages.isEmpty)
                .padding()
            }
            .background(Color.white)
        }
        .navigationTitle("上传图片")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(imageType: $imageType, viewModel: viewModel, allowsMultipleSelection: imageType == "Style")
        }
    }
}

// 添加虚线上传按钮组件
struct DashedUploadButton: View {
    let title: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(.blue)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundColor(.gray.opacity(0.3))
        )
    }
}

