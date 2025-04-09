//import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem?
    var window: NSWindow? // 改为强引用，防止窗口被意外释放
    private var lightController = LightController.shared
    private var cancellables = Set<AnyCancellable>()

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
        menu.addItem(NSMenuItem(title: "Show Window", action: #selector(toggleWindow), keyEquivalent: "w"))
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
            range: 2700...6500,
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
        view.edgeInsets = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        // 标题标签（不再需要设置tag）
        let titleLabel = NSTextField(labelWithString: "\(title): \(Int(currentValue))\(unit)")
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
        
        // 刻度标签
        let tickStack = NSStackView()
        tickStack.distribution = .equalCentering
        [range.lowerBound, (range.lowerBound + range.upperBound)/2, range.upperBound].forEach { value in
            let label = NSTextField(labelWithString: "\(Int(value))\(unit)")
            label.font = .systemFont(ofSize: 10)
            tickStack.addArrangedSubview(label)
        }
        
        view.addArrangedSubview(titleLabel)
        view.addArrangedSubview(slider)
        view.addArrangedSubview(tickStack)
        
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
            titleLabel.stringValue = "\(titleLabel.stringValue.components(separatedBy: ":")[0]): \(Int(value))\(unit)"
        }
    }

    // MARK: - 窗口管理
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
    
    @objc private func toggleWindow() {
        guard let window = window else { return }
        
        if window.isVisible {
            window.orderOut(nil)
            NSApp.hide(nil)
        } else {
            window.center()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
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
        lightController.setBrightness(Double(sender.doubleValue))
    }
    
    @objc private func colorTempChanged(_ sender: NSSlider) {
        lightController.setColorTemperature(Double(sender.doubleValue))
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
    }

    // 菜单弹出时更新滑动条状态
    func menuWillOpen(_ menu: NSMenu) {
        // 获取当前状态
        LightController.shared.refreshDeviceState()
        let currentBrightness = lightController.brightness
        let currentColorTemp = lightController.colorTemperature
        print("Current Brightness: \(currentBrightness)%")
        print("Current Color Temperature: \(currentColorTemp)K")

        // 更新UI（确保在主线程）
        DispatchQueue.main.async {
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
    }*/
}

// MARK: - 扩展方法
extension NSMenu {
    func item(withTag tag: Int) -> NSMenuItem? {
        items.first(where: { $0.tag == tag })
    }
}