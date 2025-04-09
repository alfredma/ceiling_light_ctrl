//
//  ContentView.swift
//  ceiling_light_ctrl
//
//  Created by 马杨 on 2025/4/1.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var controller = LightController.shared
    
    var body: some View {
        VStack(spacing: 20) {
            HeaderView()
            PowerButton()
            ControlSliders()
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
}

private struct HeaderView: View {
    var body: some View {
        Text("卧室吸顶灯控制")
            .font(.system(size: 24, weight: .semibold))
            .padding(.bottom, 20)
    }
}

private struct PowerButton: View {
    @ObservedObject var controller = LightController.shared
    
    var body: some View {
        Button(action: controller.togglePower) {
            Text(controller.isOn ? "关闭灯光" : "开启灯光")
                .frame(width: 120)
                .padding(.vertical, 12)
                .background(controller.isOn ? Color.blue : Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct ControlSliders: View {
    @ObservedObject var controller = LightController.shared
    
    var body: some View {
        VStack(spacing: 25) {
            SmartSlider(
                title: "亮度",
                value: $controller.brightness,
                range: 1...100,
                unit: "%",
                marks: [1, 20, 40, 60, 80, 100],
                step: 1
            )
            
            SmartSlider(
                title: "色温",
                value: $controller.colorTemperature,
                range: 2700...6500,
                unit: "K",
                marks: [2700, 3500, 4500, 5500, 6500],
                step: 100
            )
        }
        .padding(.horizontal) // 添加水平内边距
        .frame(maxWidth: .infinity) // 确保宽度扩展
    }
}

struct SmartSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    let marks: [Int]
    let step: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            // 标题
            Text("\(title): \(Int(value))\(unit)")
                .font(.headline)
                .padding(.horizontal)
            
            // 滑动条主体
            GeometryReader { geometry in
                let sliderWidth = geometry.size.width
                
                VStack(spacing: 4) {
                    // 滑动条控件
                    Slider(
                        value: $value,
                        in: range,
                        step: Double(step),
                    )
                    
                    // 刻度标签容器（关键修改）
                    HStack(spacing: 0) {
                        ForEach(marks, id: \.self) { mark in
                            Text("\(mark)")
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading) // 均匀分布
                        }
                    }
                    .padding(.horizontal, 4) // 补偿滑动条边距
                }
                .frame(width: sliderWidth) // 强制使用完整宽度
            }
            .frame(height: 40) // 固定高度
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity) // 关键：横向充满容器
    }
}

#Preview {
    ContentView()
}
