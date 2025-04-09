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
            Text("\(title): \(Int(value))\(unit)")
                .font(.headline)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .center)
            
            GeometryReader { geometry in
                let totalWidth = geometry.size.width - 20 // 留出边距
                let minValue = range.lowerBound
                let maxValue = range.upperBound
                
                ZStack(alignment: .leading) {
                    // 自定义轨道
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2)) // 自定义轨道颜色
                        .frame(height: 4)
                    
                    // 主要刻度线
                    ForEach(marks, id: \.self) { mark in
                        let ratio = CGFloat(mark - Int(minValue)) / CGFloat(maxValue - minValue)
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: 1, height: 12)
                            .offset(x: ratio * totalWidth)
                            .offset(y: -2)
                    }
                    
                    // 滑动条控件
                    Slider(value: $value, in: range, step: Double(step))
                        .accentColor(.blue) // 自定义滑块颜色
                        .padding(.horizontal, 4)
                }
                .frame(height: 30)
                
                // 刻度标签容器
                HStack(spacing: 0) {
                    ForEach(marks, id: \.self) { mark in
                        Text("\(mark)")
                            .font(.system(size: 10))
                            .frame(width: mark == marks.last ? nil : totalWidth / CGFloat(marks.count - 1),
                                   alignment: mark == marks.last ? .trailing : .leading)
                            .offset(x: mark == marks.first ? 2 : (mark == marks.last ? -2 : 0))
                    }
                }
                .padding(.horizontal, 8) // 标签容器边距
                .offset(y: 15)
            }
            .frame(height: 50) // 整体高度控制
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ContentView()
}
