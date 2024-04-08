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
    let temp: String
    let humidity: String
    let wind360: String
    let windSpeed: String
    let dew: String
}

func calculateBackSouthProbability(hourlyData: HourlyData) -> Double {
    
    let temperatureThreshold = 10.0
    let humidityThreshold = 0.80
    let windSpeedThreshold = 0.5
    let southWindDirection = 135..<225

    let temperature = Double(hourlyData.temp)!
    let humidity = Double(hourlyData.humidity)!
    let windSpeed = Double(hourlyData.windSpeed)!
    let wind360 = Int(hourlyData.wind360)!
    let dew = Double(hourlyData.dew)!

    let temperatureScore = temperature >= temperatureThreshold ? 1.0 : 0.0
    let humidityScore = humidity >= humidityThreshold ? 1.0 : 0.0
    let windSpeedScore = windSpeed <= windSpeedThreshold * 10.0 ? 1.0 : 0.0
    let windDirectionScore = southWindDirection.contains(wind360) ? 1.0 : 0.0
    let dewScore = dew > temperature ? 1.0 : 0.0

    let totalScore = temperatureScore + humidityScore + windSpeedScore + windDirectionScore + dewScore
    let probability = min(totalScore / 5.0, 1.0)

    return probability
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), hourlyData: HourlyData(fxTime: "", temp: "", humidity: "", wind360: "", windSpeed: "", dew: ""))
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration, hourlyData: HourlyData(fxTime: "", temp: "", humidity: "", wind360: "", windSpeed: "", dew: ""))
    }

    struct SimpleEntry: TimelineEntry {
        let date: Date
        let configuration: ConfigurationAppIntent
        let hourlyData: HourlyData
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let url = URL(string: "http://localhost:3000/114.73,22.79")!
        let (data, _) = try! await URLSession.shared.data(from: url)
        let weatherData = try! JSONDecoder().decode(WeatherData.self, from: data)

        let now = Date()
        let currentHour = Calendar.current.component(.hour, from: now)

        print("Current time: \(now)")
        print("Current hour (UTC): \(currentHour)")

        if let currentHumidityIndex = weatherData.hourly.firstIndex(where: { $0.fxTime.contains("\(currentHour):00") }) {
            let currentEntry = SimpleEntry(date: now, configuration: configuration, hourlyData: weatherData.hourly[currentHumidityIndex])

            print("Found matching hourly data:")
            print("  fxTime: \(currentEntry.hourlyData.fxTime)")
            print("  Humidity: \(currentEntry.hourlyData.humidity)%")

            return Timeline(entries: [currentEntry], policy: .atEnd)
        } else {
            let emptyEntry = SimpleEntry(date: now, configuration: configuration, hourlyData: HourlyData(fxTime: "", temp: "", humidity: "", wind360: "", windSpeed: "", dew: ""))
            return Timeline(entries: [emptyEntry], policy: .atEnd)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let humidity: String
}


struct widgetEntryView : View {
    var entry: Provider.SimpleEntry

    var body: some View {
        ZStack {
            Color.white

            VStack(alignment: .leading) {
                    HStack {
                        if Int(calculateBackSouthProbability(hourlyData: entry.hourlyData) * 100) <= 20 {
                            Image("x_x")
                                .frame(width: 89)
                                .foregroundColor(.white)
                        } else {
                            Image("^——^")
                                .frame(width: 89)
                                .foregroundColor(.white)
                        }
                        Image("\(Int(calculateBackSouthProbability(hourlyData: entry.hourlyData) * 100))")
                            .frame(width: 32,height: 49)
                            .foregroundColor(.white)
                    }
                    Text("现在开窗感受")
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
                    Text("朝云暮雨")
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
                            Text(entry.hourlyData.humidity + "%")
                        }
                        .bold()
                        .foregroundColor(Color(red: 98/255, green: 98/255, blue: 98/255))
                        VStack(alignment: .leading) {
                            Text("概率")
                            Text("\(Int(calculateBackSouthProbability(hourlyData: entry.hourlyData) * 100))%")
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
