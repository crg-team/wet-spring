//
//  widget.swift
//  widget
//
//  Created by Akiage on 2024/3/21.
//

import WidgetKit
import SwiftUI
import CoreLocation

struct WeatherData: Codable {
    let hourly: [HourlyData]
}

struct HourlyData: Codable {
    let fxTime: String
    let humidity: String
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), humidity: "N/A")
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration, humidity: "N/A")
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        
        let url = URL(string: "http://localhost:3000/")!
        let (data, _) = try! await URLSession.shared.data(from: url)
        let weatherData = try! JSONDecoder().decode(WeatherData.self, from: data)
        
        let now = Date()
        let currentHour = Calendar.current.component(.hour, from: now)
        
        if let currentHumidityIndex = weatherData.hourly.firstIndex(where: { $0.fxTime.contains("\(currentHour):00") }) {
            let currentEntry = SimpleEntry(date: now, configuration: configuration, humidity: weatherData.hourly[currentHumidityIndex].humidity)
            entries.append(currentEntry)
        }
        
        for hourOffset in 1...4 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: now)!
            
            if let nextHourHumidityIndex = weatherData.hourly.firstIndex(where: { $0.fxTime.contains("\(currentHour + hourOffset):00") }) {
                let entry = SimpleEntry(date: entryDate, configuration: configuration, humidity: weatherData.hourly[nextHourHumidityIndex].humidity)
                entries.append(entry)
            } else {
                let entry = SimpleEntry(date: entryDate, configuration: configuration, humidity: "N/A")
                entries.append(entry)
            }
        }
        
        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let humidity: String
}


struct widgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            Color.white

            VStack(alignment: .leading) {
                    HStack {
                        Image("Emoji")
                            .frame(width: 89)
                            .foregroundColor(.white)
                        Image("100")
                            .frame(width: 32,height: 49)
                            .foregroundColor(.white)
                    }
                    Text("现在开窗体验")
                        .font(Font.system(size: 12, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 156/255, green: 156/255, blue: 156/255),
                                    Color(red: 54/255, green: 54/255, blue: 54/255)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("如沫春风")
                        .font(Font.system(size: 24, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 156/255, green: 156/255, blue: 156/255),
                                    Color(red: 54/255, green: 54/255, blue: 54/255)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .bold()
                        .foregroundColor(Color(red: 98/255, green: 98/255, blue: 98/255))
                        .foregroundColor(.black)
                    HStack {
                        VStack(alignment: .leading) {
                            Text("潮湿度")
                            Text(entry.humidity + "%")
                        }
                        .bold()
                        .foregroundColor(Color(red: 98/255, green: 98/255, blue: 98/255))
                        VStack(alignment: .leading) {
                            Text("评分")
                            Text("87%")
                        }
                        .bold()
                        .foregroundColor(Color(red: 98/255, green: 98/255, blue: 98/255))
                    }
                    .padding(.top, 0.5)
                }
            .padding()
            .background(Color.white)
        }
        .edgesIgnoringSafeArea(.all)
        .background(Color.white)
    }
}

struct widget: Widget {
    let kind: String = "widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            widgetEntryView(entry: entry)
                .containerBackground(.white, for: .widget)
        }
    }
    
}
