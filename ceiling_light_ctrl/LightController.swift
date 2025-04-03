import Foundation

class LightController {
    // Properties to store light state
    var isLightOn: Bool = false
    var brightness: Double = 50.0
    var colorTemperature: Double = 4000.0
    
    // 解析灯的状态
    func parseLightState(result: String) -> (isLightOn: Bool, brightness: Double, colorTemperature: Double)? {
        if let data = result.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let power = json["power"] as? String,
                       let brightnessValue = json["brightness"] as? String,
                       let colorTempValue = json["color_temp"] as? String {
                        
                        // 更新类的成员变量
                        self.isLightOn = (power == "on")
                        self.brightness = Double(brightnessValue) ?? 50.0
                        self.colorTemperature = Double(colorTempValue) ?? 4000.0
                        
                        // 保存状态到 UserDefaults
                        saveLightStateToDefaults()
                        
                        // 返回解析结果
                        return (
                            isLightOn: self.isLightOn,
                            brightness: self.brightness,
                            colorTemperature: self.colorTemperature
                        )
                    }
                }
            } catch {
                print("Failed to parse JSON: \(error). Input result: \(result)")
            }
        }
        return nil
    }

    func saveLightStateToFile() {
        let fileManager = FileManager.default
        if let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentDirectory.appendingPathComponent("lightState.json")
            let lightState: [String: Any] = [
                "isLightOn": isLightOn,
                "brightness": brightness,
                "colorTemperature": colorTemperature
            ]
            do {
                let data = try JSONSerialization.data(withJSONObject: lightState, options: [.prettyPrinted])
                try data.write(to: fileURL)
                print("Light state saved to file: \(fileURL)")
            } catch {
                print("Failed to save light state to file: \(error)")
            }
        } else {
            print("Failed to get document directory.")
        }
    }

    func saveLightStateToDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(self.isLightOn, forKey: "isLightOn")
        defaults.set(self.brightness, forKey: "brightness")
        defaults.set(self.colorTemperature, forKey: "colorTemperature")
        print("Light state saved to UserDefaults.")
        
        // 保存到共享文件
        saveLightStateToFile()
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

    // 调用嵌入的可执行文件的函数
    func runEmbeddedExecutable(command: String, value: Int? = nil) -> String? {
        let process = Process()
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe

        // 获取嵌入的可执行文件路径
        guard let executablePath = Bundle.main.path(forResource: "mjia_iot_light", ofType: nil) else {
            print("错误：未找到嵌入的可执行文件")
            return nil
        }

        process.executableURL = URL(fileURLWithPath: executablePath)
        var arguments = [command]
        if let value = value {
            arguments.append(contentsOf: ["--value", "\(value)"])
        }
        process.arguments = arguments

        do {
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                print("可执行文件错误: \(errorMessage)")
                return nil
            }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            print("执行失败: \(error)")
            return nil
        }
    }

    func getCurrentBrightness() -> Double {
        return brightness
    }

    func getCurrentColorTemperature() -> Double {
        return colorTemperature
    }
}