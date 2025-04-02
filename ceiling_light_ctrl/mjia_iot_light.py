import socket
import argparse
import select
import sys

# Yeelight 智能灯的 IP 地址和端口
DEVICE_IP = "192.168.31.123"  # 替换为您的设备 IP
DEVICE_PORT = 55443

# 打印调试信息到标准错误流
def debug_print(message):
    print(message, file=sys.stderr)

# 发送命令到设备
def send_command(command):
    sock = None
    try:
        # 创建一个 TCP 连接
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        #sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)  # 禁用 Nagle 算法
        #sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)  # 允许地址重用
        sock.settimeout(2)  # 设置超时时间为 1 秒
        debug_print(f"尝试连接到设备 {DEVICE_IP}:{DEVICE_PORT}...")
        sock.connect((DEVICE_IP, DEVICE_PORT))
        sock.send((command + "\r\n").encode("utf-8"))
        #sock.sendall((command + "\r\n").encode("utf-8"))
        sock.send(b" ")  # workaround发送一个空字节
        debug_print(f"发送命令: {command.strip()}")
        
        # 使用 select 检查是否有数据可读
        ready = select.select([sock], [], [], 2)  # 超时时间为 2 秒
        if ready[0]:
            response = sock.recv(1024).decode("utf-8").strip()
            debug_print(f"Response: {response}")
            return response
        else:
            debug_print("设备未返回数据，但命令可能已成功执行")
            return None
    except socket.error as e:
        debug_print(f"连接失败: {e}")
        return None
    finally:
        if sock:
            sock.close()
            debug_print("关闭连接")

# 打开灯光
def turn_on_light():
    print("正在打开灯光...")
    turn_on_command = '{"id":1,"method":"set_power","params":["on","smooth",500]}'
    send_command(turn_on_command)

# 关闭灯光
def turn_off_light():
    print("正在关闭灯光...")
    turn_off_command = '{"id":1,"method":"set_power","params":["off","smooth",500]}'
    send_command(turn_off_command)

# 设置亮度
def set_brightness(brightness):
    if 1 <= brightness <= 100:
        print(f"正在设置亮度为 {brightness}...")
        brightness_command = f'{{"id":1,"method":"set_bright","params":[{brightness},"smooth",500]}}'
        send_command(brightness_command)
    else:
        print("Error: 亮度值必须在 1 到 100 之间")

# 设置颜色（RGB）
def set_color(red, green, blue):
    print(f"正在设置颜色为 RGB({red}, {green}, {blue})...")
    rgb = (red << 16) | (green << 8) | blue
    color_command = f'{{"id":1,"method":"set_rgb","params":[{rgb},"smooth",500]}}'
    send_command(color_command)

# 设置色温
def set_color_temperature(ct_value):
    if 1700 <= ct_value <= 6500:
        print(f"正在设置色温为 {ct_value}K...")
        ct_command = f'{{"id":1,"method":"set_ct_abx","params":[{ct_value},"smooth",500]}}'
        send_command(ct_command)
    else:
        print("Error: 色温值必须在 1700 到 6500 之间")

# 获取灯的当前状态
def get_properties():
    debug_print("正在获取灯的当前状态...")
    get_command = '{"id":1,"method":"get_prop","params":["power","bright","ct"]}'
    response = send_command(get_command)
    if response:
        try:
            # 解析返回的 JSON 数据
            import json
            data = json.loads(response)
            if "result" in data:
                result = data["result"]
                power = result[0]
                brightness = result[1]
                color_temp = result[2]
                
                # 构造返回的 JSON 数据
                result_json = {
                    "power": power,
                    "brightness": brightness,
                    "color_temp": color_temp
                }
                return json.dumps(result_json)  # 返回 JSON 格式的结果
            else:
                debug_print("Error: 无法解析设备返回的数据")
                return json.dumps({"error": "无法解析设备返回的数据"})
        except json.JSONDecodeError:
            debug_print("Error: 返回的数据不是有效的 JSON")
            return json.dumps({"error": "返回的数据不是有效的 JSON"})
    else:
        debug_print("Error: 未收到设备的响应")
        return json.dumps({"error": "未收到设备的响应"})

# 主函数，解析命令行参数
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="控制米家智能灯的功能")
    parser.add_argument(
        "action",
        choices=["on", "off", "brightness", "color", "colortemp", "get"],
        help="选择操作：'on' 打开灯光，'off' 关闭灯光，'brightness' 设置亮度，'color' 设置颜色，'colortemp' 设置色温，'get' 获取当前状态"
    )
    parser.add_argument(
        "--value",
        type=int,
        help="亮度值 (1-100)、色温值 (1700-6500) 或 RGB 颜色值 (0-255)"
    )
    parser.add_argument(
        "--red", type=int, help="红色值 (0-255)", default=0
    )
    parser.add_argument(
        "--green", type=int, help="绿色值 (0-255)", default=0
    )
    parser.add_argument(
        "--blue", type=int, help="蓝色值 (0-255)", default=0
    )
    args = parser.parse_args()

    if args.action == "on":
        turn_on_light()
    elif args.action == "off":
        turn_off_light()
    elif args.action == "brightness":
        if args.value is not None:
            set_brightness(args.value)
        else:
            print("Error: 请提供亮度值 (--value)")
    elif args.action == "color":
        set_color(args.red, args.green, args.blue)
    elif args.action == "colortemp":
        if args.value is not None:
            set_color_temperature(args.value)
        else:
            print("Error: 请提供色温值 (--value)")
    elif args.action == "get":
        print(get_properties())  # 确保返回值被打印到标准输出
