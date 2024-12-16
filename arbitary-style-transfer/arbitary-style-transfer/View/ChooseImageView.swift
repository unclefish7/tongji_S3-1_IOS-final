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
            // 中间可滚动内容
            ScrollView {
                VStack(spacing: 20) {
                    Divider()

                    HStack {
                        Button("导入内容图片") {
                            imageType = "Content"
                            showingImagePicker = true
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)

                        Button("导入风格图片") {
                            imageType = "Style"
                            showingImagePicker = true
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()

                    Divider()

                    VStack {
                        Text("已导入内容图片：")
                            .font(.headline)
                        if let contentImage = viewModel.contentImage {
                            Image(uiImage: contentImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .clipped()
                                .cornerRadius(10)
                        }
                    }
                    .padding()

                    Divider()

                    VStack {
                        Text("已导入风格图片：")
                            .font(.headline)
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(viewModel.styleImages, id: \.self) { styleImage in
                                    Image(uiImage: styleImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .clipped()
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                    .padding()

                    Divider()

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
                        if await viewModel.performStyleTransfer() {
                            path.append(.preview)  // 使用 append 添加到导航栈
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

