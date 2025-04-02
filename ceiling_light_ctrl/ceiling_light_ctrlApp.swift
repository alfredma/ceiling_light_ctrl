//
//  ceiling_light_ctrlApp.swift
//  ceiling_light_ctrl
//
//  Created by 马杨 on 2025/4/1.
//

import SwiftUI

@main
struct ceiling_light_ctrlApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(DefaultWindowStyle())
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
            NSApplication.shared.terminate(nil) // 完全退出应用程序
            }
        }
    }
}
