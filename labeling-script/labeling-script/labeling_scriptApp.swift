//
//  labeling_scriptApp.swift
//  labeling-script
//
//  Created by 贾文超 on 2024/12/12.
//

import SwiftUI

@main
struct labeling_scriptApp: App {
    init() {
        print("Current working directory: \(FileManager.default.currentDirectoryPath)")
    }

    var body: some Scene {
        WindowGroup {
            PoseAnnotationView(folderPath: "") // 初始路径为空，用户选择后更新
        }
    }
}
