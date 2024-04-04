import AppKit
import CoreLocation

class AppDelegate: NSObject, NSApplicationDelegate, CLLocationManagerDelegate {

    var statusBarItem: NSStatusItem?
    var locationManager: CLLocationManager?
    var locality: String?
    var subLocality: String?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem?.button {
            
            guard let image = NSImage(named: "StatusBar") else { return }
            button.image = image
            
            // location
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            locationManager?.startUpdatingLocation()
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let latitude = String(format: "%.2f", location.coordinate.latitude)
            let longitude = String(format: "%.2f", location.coordinate.longitude)
            
            self.fetchWeatherData(latitude: latitude, longitude: longitude) { weather in
                DispatchQueue.main.async {
                    self.statusBarItem?.button?.title = "湿度: \(weather.humidity)%"
                }
            }
            
            manager.stopUpdatingLocation()
        }
    }
    
    func fetchWeatherData(latitude: String, longitude: String, completion: @escaping (HourlyData) -> Void) {
        let urlString = "http://localhost:3000/\(longitude),\(latitude)"
        guard let url = URL(string: urlString) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let weatherData = try decoder.decode(WeatherData.self, from: data)
                    
                    // 计算平均湿度和温度
                    let totalHumidity = weatherData.hourly.reduce(0) { $0 + Double($1.humidity)! }
                    let averageHumidity = totalHumidity / Double(weatherData.hourly.count)
                    
                    let averageTemp = weatherData.hourly.reduce(0) { $0 + Double($1.temp)! } / Double(weatherData.hourly.count)
                    
                    completion(HourlyData(humidity: String(format: "%.1f", averageHumidity), temp: String(format: "%.1f", averageTemp)))
                } catch {
                    print("Failed to decode JSON: \(error)")
                }
            } else if let error = error {
                print("Failed to fetch data: \(error)")
            }
        }
        task.resume()
    }
}

struct WeatherData: Codable {
    let hourly: [HourlyData]
}

/*
 humidity   相对湿度百分比字符串
 temp       温度字符串
*/

struct HourlyData: Codable {
    let humidity: String
    let temp: String
}
