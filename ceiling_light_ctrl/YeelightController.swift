import Foundation
import Network

class YeelightController {
    static let shared = YeelightController()
    private let deviceIP = "192.168.31.123" // 替换为您的设备 IP
    private let devicePort: UInt16 = 55443

    private init() {}

    // 发送命令到设备
    private func sendCommand(_ command: String, timeout: TimeInterval = 1.0) -> String? {
        print("Sending command: \(command)")
        var response: String?
        let socketFD = socket(AF_INET, SOCK_STREAM, 0)
        guard socketFD >= 0 else {
            print("Failed to create socket.")
            return nil
        }

        var serverAddress = sockaddr_in()
        serverAddress.sin_family = sa_family_t(AF_INET)
        serverAddress.sin_port = in_port_t(devicePort).bigEndian
        inet_pton(AF_INET, deviceIP, &serverAddress.sin_addr)

        let connectResult = withUnsafePointer(to: &serverAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(socketFD, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        guard connectResult >= 0 else {
            print("Failed to connect to server.")
            close(socketFD)
            return nil
        }

        let commandData = (command + "\r\n").data(using: .utf8)!
        let sendResult = commandData.withUnsafeBytes {
            send(socketFD, $0.baseAddress, $0.count, 0)
        }

        guard sendResult >= 0 else {
            print("Failed to send command.")
            close(socketFD)
            return nil
        }

        let emptyCommandData = " ".data(using: .utf8)!
        let emptySendResult = emptyCommandData.withUnsafeBytes {
            send(socketFD, $0.baseAddress, $0.count, 0)
        }

        guard emptySendResult >= 0 else {
            print("Failed to send empty command.")
            close(socketFD)
            return nil
        }

        // Set timeout for receiving data
        var tv = timeval(tv_sec: Int(timeout), tv_usec: 0)
        setsockopt(socketFD, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))

        var buffer = [UInt8](repeating: 0, count: 1024)
        let receiveResult = recv(socketFD, &buffer, buffer.count, 0)

        if receiveResult > 0 {
            response = String(bytes: buffer[0..<receiveResult], encoding: .utf8)
            print("Received response: \(response ?? "")")
        } else if receiveResult == 0 {
            print("Connection closed by server.")
        } else {
            print("Failed to receive response or operation timed out.")
        }

        close(socketFD)
        return response
    }

    // 打开灯光
    func turnOnLight() {
        let command = "{\"id\":1,\"method\":\"set_power\",\"params\":[\"on\",\"smooth\",500]}"
        _ = sendCommand(command)
    }

    // 关闭灯光
    func turnOffLight() {
        let command = "{\"id\":1,\"method\":\"set_power\",\"params\":[\"off\",\"smooth\",500]}"
        _ = sendCommand(command)
    }

    // 设置亮度
    func setBrightness(_ brightness: Int) {
        guard brightness >= 1 && brightness <= 100 else {
            print("Brightness must be between 1 and 100.")
            return
        }
        let command = "{\"id\":1,\"method\":\"set_bright\",\"params\":[\(brightness),\"smooth\",500]}"
        _ = sendCommand(command)
    }

    // 设置色温
    func setColorTemperature(_ temperature: Int) {
        guard temperature >= 1700 && temperature <= 6500 else {
            print("Color temperature must be between 1700 and 6500.")
            return
        }
        let command = "{\"id\":1,\"method\":\"set_ct_abx\",\"params\":[\(temperature),\"smooth\",500]}"
        _ = sendCommand(command)
    }

    // 获取灯的状态
    func getProperties() -> (power: String, brightness: Int, colorTemperature: Int)? {
        let command = "{\"id\":1,\"method\":\"get_prop\",\"params\":[\"power\",\"bright\",\"ct\"]}"
        if let response = sendCommand(command) {
            do {
                if let data = response.data(using: .utf8),
                   let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let result = json["result"] as? [String] {
                    let power = result[0]
                    let brightness = Int(result[1]) ?? 50
                    let colorTemperature = Int(result[2]) ?? 4000
                    return (power, brightness, colorTemperature)
                }
            } catch {
                print("Failed to parse response: \(error)")
            }
        }
        return nil
    }
}