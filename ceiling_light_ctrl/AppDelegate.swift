//import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem?
    let lightController = LightController() // 控制逻辑实例
    var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 创建状态栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "lightbulb", accessibilityDescription: "Ceiling Light")
        }

        // 创建菜单
        let menu = NSMenu()
        menu.delegate = self // 设置菜单代理

        // 添加 "Show Window" 按钮
        menu.addItem(NSMenuItem(title: "Show Window", action: #selector(showWindow), keyEquivalent: "w"))

        // 添加开关灯按钮
        menu.addItem(NSMenuItem(title: "Turn On", action: #selector(turnOnLight), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Turn Off", action: #selector(turnOffLight), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        // 添加亮度滑动条
        let brightnessView = createSliderView(
            title: "Brightness",
            value: 50,
            minValue: 0,
            maxValue: 100,
            action: #selector(brightnessChanged(_:))
        )
        let brightnessItem = NSMenuItem()
        brightnessItem.view = brightnessView
        brightnessItem.view?.setFrameSize(NSSize(width: 200, height: 80)) // 设置固定大小
        menu.addItem(brightnessItem)

        // 添加色温滑动条
        let colorTempView = createSliderView(
            title: "Color Temperature",
            value: 4000,
            minValue: 3500,
            maxValue: 6000,
            action: #selector(colorTempChanged(_:))
        )
        let colorTempItem = NSMenuItem()
        colorTempItem.view = colorTempView
        colorTempItem.view?.setFrameSize(NSSize(width: 200, height: 80)) // 设置固定大小
        menu.addItem(colorTempItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    @objc func showWindow() {
        if window == nil {
            let contentView = ContentView()
            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window?.center()
            window?.setFrameAutosaveName("Main Window")
            window?.contentView = NSHostingView(rootView: contentView)
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func turnOnLight() {
        print("Turning on the light")
        lightController.runPythonScript(command: "on")
    }

    @objc func turnOffLight() {
        print("Turning off the light")
        lightController.runPythonScript(command: "off")
    }

    @objc func brightnessChanged(_ sender: NSSlider) {
        let brightness = Int(sender.doubleValue)
        print("Brightness changed to \(brightness)%")
        lightController.runPythonScript(command: "brightness", value: brightness)

        // 更新标题显示
        if let container = sender.superview as? NSStackView,
           let titleLabel = container.arrangedSubviews.first as? NSTextField {
            titleLabel.stringValue = "Brightness: \(brightness)%"
        }
    }

    @objc func colorTempChanged(_ sender: NSSlider) {
        let colorTemp = Int(sender.doubleValue)
        print("Color Temperature changed to \(colorTemp)K")
        lightController.runPythonScript(command: "colortemp", value: colorTemp)

        // 更新标题显示
        if let container = sender.superview as? NSStackView,
           let titleLabel = container.arrangedSubviews.first as? NSTextField {
            titleLabel.stringValue = "Color Temperature: \(colorTemp)K"
        }
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // 创建滑动条视图
    private func createSliderView(title: String, value: Double, minValue: Double, maxValue: Double, action: Selector) -> NSView {
        let container = NSStackView()
        container.orientation = .vertical
        container.spacing = 8 // 设置文本和滑动条之间的固定间距
        container.edgeInsets = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10) // 设置内边距
        container.translatesAutoresizingMaskIntoConstraints = false // 禁用自动调整大小约束

        // 添加标题
        let titleLabel = NSTextField(labelWithString: "\(title): \(Int(value))")
        titleLabel.alignment = .center
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .labelColor
        titleLabel.isEditable = false
        titleLabel.isBordered = false
        titleLabel.backgroundColor = .clear
        titleLabel.translatesAutoresizingMaskIntoConstraints = false // 禁用自动调整大小约束

        // 添加滑动条
        let slider = NSSlider(value: value, minValue: minValue, maxValue: maxValue, target: self, action: action)
        slider.isContinuous = true
        slider.controlSize = .small
        slider.translatesAutoresizingMaskIntoConstraints = false // 禁用自动调整大小约束

        // 添加刻度
        let tickMarks = 5 // 5 等分
        slider.numberOfTickMarks = tickMarks + 1 // 包括起点和终点
        slider.allowsTickMarkValuesOnly = true

        // 添加刻度标签
        let tickLabels = NSStackView()
        tickLabels.orientation = .horizontal
        tickLabels.distribution = .equalSpacing
        tickLabels.translatesAutoresizingMaskIntoConstraints = false

        for i in 0...tickMarks {
            let tickValue = minValue + (maxValue - minValue) * Double(i) / Double(tickMarks)
            let tickLabel = NSTextField(labelWithString: "\(Int(tickValue))")
            tickLabel.alignment = .center
            tickLabel.font = NSFont.systemFont(ofSize: 10)
            tickLabel.textColor = .secondaryLabelColor
            tickLabel.isEditable = false
            tickLabel.isBordered = false
            tickLabel.backgroundColor = .clear
            tickLabels.addArrangedSubview(tickLabel)
        }

        // 添加到容器
        container.addArrangedSubview(titleLabel)
        container.addArrangedSubview(slider)
        container.addArrangedSubview(tickLabels)

        // 设置容器的宽度和高度
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 200), // 设置容器宽度
            titleLabel.heightAnchor.constraint(equalToConstant: 20), // 设置标题高度
            slider.heightAnchor.constraint(equalToConstant: 20), // 设置滑动条高度
            tickLabels.heightAnchor.constraint(equalToConstant: 15) // 设置刻度标签高度
        ])

        return container
    }

    // 菜单弹出时更新滑动条状态
    func menuWillOpen(_ menu: NSMenu) {
        // 获取当前状态
        let currentBrightness = lightController.getCurrentBrightness()
        let currentColorTemp = lightController.getCurrentColorTemperature()

        // 更新亮度滑动条
        if let brightnessItem = menu.items.first(where: { ($0.view?.subviews.contains(where: { $0 is NSSlider }) ?? false) }) {
            if let slider = brightnessItem.view?.subviews.compactMap({ $0 as? NSSlider }).first {
                slider.doubleValue = currentBrightness
                if let container = slider.superview as? NSStackView,
                   let titleLabel = container.arrangedSubviews.first as? NSTextField {
                    titleLabel.stringValue = "Brightness: \(Int(currentBrightness))%"
                }
            }
        }

        // 更新色温滑动条
        if let colorTempItem = menu.items.last(where: { ($0.view?.subviews.contains(where: { $0 is NSSlider }) ?? false) }) {
            if let slider = colorTempItem.view?.subviews.compactMap({ $0 as? NSSlider }).first {
                slider.doubleValue = currentColorTemp
                if let container = slider.superview as? NSStackView,
                   let titleLabel = container.arrangedSubviews.first as? NSTextField {
                    titleLabel.stringValue = "Color Temperature: \(Int(currentColorTemp))K"
                }
            }
        }
    }
}