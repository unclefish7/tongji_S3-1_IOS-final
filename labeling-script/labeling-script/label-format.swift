import Foundation

struct ImageAnnotation: Codable {
    let fileName: String
    let classification: String
    let keypoints: [[String: CGFloat]]
}
