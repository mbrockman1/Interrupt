import SwiftUI
import SwiftData
import Charts


struct AnalyticsView: View {
    @Query(sort: \InterruptLog.timestamp, order: .reverse) private var allLogs: [InterruptLog]
    @State private var selectedDate = Date()
    @State private var showingCalendarSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 1. The Compact Date Navigator
                HStack {
                    Button(action: { moveDate(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                            .padding(8)
                    }
                    
                    Spacer()
                    
                    Button(action: { showingCalendarSheet = true }) {
                        Text(formattedDate)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    Button(action: { moveDate(by: 1) }) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                // Use this syntax for semantic colors that work in both Light/Dark mode
                                .foregroundStyle(isToday ? Color(uiColor: .tertiaryLabel) : Color.accentColor)
                                .padding(8)
                        }
                        .disabled(isToday)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(uiColor: .systemGroupedBackground))
                
                // 2. The Scrollable Content
                ScrollView {
                    VStack(spacing: 20) {
                        let dailyLogs = allLogs.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: selectedDate) }
                        
                        // Daily Total
                        GroupBox {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Interrupts on this day")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text("\(dailyLogs.count)")
                                        .font(.system(size: 40, weight: .bold, design: .rounded))
                                }
                                Spacer()
                                Image(systemName: "bolt.shield.fill")
                                    .font(.system(size: 30))
                                    .foregroundStyle(Color.accentColor.gradient)
                            }
                            .padding(.vertical, 8)
                        }
                        
                        if dailyLogs.isEmpty {
                            Text("No rumination logged on this day.")
                                .foregroundStyle(.secondary)
                                .padding(.top, 40)
                        } else {
                            // MOST COMMON TRIGGERS (Bar Chart)
                            GroupBox {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Triggers that day")
                                        .font(.headline)
                                    
                                    Chart {
                                        ForEach(sortedTriggers(for: dailyLogs), id: \.name) { item in
                                            BarMark(
                                                x: .value("Count", item.count),
                                                y: .value("Emotion", item.name)
                                            )
                                            .foregroundStyle(by: .value("Emotion", item.name))
                                            .cornerRadius(4)
                                            .annotation(position: .trailing) {
                                                Text("\(item.count)")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    .frame(height: max(100, CGFloat(uniqueTriggersCount(in: dailyLogs) * 50)))
                                    .chartLegend(.hidden)
                                }
                                .padding(.vertical, 8)
                            }
                            
                            // TIME OF DAY PATTERNS (Line Chart)
                            GroupBox {
                                VStack(alignment: .leading, spacing: 16) {
                                    VStack(alignment: .leading) {
                                        Text("Time of Day")
                                            .font(.headline)
                                        Text("When did rumination peak?")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Chart(timeOfDayData(for: dailyLogs), id: \.date) { item in
                                        AreaMark(
                                            x: .value("Time", item.date),
                                            y: .value("Count", item.count)
                                        )
                                        .interpolationMethod(.monotone)
                                        .foregroundStyle(LinearGradient(colors: [Color.accentColor.opacity(0.4), Color.clear], startPoint: .top, endPoint: .bottom))
                                        
                                        LineMark(
                                            x: .value("Time", item.date),
                                            y: .value("Count", item.count)
                                        )
                                        .interpolationMethod(.monotone)
                                        .foregroundStyle(Color.accentColor)
                                        .lineStyle(StrokeStyle(lineWidth: 3))
                                    }
                                    .frame(height: 200)
                                    .chartXAxis {
                                        AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                                            if let _ = value.as(Date.self) {
                                                AxisValueLabel(format: .dateTime.hour())
                                                AxisGridLine()
                                                AxisTick()
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(uiColor: .systemGroupedBackground))
            }
//            .navigationTitle("Insights")
//            .navigationBarTitleDisplayMode(.inline)
            // The Expanding Calendar Sheet
            .sheet(isPresented: $showingCalendarSheet) {
                NavigationStack {
                    VStack {
                        DatePicker("Select Date", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .padding()
                        Spacer()
                    }
                    .navigationTitle("Jump to Date")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        Button("Done") { showingCalendarSheet = false }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
    
    // MARK: - Helpers
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    private var formattedDate: String {
        if isToday { return "Today" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }
    
    private func moveDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    // Data Processing
    private func sortedTriggers(for logs: [InterruptLog]) -> [(name: String, count: Int)] {
        var counts: [String: Int] = [:]
        for log in logs { counts[log.categoryName, default: 0] += 1 }
        return counts.map { (name: $0.key, count: $0.value) }.sorted { $0.count > $1.count }
    }
    
    private func timeOfDayData(for logs: [InterruptLog]) -> [(date: Date, count: Int)] {
        var hourlyCounts = Array(repeating: 0, count: 24)
        let calendar = Calendar.current
        for log in logs {
            let hour = calendar.component(.hour, from: log.timestamp)
            hourlyCounts[hour] += 1
        }
        let startOfDay = calendar.startOfDay(for: selectedDate)
        return hourlyCounts.enumerated().map { index, count in
            let hourDate = calendar.date(byAdding: .hour, value: index, to: startOfDay)!
            return (date: hourDate, count: count)
        }
    }
    
    private func uniqueTriggersCount(in logs: [InterruptLog]) -> Int {
        Set(logs.map { $0.categoryName }).count
    }
}
