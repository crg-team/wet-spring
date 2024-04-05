//
//  widget.swift
//  widget
//
//  Created by Akiage on 2024/3/21.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

struct widgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            Color.white

            VStack(alignment: .leading) {
                    Image("WidgetBackground")
                        .frame(height: 49.18)
                        .foregroundColor(.white)
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
                        .padding(.top, 1)
                    HStack {
                        Image("100")
                        VStack(alignment: .leading) {
                            HStack {
                                Text("潮湿度")
                                Text("评分")
                            }
                            .bold()
                            .foregroundColor(Color(red: 98/255, green: 98/255, blue: 98/255))
                            .padding(.top, 0.5)

                            HStack {
                                Text("56.1%")
                                Text("87%")
                            }
                            .bold()
                            .foregroundColor(Color(red: 98/255, green: 98/255, blue: 98/255))
                        }
                    }
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
