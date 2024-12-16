//
//  ChooseImageView.swift
//  arbitary-style-transfer
//
//  Created by 贾文超 on 2024/12/16.
//

import SwiftUI

struct ChooseImageView: View {
    @StateObject private var viewModel = StyleTransferViewModel()
    @State private var showingImagePicker = false
    @State private var imageType = "Content"

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

            Button("下一步：风格调整") {
                // Navigate to the next view
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(imageType: $imageType, viewModel: viewModel, allowsMultipleSelection: imageType == "Style")
        }
        .padding()
    }
}

