//
//  CeilingLightWidget.swift
//  CeilingLightWidget
//
//  Created by 马杨 on 2025/4/2.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), isLightOn: true, brightness: 50, colorTemperature: 4000)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let defaults = UserDefaults.standard
        let isLightOn = defaults.bool(forKey: "isLightOn")
        let brightness = defaults.integer(forKey: "brightness")
        let colorTemperature = defaults.integer(forKey: "colorTemperature")

        let entry = SimpleEntry(date: Date(), isLightOn: isLightOn, brightness: brightness, colorTemperature: colorTemperature)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let defaults = UserDefaults.standard
        let isLightOn = defaults.bool(forKey: "isLightOn")
        let brightness = defaults.integer(forKey: "brightness")
        let colorTemperature = defaults.integer(forKey: "colorTemperature")

        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, isLightOn: isLightOn, brightness: brightness, colorTemperature: colorTemperature)

        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let isLightOn: Bool
    let brightness: Int
    let colorTemperature: Int
}

struct CeilingLightWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text(entry.isLightOn ? "Light: ON" : "Light: OFF")
                .font(.headline)
                .foregroundColor(entry.isLightOn ? .green : .red)
                .padding(.bottom, 10)

            Text("Brightness: \(entry.brightness)%")
                .font(.caption)
                .padding(.bottom, 5)

            Text("Color Temp: \(entry.colorTemperature)K")
                .font(.caption)
        }
        .padding()
        .containerBackground(Color.blue, for: .widget) // 添加 containerBackground 修饰符
    }
}

struct CeilingLightWidget: Widget {
    let kind: String = "CeilingLightWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CeilingLightWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Ceiling Light Widget")
        .description("Displays the current state of your ceiling light.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
