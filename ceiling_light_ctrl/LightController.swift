import Foundation
import Combine

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        max(range.lowerBound, min(range.upperBound, self))
    }
}

class LightController: ObservableObject {
    static let shared = LightController()
    private let yeelight = YeelightController.shared
    private var cancellables = Set<AnyCancellable>()

    // 发布属性
    @Published var isOn: Bool = false
    @Published var brightness: Double = 50.0
    @Published var colorTemperature: Double = 4000.0

    private var brightnessUpdateWorkItem: DispatchWorkItem?
    private var colorTemperatureUpdateWorkItem: DispatchWorkItem?

    // 私有初始化防止外部实例化
    private init() {
        setupBindings()
        refreshDeviceState()
    }
    private func setupBindings() {
        $brightness
            .dropFirst()
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateBrightness()
            }
            .store(in: &cancellables)
        
        $colorTemperature
            .dropFirst()
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateColorTemperature()
            }
            .store(in: &cancellables)
    }
    func refreshDeviceState() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            if let state = self.yeelight.getProperties() {
                DispatchQueue.main.async {
                    self.isOn = (state.power == "on")
                    self.brightness = Double(state.brightness)
                    self.colorTemperature = Double(state.colorTemperature)
                    print("Refreshed device state: \(state)")
                }
            }
        }
    }

    func togglePower() {
        isOn ? turnOff() : turnOn()
    }
    
    func turnOn() {
        yeelight.turnOn()
        isOn = true
    }
    
    func turnOff() {
        yeelight.turnOff()
        isOn = false
    }

    func setBrightness(_ value: Double) {
        brightness = value.clamped(to: 1...100)
    }
    
    func setColorTemperature(_ value: Double) {
        colorTemperature = value.clamped(to: 1700...6500)
    }

    func updateBrightness() {
        brightnessUpdateWorkItem?.cancel() // 取消之前的任务
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.yeelight.setBrightness(Int(self.brightness))
        }
        brightnessUpdateWorkItem = workItem
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3, execute: workItem) // 延迟 0.3 秒执行
    }

    func updateColorTemperature() {
        colorTemperatureUpdateWorkItem?.cancel() // 取消之前的任务
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.yeelight.setColorTemperature(Int(self.colorTemperature))
        }
        colorTemperatureUpdateWorkItem = workItem
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3, execute: workItem) // 延迟 0.3 秒执行
    }
}
