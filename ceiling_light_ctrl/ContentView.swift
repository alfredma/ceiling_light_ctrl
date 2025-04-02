//
//  ContentView.swift
//  ceiling_light_ctrl
//
//  Created by 马杨 on 2025/4/1.
//

import SwiftUI

struct ContentView: View {
    @State private var colorTemperature: Double = 4000 // 默认色温为 4000K
    @State private var brightness: Double = 50 // 默认亮度为 50%
    @State private var isLightOn: Bool = true // 默认开关状态为开
    @Environment(\.scenePhase) private var scenePhase // 监听应用场景状态

    var body: some View {
        VStack {
            // 设置标题
            Text("卧室吸顶灯")
                .font(.largeTitle)
                .padding(.bottom, 20)
            
            // 按钮和色温滑动条左右展示
            HStack {
                // 开灯按钮
                Button(isLightOn ? "Light Off" : "Light On") {
                    isLightOn.toggle()
                    runPythonScript(command: isLightOn ? "on" : "off")
                }
                .padding()
                
                Spacer()
                
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
                                runPythonScript(command: "colortemp", value: Int(colorTemperature))
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
            }
            .padding()
            
            // 按钮和亮度滑动条左右展示
            HStack {
                Spacer()
                
                // 亮度调节滑动条
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
                                runPythonScript(command: "brightness", value: Int(brightness))
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
            .padding()
        }
        .padding()
        .onAppear {
            // 调用脚本获取灯的状态
            if let result = runPythonScript(command: "get") {
                parseLightState(result: result)
            } else {
                print("Failed to fetch light state. Using default values.")
                // 设置默认值
                isLightOn = true
                brightness = 50
                colorTemperature = 4000
                saveLightStateToDefaults()
            }
        }
    }
    
    // 调用外部 Python 脚本的函数
    func runPythonScript_ext(command: String, value: Int? = nil) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3") // 确保 Python3 路径正确
        var arguments = ["/Volumes/macdisk/workspace/myprj/pytest/mjia_iot_light.py", command]
        if let value = value {
            arguments.append("--value")
            arguments.append("\(value)")
        }
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            print("Failed to run Python script: \(error)")
            return nil
        }
    }
    // 调用内嵌Python 脚本的函数
    func runPythonScript(command: String, value: Int? = nil) -> String? {
        let process = Process()
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe
        
        // 使用嵌入的 Python 脚本路径
        guard let scriptPath = Bundle.main.path(forResource: "mjia_iot_light", ofType: "py") else {
            print("错误：未找到 Python 脚本")
            return nil
        }
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        var arguments = [scriptPath, command]
        
        if let value = value {
            arguments.append(contentsOf: ["--value", "\(value)"])
        }
        process.arguments = arguments
        
        do {
            try process.run()
            process.waitUntilExit()
            
            // 检查执行状态
            guard process.terminationStatus == 0 else {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                print("Python脚本错误: \(errorMessage)")
                return nil
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            print("执行失败: \(error)")
            return nil
        }
    }
    
    // 解析灯的状态
    func parseLightState(result: String) {
        if let data = result.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let power = json["power"] as? String,
                       let brightnessValue = json["brightness"] as? String,
                       let colorTempValue = json["color_temp"] as? String {
                        // 更新 SwiftUI 的状态
                        isLightOn = (power == "on")
                        brightness = Double(brightnessValue) ?? 50
                        colorTemperature = Double(colorTempValue) ?? 4000
                        
                        // 保存状态到 UserDefaults
                        saveLightStateToDefaults()
                    }
                }
            } catch {
                print("Failed to parse JSON: \(error)")
            }
        }
    }

    func saveLightStateToDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(isLightOn, forKey: "isLightOn")
        defaults.set(brightness, forKey: "brightness")
        defaults.set(colorTemperature, forKey: "colorTemperature")
        print("Light state saved to UserDefaults.")
    }
}

#Preview {
    ContentView()
}
