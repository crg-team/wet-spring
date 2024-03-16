import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusBarItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem?.button {
            
            guard let image = NSImage(named: "StatusBar") else { return }
            button.image = image
            
            // 获取并设置天气数据
            fetchWeatherData { weather in
                DispatchQueue.main.async {
                    let score = self.calculateWeatherScore(weather: weather)
                    button.title = "湿度: \(weather.humidity)%"
                }
            }
        }
    }
    
    
    func fetchWeatherData(completion: @escaping (HourlyData) -> Void) {
        let url = URL(string: "")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let weatherData = try decoder.decode(WeatherData.self, from: data)
                    
                    // 计算平均湿度和温度
                    let totalHumidity = weatherData.hourly.reduce(0) { $0 + Double($1.humidity)! }
                    let averageHumidity = totalHumidity / Double(weatherData.hourly.count)
                    
                    // 获取天气描述文本
                    let averageTemp = weatherData.hourly.reduce(0) { $0 + Double($1.temp)! } / Double(weatherData.hourly.count)
                    let weatherText = weatherData.hourly.first?.text ?? ""
                    
                    // 平均湿度、温度和天气
                    completion(HourlyData(humidity: String(format: "%.1f", averageHumidity), temp: String(format: "%.1f", averageTemp), text: weatherText))
                } catch {
                    print("Failed to decode JSON: \(error)")
                }
            } else if let error = error {
                print("Failed to fetch data: \(error)")
            }
        }
        task.resume()
    }
    
    func calculateWeatherScore(weather: HourlyData) -> Int {
        
        /*  开窗指数建模
         humidityScore  设湿度 30% 是最合适的开窗时机
         tempScore      设 29°C 是最阳光正盛之际
         weatherScore   天气指数
         
         TODE: 室外温度、室内温度、24 小时状态平均值
        */
        let humidityScore = 100 - abs(Double(weather.humidity)! - 30)
        let tempScore = 100 - abs(Double(weather.temp)! - 29)
        let weatherScore: Int
        
        switch weather.text {
        case "晴":
            weatherScore = 100
        case "阴", "多云":
            weatherScore = 80
        case "雨", "雪":
            weatherScore = 50
        default:
            weatherScore = 70
        }
        return Int((humidityScore + tempScore + Double(weatherScore)) / 3.0)
    }
}

struct WeatherData: Codable {
    let hourly: [HourlyData]
}

/*
 humidity   相对湿度百分比字符串
 temp       温度字符串
 text       天气描述
*/

struct HourlyData: Codable {
    let humidity: String
    let temp: String
    let text: String
}
