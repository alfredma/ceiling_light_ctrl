//import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem?
    var window: NSWindow? // 改为强引用，防止窗口被意外释放
    private var lightController = LightController.shared
    private var cancellables = Set<AnyCancellable>()
    // 全局标题存储
    private var sliderTitleMap = [Int: String]()

    // MARK: - 应用生命周期
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 初始化主窗口
        setupMainWindow()
        // 设置状态栏
        setupStatusItem()
        // 绑定数据监听
        setupSubscriptions()
        // 设置Dock图标策略
        NSApp.setActivationPolicy(.regular)
        // 保持常规激活策略但隐藏不需要的界面元素
        // NSApp.setActivationPolicy(.accessory)
    }

    // MARK: - 窗口配置
    private func setupMainWindow() {
        let contentView = ContentView()
        let window = createWindow(with: NSHostingView(rootView: contentView))
        window.makeKeyAndOrderFront(nil)
        self.window = window
    }

    private func createWindow(with contentView: NSView) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Ceiling Light Controller"
        window.contentView = contentView
        window.contentMinSize = NSSize(width: 600, height: 400)
        window.isReleasedWhenClosed = false
        /*
         * canJoinAllSpaces: 允许窗口在所有桌面空间显示
         * transient: 防止窗口出现在 Mission Control 作为独立窗口
        */
        window.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenNone]
        window.isExcludedFromWindowsMenu = true
        window.delegate = self
        return window
    }

    // MARK: - 状态栏配置
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // 设置状态栏图标
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "lightbulb", accessibilityDescription: "Ceiling Light")
            button.action = #selector(toggleMenu(_:))
            button.target = self
        }
        
        // 构建菜单
        buildStatusMenu()
    }

    private func buildStatusMenu() {
        let menu = NSMenu()
        menu.delegate = self
        
        // 添加菜单项
        menu.addItem(NSMenuItem(title: "Show Window", action: #selector(showWindow), keyEquivalent: "w"))
        menu.addItem(NSMenuItem.separator())
        
        // 灯光控制
        menu.addItem(NSMenuItem(title: "Turn On", action: #selector(turnOnLight), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Turn Off", action: #selector(turnOffLight), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // 亮度控制
        let brightnessItem = createSliderMenuItem(
            title: "Brightness",
            currentValue: lightController.brightness,
            range: 1...100,
            unit: "%",
            tag: 1001,
            action: #selector(brightnessChanged(_:))
        )
        menu.addItem(brightnessItem)
        
        // 色温控制
        let tempItem = createSliderMenuItem(
            title: "Color Temperature",
            currentValue: lightController.colorTemperature,
            range: 3500...6000,
            unit: "K",
            tag: 1002,
            action: #selector(colorTempChanged(_:))
        )
        menu.addItem(tempItem)
        menu.addItem(NSMenuItem.separator())
        
        // 退出项
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }

    // MARK: - 菜单项创建
    private func createSliderMenuItem(title: String, currentValue: Double, range: ClosedRange<Double>, unit: String, tag: Int, action: Selector) -> NSMenuItem {
        let view = NSStackView()
        view.orientation = .vertical
        view.spacing = 8
        view.edgeInsets = NSEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        view.translatesAutoresizingMaskIntoConstraints = false // 添加约束

        // 标题标签（不再需要设置tag）
        let titleLabel = NSTextField(labelWithString: "\(title): \(Int(currentValue))\(unit)")
        sliderTitleMap[tag] = title // 关键：存储原始标题
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.isEditable = false
        titleLabel.isBordered = false
        
        // 滑动条（不再需要设置tag）
        let slider = NSSlider(value: currentValue, 
                             minValue: range.lowerBound, 
                             maxValue: range.upperBound,
                             target: self,
                             action: action)
        slider.isContinuous = true
        slider.controlSize = .small  // 使用更紧凑的尺寸
        slider.widthAnchor.constraint(equalToConstant: 180).isActive = true // 固定宽度
        
        // 添加刻度
        let tickMarks = 5 // 5 等分
        slider.numberOfTickMarks = 2*tickMarks + 1 // 包括起点和终点
        slider.allowsTickMarkValuesOnly = true

        // 刻度标签
        let tickStack = NSStackView()
        tickStack.orientation = .horizontal
        tickStack.distribution = .equalSpacing
        //tickStack.distribution = .equalCentering
        tickStack.translatesAutoresizingMaskIntoConstraints = false
        tickStack.widthAnchor.constraint(equalToConstant: 180).isActive = true // 对齐滑动条宽度
        /*
        [range.lowerBound, (range.lowerBound + range.upperBound)/2, range.upperBound].forEach { value in
            let label = NSTextField(labelWithString: "\(Int(value))\(unit)")
            label.font = .systemFont(ofSize: 10)
            tickStack.addArrangedSubview(label)
        }*/
        for i in 0...tickMarks {
            let tickValue = range.lowerBound + (range.upperBound - range.lowerBound) * Double(i) / Double(tickMarks)
            let tickLabel = NSTextField(labelWithString: "\(Int(tickValue))")
            tickLabel.alignment = .center
            tickLabel.font = NSFont.systemFont(ofSize: 10)
            tickLabel.textColor = .secondaryLabelColor
            tickLabel.isEditable = false
            tickLabel.isBordered = false
            tickLabel.backgroundColor = .clear
            tickStack.addArrangedSubview(tickLabel)
        }
        
        view.addArrangedSubview(titleLabel)
        view.addArrangedSubview(slider)
        view.addArrangedSubview(tickStack)
        
        // 设置容器的宽度和高度
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 200), // 设置容器宽度
            titleLabel.heightAnchor.constraint(equalToConstant: 20), // 设置标题高度
            slider.heightAnchor.constraint(equalToConstant: 20), // 设置滑动条高度
            tickStack.heightAnchor.constraint(equalToConstant: 15) // 设置刻度标签高度
        ])

        let item = NSMenuItem()
        item.view = view
        item.tag = tag // 关键修改：设置菜单项本身的tag
        return item
    }

    // MARK: - 数据绑定
    func setupSubscriptions() {
        cancellables.removeAll() // 清空旧订阅
        
        lightController.$brightness
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.updateSliderValue(value, forTag: 1001, unit: "%")
            }
            .store(in: &cancellables)
        
        lightController.$colorTemperature
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.updateSliderValue(value, forTag: 1002, unit: "K")
            }
            .store(in: &cancellables)
    }

    private func updateSliderValue(_ value: Double, forTag tag: Int, unit: String) {
        guard let menu = statusItem?.menu,
            // 通过菜单项tag获取对应item
            let item = menu.item(withTag: tag),
            let stackView = item.view as? NSStackView,
            // 按顺序获取子视图（索引0是标题，1是滑动条）
            stackView.arrangedSubviews.count >= 2,
            let titleLabel: NSTextField = stackView.arrangedSubviews[0] as? NSTextField,
            let slider = stackView.arrangedSubviews[1] as? NSSlider else {
            print("无法找到对应控件 tag:\(tag)")
            return
        }
        
        DispatchQueue.main.async {
            slider.doubleValue = value
            // 通过存储的标题更新
            let titlePrefix = self.sliderTitleMap[tag] ?? "Unknown"
            titleLabel.stringValue = "\(titlePrefix): \(Int(value))\(unit)"
        }
    }

    // MARK: - 窗口管理
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // 保持常规激活策略但隐藏不需要的界面元素,隐藏dock图标
        NSApp.setActivationPolicy(.accessory)
        sender.orderOut(nil)
        NSApp.hide(nil) // 隐藏整个应用
        return false
    }
    
    @objc private func toggleWindow() {
        guard let window = window else { return }
        
        if window.isVisible {
            // 隐藏窗口时保持辅助模式
            window.orderOut(nil)
            NSApp.hide(nil)
        } else {
            // 临时切换为常规应用激活策略
            NSApp.setActivationPolicy(.regular)
            // 强制激活应用并显示窗口
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            window.center()
            // 延迟恢复辅助模式避免 Dock 图标残留
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }

    @objc private func showWindow() {
        guard let window = window else { return }
        //if window.isVisible {
            // 切换为常规应用激活策略
            NSApp.setActivationPolicy(.regular)
            // 强制显示
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        //}
    }
    // MARK: - 用户交互
    @objc private func toggleMenu(_ sender: NSStatusBarButton) {
        statusItem?.menu?.popUp(positioning: nil, at: .zero, in: sender)
    }
    
    @objc private func turnOnLight() {
        lightController.turnOn()
    }
    
    @objc private func turnOffLight() {
        lightController.turnOff()
    }
    
    @objc private func brightnessChanged(_ sender: NSSlider) {
        let value = sender.doubleValue
        lightController.setBrightness(Double(sender.doubleValue))
        // 立即更新状态栏菜单标题
        updateSliderValue(value, forTag: 1001, unit: "%")
    }
    
    @objc private func colorTempChanged(_ sender: NSSlider) {
        let value = sender.doubleValue
        lightController.setColorTemperature(value)
        updateSliderValue(value, forTag: 1002, unit: "K")
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - 菜单代理
    func menuWillOpen(_ menu: NSMenu) {
        lightController.refreshDeviceState()
    }
    

    /*
    // 创建滑动条视图
    private func createSliderView(title: String, value: Double, minValue: Double, maxValue: Double, action: Selector) -> NSView {
        let container = NSStackView()
        container.orientation = .vertical
        container.spacing = 8 // 设置文本和滑动条之间的固定间距
        container.edgeInsets = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10) // 设置内边距
        container.translatesAutoresizingMaskIntoConstraints = false // 禁用自动调整大小约束

        // 添加标题
        let titleLabel = NSTextField(labelWithString: "\(title): \(Int(value))")
        titleLabel.tag = title == "Brightness" ? 1001 : 1002 // 唯一标识
        titleLabel.alignment = .center
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .labelColor
        titleLabel.isEditable = false
        titleLabel.isBordered = false
        titleLabel.backgroundColor = .clear
        titleLabel.translatesAutoresizingMaskIntoConstraints = false // 禁用自动调整大小约束

        // 添加滑动条
        let slider = NSSlider(value: value, minValue: minValue, maxValue: maxValue, target: self, action: action)
        slider.tag = title == "Brightness" ? 2001 : 2002 // 唯一标识
        slider.isContinuous = true
        slider.controlSize = .small
        slider.translatesAutoresizingMaskIntoConstraints = false // 禁用自动调整大小约束

        // 添加刻度
        let tickMarks = 5 // 5 等分
        slider.numberOfTickMarks = 2*tickMarks + 1 // 包括起点和终点
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
    }*/
}

// MARK: - 扩展方法
extension NSMenu {
    func item(withTag tag: Int) -> NSMenuItem? {
        items.first(where: { $0.tag == tag })
    }
}
