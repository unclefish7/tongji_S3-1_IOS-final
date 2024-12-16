//
//  ChooseImageView.swift
//  arbitary-style-transfer
//
//  Created by 贾文超 on 2024/12/16.
//

import SwiftUI

struct ChooseImageView: View {
    @ObservedObject var viewModel: StyleTransferViewModel
    @State private var showingImagePicker = false
    @State private var imageType = "Content"
    @State private var navigateToPreview = false

    var body: some View {
        VStack(spacing: 20) {
            Text("第一步：上传图片")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .padding()

            Divider().padding(.horizontal)

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

            Divider().padding(.horizontal)

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

            Divider().padding(.horizontal)

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

            Divider().padding(.horizontal)

            if viewModel.isProcessing {
                ProgressView("正在生成图片... \(Int(viewModel.processingProgress * 100))%")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            }

            NavigationLink(destination: PreviewImageView(stylizedImages: viewModel.stylizedImages), isActive: $navigateToPreview) {
                EmptyView()
            }

            Button("下一步：生成图片") {
                Task {
                    if await viewModel.performStyleTransfer() {
                        navigateToPreview = true
                    }
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(viewModel.isProcessing || viewModel.contentImage == nil || viewModel.styleImages.isEmpty)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(imageType: $imageType, viewModel: viewModel, allowsMultipleSelection: imageType == "Style")
        }
        .padding()
    }
}

