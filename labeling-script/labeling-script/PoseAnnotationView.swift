//
//  ContentView.swift
//  labeling-script
//
//  Created by 贾文超 on 2024/12/12.
//

import SwiftUI

struct PoseAnnotationView: View {
    @StateObject private var viewModel: PoseAnnotationViewModel

    init(folderPath: String) {
        _viewModel = StateObject(wrappedValue: PoseAnnotationViewModel(folderPath: folderPath))
    }

    var body: some View {
        VStack {
            // 显示当前图片
            if let image = viewModel.currentImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
            } else {
                Text("No image to display")
                    .font(.headline)
            }

            // 分类标注
            HStack {
                TextField("Enter classification", text: $viewModel.classification)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Save Annotation") {
                    viewModel.saveAnnotation()
                    viewModel.loadNextImage()
                }
                .padding()
            }

            Spacer()

            // 导出标注结果
            Button("Export Annotations") {
                let savePath = "/path/to/output/annotations.json" // 修改为你的导出路径
                viewModel.exportAnnotations(to: savePath)
            }
            .padding()
        }
        .padding()
    }
}

