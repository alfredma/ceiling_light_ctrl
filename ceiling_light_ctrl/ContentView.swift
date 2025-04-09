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
                marks: [1, 25, 50, 75, 100]
            )
            
            SmartSlider(
                title: "色温",
                value: $controller.colorTemperature,
                range: 1700...6500,
                unit: "K",
                marks: [1700, 3000, 4300, 5500, 6500]
            )
        }
    }
}

struct SmartSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    let marks: [Int]
    
    var body: some View {
        VStack {
            Text("\(title): \(Int(value))\(unit)")
                .font(.headline)
            
            Slider(
                value: $value,
                in: range,
                step: (range.upperBound - range.lowerBound)/100
            )
            .padding(.horizontal)
            
            HStack {
                ForEach(marks, id: \.self) { mark in
                    Text("\(mark)")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    ContentView()
}
