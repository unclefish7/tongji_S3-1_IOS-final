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
    let stylizedImage: UIImage
    @State private var strength: Float = 1.0
    @State private var currentImage: UIImage?
    
    var body: some View {
        VStack {
            Text("调整风格迁移强度")
                .font(.title)
                .padding()
            
            if let displayImage = currentImage {
                Image(uiImage: displayImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            
            HStack {
                Text("原始")
                Slider(value: $strength, in: 0...1) { editing in
                    if !editing {
                        updateImage()
                    }
                }
                .onChange(of: strength) { _ in
                    updateImage()
                }
                Text("风格化")
            }
            .padding()
            
            Text("强度: \(Int(strength * 100))%")
                .padding()
        }
        .onAppear {
            currentImage = stylizedImage
            updateImage()
        }
    }
    
    private func updateImage() {
        if let interpolatedImage = viewModel.interpolateImages(
            original: originalImage,
            stylized: stylizedImage,
            strength: strength
        ) {
            currentImage = interpolatedImage
        }
    }
}

