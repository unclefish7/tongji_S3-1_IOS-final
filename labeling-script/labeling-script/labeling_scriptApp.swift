//
//  labeling_scriptApp.swift
//  labeling-script
//
//  Created by 贾文超 on 2024/12/12.
//

import SwiftUI

@main
struct labeling_scriptApp: App {
    var body: some Scene {
        WindowGroup {
            PoseAnnotationView(folderPath: "/path/to/your/images") // 修改为你的图片目录路径
        }
    }
}
