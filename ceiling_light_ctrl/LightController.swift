import Foundation

class LightController: ObservableObject {
    static let shared = LightController()
    private init() { // 禁止外部实例化
        // 从 UserDefaults 中加载状态
        //loadLightStateFromDefaults()
    }
    // Properties to store light state
    @Published var isLightOn: Bool = false
    @Published var brightness: Double = 50.0
    @Published var colorTemperature: Double = 4000.0
    private let yeelightController = YeelightController.shared

    private var brightnessUpdateWorkItem: DispatchWorkItem?
    private var colorTemperatureUpdateWorkItem: DispatchWorkItem?

    func refreshDeviceState() {
        if let state = yeelightController.getProperties() {
            self.isLightOn = (state.power == "on")
            self.brightness = Double(state.brightness)
            self.colorTemperature = Double(state.colorTemperature)
            print("Refreshed device state: \(state)")
        }
    }

    func toggleLight() {
        if isLightOn {
            yeelightController.turnOffLight()
        } else {
            yeelightController.turnOnLight()
        }
        isLightOn.toggle()
    }

    func updateBrightness() {
        brightnessUpdateWorkItem?.cancel() // 取消之前的任务
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.yeelightController.setBrightness(Int(self.brightness))
        }
        brightnessUpdateWorkItem = workItem
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3, execute: workItem) // 延迟 0.3 秒执行
    }

    func updateColorTemperature() {
        colorTemperatureUpdateWorkItem?.cancel() // 取消之前的任务
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.yeelightController.setColorTemperature(Int(self.colorTemperature))
        }
        colorTemperatureUpdateWorkItem = workItem
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3, execute: workItem) // 延迟 0.3 秒执行
    }
}