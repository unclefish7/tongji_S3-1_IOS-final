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
    @State private var strengths: [Float]
    @State private var currentImage: UIImage?
    
    init(viewModel: StyleTransferViewModel, originalImage: UIImage, stylizedImages: [UIImage]) {
        self.viewModel = viewModel
        self.originalImage = originalImage
        self.stylizedImages = stylizedImages
        self._strengths = State(initialValue: Array(repeating: 1.0 / Float(stylizedImages.count),
                                                  count: stylizedImages.count))
    }
    
    var body: some View {
        ScrollView {
            VStack {
                Text("调整风格融合强度")
                    .font(.title)
                    .padding()
                
                if let blendedImage = currentImage {
                    Text("融合结果")
                        .font(.headline)
                    Image(uiImage: blendedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .padding()
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
        .onAppear {
            updateImage()
        }
    }
    
    private func updateImage() {
        if let blendedImage = viewModel.blendMultipleStyles(
            original: originalImage,
            stylizedImages: stylizedImages,
            strengths: strengths
        ) {
            currentImage = blendedImage
        }
    }
}

