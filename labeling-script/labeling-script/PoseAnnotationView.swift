//
//  ContentView.swift
//  labeling-script
//
//  Created by 贾文超 on 2024/12/12.
//

import SwiftUI
import UniformTypeIdentifiers

struct PoseAnnotationView: View {
    @StateObject private var viewModel: PoseAnnotationViewModel
    @State private var isShowingImagePicker = false
    @State private var isShowingExportPicker = false

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
                isShowingExportPicker = true
            }
            .padding()
            .fileExporter(
                isPresented: $isShowingExportPicker,
                document: JSONFile(initialText: ""),
                contentType: .json,
                defaultFilename: "annotations"
            ) { result in
                switch result {
                case .success(let url):
                    if url.startAccessingSecurityScopedResource() {
                        viewModel.exportAnnotations(to: url.path)
                        url.stopAccessingSecurityScopedResource()
                    } else {
                        print("Failed to access security scoped resource: \(url)")
                    }
                case .failure(let error):
                    print("Failed to export annotations: \(error)")
                }
            }

            // 选择图片
            Button("Select Images") {
                isShowingImagePicker = true
            }
            .padding()
            .fileImporter(
                isPresented: $isShowingImagePicker,
                allowedContentTypes: [.image],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    viewModel.loadImages(from: urls.map { $0.path })
                case .failure(let error):
                    print("Failed to select images: \(error)")
                }
            }
        }
        .padding()
    }
}

// 用于导出 JSON 文件的辅助结构
struct JSONFile: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var text: String

    init(initialText: String) {
        self.text = initialText
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.text = String(data: data, encoding: .utf8) ?? ""
        } else {
            self.text = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return .init(regularFileWithContents: data)
    }
}

