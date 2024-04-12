//
//  widget.swift
//  widget
//
//  Created by Akiage on 2024/3/21.
//

import WidgetKit
import SwiftUI
import Foundation

struct WeatherData: Codable {
    let hourly: [HourlyData]
}

/*  https://dev.qweather.com/docs/api/grid-weather/grid-weather-hourly-forecast/
 *  fxLink          数据时间
 *  temp            温度单位摄氏度
 *  humidity        相对湿度
 *  wind360         风向 360 角度
 *  windSpeed       风速，公里 / 小时
 *  dew             露点温度
 *  text            天气状况的文字描述
 *  windScale       风力等级
 *  cloud           云量
 *  precip          降雨量
 */

struct HourlyData: Codable {
    let fxTime: String
    let temp: String
    let humidity: String
    let wind360: String
    let windSpeed: String
    let dew: String
    let text: String
    let windScale: String
    let cloud : String
    let precip : String
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
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), hourlyData: HourlyData(fxTime: "", temp: "", humidity: "", wind360: "", windSpeed: "", dew: "", text: "", windScale: "", cloud: "", precip: ""))
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration, hourlyData: HourlyData(fxTime: "", temp: "", humidity: "", wind360: "", windSpeed: "", dew: "", text: "", windScale: "", cloud: "", precip: ""))
    }

    struct SimpleEntry: TimelineEntry {
        let date: Date
        let configuration: ConfigurationAppIntent
        let hourlyData: HourlyData
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {

        var weatherUrl: URL?
        if let userDefaults = UserDefaults(suiteName: "group.com.cc.nospring"),
           let unwrappedLongitude = userDefaults.string(forKey: "longitude"),
           let unwrappedLatitude = userDefaults.string(forKey: "latitude") {
            let coordinates = "\(unwrappedLongitude),\(unwrappedLatitude)"
            weatherUrl = URL(string: "http://localhost:3000/\(coordinates)")!
        } else {
            print("No saved longitude and/or latitude.")
            return Timeline(entries: [], policy: .never)
        }

        guard let url = weatherUrl else {
            return Timeline(entries: [], policy: .never)
        }
        
        let (data, _) = try! await URLSession.shared.data(from: url)
        let weatherData = try! JSONDecoder().decode(WeatherData.self, from: data)
        

        let now = Date()
        let currentHour = Calendar.current.component(.hour, from: now)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH"
        let formattedCurrentHour = formatter.string(from: now)

        if let currentHumidityIndex = weatherData.hourly.firstIndex(where: { $0.fxTime.contains("\(formattedCurrentHour):00") }) {
            let currentEntry = SimpleEntry(date: now, configuration: configuration, hourlyData: weatherData.hourly[currentHumidityIndex])
            return Timeline(entries: [currentEntry], policy: .atEnd)
        } else {
            let emptyEntry = SimpleEntry(date: now, configuration: configuration, hourlyData: HourlyData(fxTime: "", temp: "", humidity: "", wind360: "", windSpeed: "", dew: "", text: "", windScale: "", cloud: "", precip: ""))
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
                    Text(determineTextForConditions(entry.hourlyData))
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
    
    private func determineTextForConditions(_ hourlyData: HourlyData) -> String {
        if isCloudyMoistWeatherConditions(hourlyData) {
            return "云布雨润"
        }
        else if isSpringRainyWeatherConditions(hourlyData) {
            return "春风化雨"
        } else if isDesiredWeatherConditions(hourlyData) {
            return "风和日丽"
        } else {
            return "听天由命"
        }
    }
    // is spring?
    func isCurrentSeasonSpring() -> Bool {
        let currentDate = Date()
        let calendar = Calendar(identifier: .gregorian)

        let currentYear = calendar.component(.year, from: currentDate)

        // 定义春分和夏至的日期
        let springEquinox = calendar.date(from: DateComponents(year: currentYear, month: 3, day: 20))!
        let summerSolstice = calendar.date(from: DateComponents(year: currentYear, month: 6, day: 21))!

        // 判断当前日期是否在春分与夏至之间
        return currentDate >= springEquinox && currentDate < summerSolstice
    }

    // 云布雨润：多云、湿度 80~100%、温度 15~25、露点接近或略低于气温、无雨或微量雨（0或0.1毫米）、风速 0~3级
    private func isCloudyMoistWeatherConditions(_ hourlyData: HourlyData) -> Bool {
        let isCloudy = hourlyData.text == "多云"
        let humidityInRange = Int(hourlyData.humidity)! >= 80 && Int(hourlyData.humidity)! <= 100
        let tempInRange = Double(hourlyData.temp)! >= 15 && Double(hourlyData.temp)! <= 25
        let dewNearTemp = abs(Double(hourlyData.temp)! - Double(hourlyData.dew)!) <= 2
        let lightOrNoPrecipitation = Double(hourlyData.precip)! == 0 || (Double(hourlyData.precip)! >= 0 && Double(hourlyData.precip)! <= 0.1)
        let windSpeedInRange = Int(hourlyData.windSpeed)! >= 0 && Int(hourlyData.windSpeed)! <= 3

        return isCloudy && humidityInRange && tempInRange && dewNearTemp && lightOrNoPrecipitation && windSpeedInRange
    }
    
    // 春风化雨：有0.1至25毫米的降雨量，风力为0~3级，湿度30~50%，且为晴或多云天气
    private func isSpringRainyWeatherConditions(_ hourlyData: HourlyData) -> Bool {
        let isSpring = isCurrentSeasonSpring()
        let isLightRainfall = Double(hourlyData.precip)! >= 0.1 && Double(hourlyData.precip)! <= 25
        let isClearToCloudy = hourlyData.text == "晴" || hourlyData.text == "多云"

        return isSpring && isLightRainfall && isClearToCloudy && isDesiredWeatherConditions(hourlyData)
    }
    
    //  风和日丽：晴天、无风~微风（0-3)、湿度 30~50
    private func isDesiredWeatherConditions(_ hourlyData: HourlyData) -> Bool {
        let isClearSky = hourlyData.text == "晴"
        let windScaleInRange = Int(hourlyData.windScale)! >= 0 && Int(hourlyData.windScale)! <= 3
        let humidityInRange = Int(hourlyData.humidity)! >= 30 && Int(hourlyData.humidity)! <= 50

        return isClearSky && windScaleInRange && humidityInRange
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
