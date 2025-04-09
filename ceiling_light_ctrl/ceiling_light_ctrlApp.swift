//
//  ceiling_light_ctrlApp.swift
//  ceiling_light_ctrl
//
//  Created by 马杨 on 2025/4/1.
//

import SwiftUI

@main
struct ceiling_light_ctrlApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
                .frame(width: 0, height: 0)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandMenu("调试") {
                Button("强制刷新") {
                    LightController.shared.refreshDeviceState()
                }
                .keyboardShortcut("r")
            }
        }
    }
}
