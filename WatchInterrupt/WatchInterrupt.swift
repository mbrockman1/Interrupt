import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry { SimpleEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) { completion(SimpleEntry(date: Date())) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        completion(Timeline(entries: [SimpleEntry(date: Date())], policy: .never))
    }
}

struct SimpleEntry: TimelineEntry { let date: Date }

struct ComplicationView: View {
    var body: some View {
        Image(systemName: "hand.raised.fill")
            .widgetAccentable()
    }
}

struct InterruptComplication: Widget {
    let kind: String = "InterruptComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ComplicationView()
        }
        .configurationDisplayName("Quick Interrupt")
        .supportedFamilies([.accessoryCircular]) // Only support circular for now to be safe
    }
}
