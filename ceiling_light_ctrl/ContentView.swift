//
//  ContentView.swift
//  ceiling_light_ctrl
//
//  Created by 马杨 on 2025/4/1.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var colorTemperature: Double = 4000 // 默认色温为 4000K
    @State private var brightness: Double = 50 // 默认亮度为 50%
    @State private var isLightOn: Bool = true // 默认开关状态为开
    @Environment(\.scenePhase) private var scenePhase // 监听应用场景状态

    private let lightController = LightController()

    var body: some View {
        VStack {
            // 顶部标题
            Text("卧室吸顶灯")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 20)

            HStack(alignment: .center) {
                // 开关按钮
                Button(isLightOn ? "Light Off" : "Light On") {
                    isLightOn.toggle()
                    lightController.runPythonScript(command: isLightOn ? "on" : "off")
                }
                .padding()
                .background(isLightOn ? Color.green : Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)

                Spacer()

                // 滑动条部分
                VStack(spacing: 20) {
                    // 色温滑动条
                    VStack {
                        Text("Color Temperature: \(Int(colorTemperature))K")
                            .font(.headline)
                            .padding(.bottom, 10)

                        ZStack {
                            // 刻度线
                            HStack(spacing: 0) {
                                ForEach([2700, 3000, 4000, 5500, 6500], id: \.self) { temp in
                                    VStack {
                                        Rectangle()
                                            .fill(Color.gray)
                                            .frame(width: 1, height: temp == 3000 || temp == 4000 || temp == 5500 ? 20 : 10) // 长线和短线区分
                                        Spacer()
                                    }
                                    if temp != 6500 { // 添加间隔，最后一个刻度不需要 Spacer
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.horizontal)

                            // 滑动条
                            Slider(
                                value: $colorTemperature,
                                in: 2700...6500,
                                step: 100,
                                onEditingChanged: { _ in
                                    lightController.runPythonScript(command: "colortemp", value: Int(colorTemperature))
                                }
                            )
                            .padding()
                        }

                        // 刻度标注
                        HStack(spacing: 0) {
                            ForEach([2700, 3000, 4000, 5500, 6500], id: \.self) { temp in
                                Text("\(temp)K")
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, alignment: .center) // 确保标注与刻度线对齐
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)

                    // 亮度滑动条
                    VStack {
                        Text("Brightness: \(Int(brightness))%")
                            .font(.headline)
                            .padding(.bottom, 10)

                        ZStack {
                            // 刻度线
                            HStack(spacing: 0) {
                                ForEach([0, 20, 40, 60, 80, 100], id: \.self) { level in
                                    VStack {
                                        Rectangle()
                                            .fill(Color.gray)
                                            .frame(width: 1, height: level % 20 == 0 ? 20 : 10) // 长线和短线区分
                                        Spacer()
                                    }
                                    if level != 100 { // 添加间隔，最后一个刻度不需要 Spacer
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.horizontal)

                            // 滑动条
                            Slider(
                                value: $brightness,
                                in: 0...100,
                                step: 5,
                                onEditingChanged: { _ in
                                    lightController.runPythonScript(command: "brightness", value: Int(brightness))
                                }
                            )
                            .padding()
                        }

                        // 刻度标注
                        HStack(spacing: 0) {
                            ForEach([0, 20, 40, 60, 80, 100], id: \.self) { level in
                                Text("\(level)%")
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, alignment: .center) // 确保标注与刻度线对齐
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .onAppear {
            // 调用脚本获取灯的状态
            if let result = lightController.runPythonScript(command: "get"),
                let state = lightController.parseLightState(result: result) {
                    isLightOn = state.isLightOn
                    brightness = state.brightness
                    colorTemperature = state.colorTemperature
            } else {
                print("Failed to fetch light state. Using default values.")
                // 设置默认值
                isLightOn = true
                brightness = 50
                colorTemperature = 4000
                //saveLightStateToDefaults()
            }
            // Reload widget timelines when the app launches
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    


}

#Preview {
    ContentView()
}
