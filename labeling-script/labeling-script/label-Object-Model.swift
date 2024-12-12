import Vision
import SwiftUI

class PoseAnnotationViewModel: ObservableObject {
    @Published var currentImage: NSImage? = nil
    @Published var classification: String = ""
    @Published var annotations: [ImageAnnotation] = []

    private var imagePaths: [String] = []
    private var currentIndex: Int = 0

    init(folderPath: String) {
        // 初始不加载图片
    }

    // 加载图片路径
    func loadImages(from paths: [String]) {
        imagePaths = paths
        currentIndex = 0
        loadNextImage()
    }

    // 加载下一张图片
    func loadNextImage() {
        guard currentIndex < imagePaths.count else { 
            print("No more images to load.")
            return 
        }
        let path = imagePaths[currentIndex]
        currentIndex += 1

        if let image = loadImage(from: path) {
            currentImage = image
            print("Loaded image: \(path)")
        } else {
            print("Failed to load image: \(path)")
        }
    }

    // 加载图片
    private func loadImage(from path: String) -> NSImage? {
        let url = URL(fileURLWithPath: path)
        if url.startAccessingSecurityScopedResource() {
            do {
                let data = try Data(contentsOf: url)
                guard let image = NSImage(data: data) else {
                    print("Failed to create image from data: \(path)")
                    return nil
                }
                url.stopAccessingSecurityScopedResource()
                return image
            } catch {
                print("Failed to load image data from: \(path), error: \(error)")
                url.stopAccessingSecurityScopedResource()
                return nil
            }
        } else {
            print("Failed to access security scoped resource: \(url)")
            return nil
        }
    }

    // 提取人体关键点
    func extractKeypoints(from image: NSImage) -> [[String: CGFloat]]? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
            guard let results = request.results,
                  let observation = results.first else { return nil }

            let recognizedPoints = try observation.recognizedPoints(.all)
            return recognizedPoints.map { (name, point) -> [String: CGFloat] in
                [
                    "name": CGFloat(name.rawValue.hashValue),
                    "x": CGFloat(point.location.x),
                    "y": CGFloat(point.location.y),
                    "confidence": CGFloat(point.confidence)
                ]
            }
        } catch {
            print("Failed to extract keypoints: \(error)")
            return nil
        }
    }

    // 保存标注结果
    func saveAnnotation() {
        guard let currentImage = currentImage else { return }
        guard let keypoints = extractKeypoints(from: currentImage) else { return }

        let fileName = imagePaths[currentIndex - 1].components(separatedBy: "/").last ?? "unknown"
        let annotation = ImageAnnotation(fileName: fileName, classification: classification, keypoints: keypoints)
        annotations.append(annotation)
    }

    // 导出标注到 JSON 文件
    func exportAnnotations(to path: String) {
        let url = URL(fileURLWithPath: path)
        if url.startAccessingSecurityScopedResource() {
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = .prettyPrinted

            do {
                let jsonData = try jsonEncoder.encode(annotations)
                try jsonData.write(to: url)
                url.stopAccessingSecurityScopedResource()
            } catch {
                print("Failed to export annotations: \(error)")
                url.stopAccessingSecurityScopedResource()
            }
        } else {
            print("Failed to access security scoped resource: \(url)")
        }
    }
}
