import SwiftUI
import FirebaseAuth
import Charts

// Data point model for storing sensor readings with timestamps
struct SensorReading: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double
    
    init(timestamp: String, value: Double) {
        // Parse ThingSpeak timestamp format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        self.timestamp = dateFormatter.date(from: timestamp) ?? Date()
        self.value = value
    }
}

// Chart data model
struct SensorChart: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let unit: String
    var value: String = "—"
    let fieldNumber: Int // ThingSpeak field number
    var readings: [SensorReading] = []
    
    // Channel URL for API access
    static let thingSpeakBaseURL = "https://api.thingspeak.com/channels/2910832/fields/"
    static let thingSpeakAPIKey = "BDRM96UBFZD5BHXR" // Read API Key
    
    // Generate API URL for fetching the latest value
    var apiURL: URL {
        URL(string: "\(SensorChart.thingSpeakBaseURL)\(fieldNumber)/last.json?api_key=\(SensorChart.thingSpeakAPIKey)")!
    }
    
    // Generate API URL for fetching historical data
    var historyURL: URL {
        URL(string: "\(SensorChart.thingSpeakBaseURL)\(fieldNumber).json?api_key=\(SensorChart.thingSpeakAPIKey)&results=60")!
    }
}

// ThingSpeak response model for single reading
struct ThingSpeakResponse: Codable {
    let createdAt: String
    let entryId: Int
    let field1: String?
    let field2: String?
    let field3: String?
    let field4: String?
    let field5: String?
    let field6: String?
    
    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case entryId = "entry_id"
        case field1, field2, field3, field4, field5, field6
    }
    
    func getValue(forField fieldNumber: Int) -> String? {
        switch fieldNumber {
        case 1: return field1
        case 2: return field2
        case 3: return field3
        case 4: return field4
        case 5: return field5
        case 6: return field6
        default: return nil
        }
    }
}

// ThingSpeak response model for historical data
struct ThingSpeakHistoryResponse: Codable {
    let channel: ChannelInfo
    let feeds: [Feed]
    
    struct ChannelInfo: Codable {
        let id: Int
        let name: String
    }
    
    struct Feed: Codable {
        let createdAt: String
        let entryId: Int
        let field1: String?
        let field2: String?
        let field3: String?
        let field4: String?
        let field5: String?
        let field6: String?
        
        enum CodingKeys: String, CodingKey {
            case createdAt = "created_at"
            case entryId = "entry_id"
            case field1, field2, field3, field4, field5, field6
        }
        
        func getValue(forField fieldNumber: Int) -> String? {
            switch fieldNumber {
            case 1: return field1
            case 2: return field2
            case 3: return field3
            case 4: return field4
            case 5: return field5
            case 6: return field6
            default: return nil
            }
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedChart: SensorChart?
    @State private var showFullScreenChart = false
    @State private var isRefreshing = false
    @State private var charts: [SensorChart] = []
    
    // Initialize charts
    let initialCharts: [SensorChart] = [
        SensorChart(
            title: "Temperature",
            icon: "thermometer",
            color: .red,
            unit: "°C",
            fieldNumber: 1
        ),
        SensorChart(
            title: "Humidity",
            icon: "humidity",
            color: .blue,
            unit: "%",
            fieldNumber: 2
        ),
        SensorChart(
            title: "Soil Moisture",
            icon: "drop.fill",
            color: .brown,
            unit: "%",
            fieldNumber: 3
        ),
        SensorChart(
            title: "Air Quality",
            icon: "aqi.medium",
            color: .green,
            unit: "AQI",
            fieldNumber: 4
        ),
        SensorChart(
            title: "Rain",
            icon: "cloud.rain",
            color: .cyan,
            unit: "mm",
            fieldNumber: 5
        ),
        SensorChart(
            title: "Pressure",
            icon: "gauge",
            color: .purple,
            unit: "hPa",
            fieldNumber: 6
        )
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Greeting section
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text("नमस्ते,")
                                        .font(.system(size: 26, weight: .bold))
                                        .foregroundColor(Color("AccentColor"))
                                    
                                    Text(authManager.user?.displayName ?? "किसान")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.primary)
                                }
                                
                                Text("आपका स्वागत है")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                            }
                            
                            Spacer()
                            
                            if let photoURL = authManager.user?.photoURL, let url = URL(string: photoURL.absoluteString) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 56, height: 56)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 56, height: 56)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.green.opacity(0.3), lineWidth: 2))
                                    case .failure:
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 56, height: 56)
                                            .foregroundColor(Color.green)
                                            .background(Circle().fill(Color.green.opacity(0.1)).frame(width: 64, height: 64))
                                    @unknown default:
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 56, height: 56)
                                            .foregroundColor(Color.green)
                                    }
                                }
                                .background(Circle().fill(Color.green.opacity(0.1)).frame(width: 64, height: 64))
                                .onTapGesture {
                                    // Navigate to profile tab
                                    NotificationCenter.default.post(name: Notification.Name("SwitchToProfileTab"), object: nil)
                                }
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 56, height: 56)
                                    .foregroundColor(Color.green)
                                    .background(Circle().fill(Color.green.opacity(0.1)).frame(width: 64, height: 64))
                                    .onTapGesture {
                                        // Navigate to profile tab
                                        NotificationCenter.default.post(name: Notification.Name("SwitchToProfileTab"), object: nil)
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        
                        // Header section
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Farm Dashboard")
                                    .font(.system(size: 24, weight: .bold))
                                
                                Text("Real-time sensor data")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                refreshDashboard()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title2)
                                    .foregroundColor(Color("AccentColor"))
                                    .rotationEffect(Angle(degrees: isRefreshing ? 360 : 0))
                                    .animation(isRefreshing ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // Sensor readings grid
                        LazyVGrid(columns: [GridItem(.flexible())], spacing: 20) {
                            ForEach(charts) { chart in
                                self.ChartCard(chart: chart)
                                    .onTapGesture {
                                        selectedChart = chart
                                        showFullScreenChart = true
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
                .refreshable {
                    refreshDashboard()
                }
                
                if charts.isEmpty {
                    LoadingView()
                }
            }
            .sheet(isPresented: $showFullScreenChart) {
                if let chart = selectedChart {
                    DetailChartView(chart: chart, refreshAction: refreshDashboard)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Initialize charts and fetch data when view appears
                charts = initialCharts
                fetchAllSensorData()
            }
        }
    }
    
    private func refreshDashboard() {
        isRefreshing = true
        fetchAllSensorData()
    }
    
    // Fetch all sensor data from ThingSpeak
    private func fetchAllSensorData() {
        // Create a group to track multiple fetch operations
        let fetchGroup = DispatchGroup()
        
        // Copy charts to a mutable array
        var updatedCharts = charts
        
        // Fetch latest data for each chart
        for (index, chart) in charts.enumerated() {
            fetchGroup.enter()
            
            // First fetch the latest value
            URLSession.shared.dataTask(with: chart.apiURL) { data, response, error in
                defer { fetchGroup.leave() }
                
                guard let data = data, error == nil else {
                    print("Error fetching data for \(chart.title): \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(ThingSpeakResponse.self, from: data)
                    
                    if let value = response.getValue(forField: chart.fieldNumber) {
                        // Format the value (round to one decimal place)
                        let formattedValue = formatSensorValue(value: value, for: chart.title)
                        
                        // Update the chart value
                        DispatchQueue.main.async {
                            updatedCharts[index].value = formattedValue
                        }
                    }
                } catch {
                    print("Error decoding data for \(chart.title): \(error.localizedDescription)")
                }
            }.resume()
            
            // Then fetch historical data for charts
            fetchGroup.enter()
            URLSession.shared.dataTask(with: chart.historyURL) { data, response, error in
                defer { fetchGroup.leave() }
                
                guard let data = data, error == nil else {
                    print("Error fetching history for \(chart.title): \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let historyResponse = try decoder.decode(ThingSpeakHistoryResponse.self, from: data)
                    
                    var readings: [SensorReading] = []
                    
                    for feed in historyResponse.feeds {
                        if let valueStr = feed.getValue(forField: chart.fieldNumber),
                           let value = Double(valueStr) {
                            let reading = SensorReading(timestamp: feed.createdAt, value: value)
                            readings.append(reading)
                        }
                    }
                    
                    // Update the chart with historical data
                    DispatchQueue.main.async {
                        updatedCharts[index].readings = readings
                    }
                    
                } catch {
                    print("Error decoding history for \(chart.title): \(error.localizedDescription)")
                }
            }.resume()
        }
        
        // Update UI when all fetches complete
        fetchGroup.notify(queue: .main) {
            charts = updatedCharts
            isRefreshing = false
        }
    }
    
    // Format sensor values appropriately
    private func formatSensorValue(value: String, for sensorType: String) -> String {
        guard let doubleValue = Double(value) else { return "—" }
        
        switch sensorType {
        case "Temperature", "Humidity", "Soil Moisture":
            return String(format: "%.1f", doubleValue) // One decimal place
        case "Air Quality":
            return String(Int(doubleValue)) // No decimals for AQI
        case "Rain":
            return doubleValue > 0 ? String(format: "%.1f", doubleValue) : "0"
        case "Pressure":
            return String(Int(doubleValue)) // No decimals for pressure
        default:
            return String(format: "%.1f", doubleValue)
        }
    }
    
    // Native chart view
    struct SensorChartView: View {
        let chart: SensorChart
        @State private var selectedReading: SensorReading?
        @State private var isAnimating = false
        
        var body: some View {
            if chart.readings.isEmpty {
                // Show placeholder if no data
                VStack {
                    Text("No data available")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    // Chart statistics in a more compact form
                    if let min = minReading, let max = maxReading {
                        HStack(spacing: 16) {
                            StatItem(
                                label: "Min",
                                value: "\(String(format: "%.1f", min.value))",
                                unit: chart.unit,
                                color: .blue
                            )
                            
                            Divider()
                                .frame(height: 24)
                            
                            StatItem(
                                label: "Avg",
                                value: "\(String(format: "%.1f", averageValue))",
                                unit: chart.unit,
                                color: .gray
                            )
                            
                            Divider()
                                .frame(height: 24)
                            
                            StatItem(
                                label: "Max",
                                value: "\(String(format: "%.1f", max.value))",
                                unit: chart.unit,
                                color: .red
                            )
                        }
                    }
                    
                    // Render actual chart with data
                    Chart {
                        ForEach(chart.readings) { reading in
                            LineMark(
                                x: .value("Time", reading.timestamp),
                                y: .value(chart.title, reading.value)
                            )
                            .foregroundStyle(chart.color.gradient)
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            
                            AreaMark(
                                x: .value("Time", reading.timestamp),
                                y: .value(chart.title, reading.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        chart.color.opacity(0.2),
                                        chart.color.opacity(0.01)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }
                        
                        // Show thresholds for certain types of data
                        if let thresholdValue = getThresholdValue() {
                            RuleMark(y: .value("Threshold", thresholdValue))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                .foregroundStyle(.secondary.opacity(0.4))
                        }
                        
                        // Show selected point
                        if let selected = selectedReading {
                            PointMark(
                                x: .value("Time", selected.timestamp),
                                y: .value("Value", selected.value)
                            )
                            .foregroundStyle(chart.color)
                            .symbolSize(80)
                            .annotation(position: .top) {
                                VStack(alignment: .center, spacing: 2) {
                                    Text("\(String(format: "%.1f", selected.value))\(chart.unit)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                    
                                    Text(timeFormatter.string(from: selected.timestamp))
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                                .padding(5)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(UIColor.systemBackground))
                                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                                )
                            }
                        }
                    }
                    .chartYScale(domain: chartYRange(for: chart))
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 5)) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(timeFormatter.string(from: date))
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                                AxisTick(stroke: StrokeStyle(dash: [1, 2]))
                                    .foregroundStyle(.secondary.opacity(0.2))
                                AxisGridLine()
                                    .foregroundStyle(.secondary.opacity(0.1))
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                            AxisValueLabel {
                                if let doubleValue = value.as(Double.self) {
                                    Text("\(String(format: "%.1f", doubleValue))")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                            }
                            AxisGridLine()
                                .foregroundStyle(.secondary.opacity(0.1))
                        }
                    }
                    .chartOverlay { proxy in
                        GeometryReader { geometry in
                            Rectangle()
                                .fill(Color.clear)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            // Get the tap location and find the closest data point
                                            let location = value.location
                                            let xPosition = location.x - geometry[proxy.plotAreaFrame].origin.x
                                            
                                            guard xPosition >= 0, xPosition <= geometry[proxy.plotAreaFrame].width else {
                                                return
                                            }
                                            
                                            let timeAsDate: Date = proxy.value(atX: xPosition) ?? Date()
                                            selectNearestReading(to: timeAsDate)
                                        }
                                        .onEnded { _ in
                                            // Optional: keep the selection (current behavior) or clear it
                                            // selectedReading = nil
                                        }
                                )
                        }
                    }
                    .frame(height: 200)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            isAnimating = true
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
            }
        }
        
        // Statistic item view
        private struct StatItem: View {
            let label: String
            let value: String
            let unit: String
            let color: Color
            
            var body: some View {
                VStack(spacing: 3) {
                    Text(label)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    HStack(spacing: 1) {
                        Text(value)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(color)
                        
                        Text(unit)
                            .font(.system(size: 11))
                            .foregroundColor(color.opacity(0.8))
                    }
                }
            }
        }
        
        // Helpers for data analysis
        
        private var minReading: SensorReading? {
            chart.readings.min { $0.value < $1.value }
        }
        
        private var maxReading: SensorReading? {
            chart.readings.max { $0.value < $1.value }
        }
        
        private var averageValue: Double {
            let total = chart.readings.reduce(0.0) { $0 + $1.value }
            return total / Double(chart.readings.count)
        }
        
        private var timeFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter
        }
        
        // Calculate appropriate Y-axis range
        private func chartYRange(for chart: SensorChart) -> ClosedRange<Double> {
            if chart.readings.isEmpty {
                return 0...1
            }
            
            let values = chart.readings.map { $0.value }
            guard let min = values.min(), let max = values.max() else {
                return 0...1
            }
            
            let padding = (max - min) * 0.2
            return (min - padding)...(max + padding)
        }
        
        // Provide thresholds for specific sensor types
        private func getThresholdValue() -> Double? {
            switch chart.title {
            case "Temperature":
                return 30.0 // Threshold for high temperature
            case "Humidity":
                return 60.0 // Threshold for high humidity
            case "Soil Moisture":
                return 40.0 // Threshold for dry soil
            case "Air Quality":
                return 50.0 // Threshold for poor air quality
            default:
                return nil
            }
        }
        
        // Select the reading closest to a timestamp
        private func selectNearestReading(to date: Date) {
            guard !chart.readings.isEmpty else { return }
            
            let closestReading = chart.readings.min(by: { 
                abs($0.timestamp.timeIntervalSince(date)) < abs($1.timestamp.timeIntervalSince(date))
            })
            
            selectedReading = closestReading
        }
    }
    
    // Chart card view
    private func ChartCard(chart: SensorChart) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                // Icon and title
                HStack(spacing: 12) {
                    Image(systemName: chart.icon)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(chart.color)
                        .cornerRadius(8)
                    
                    Text(chart.title)
                        .font(.title3)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Value with loading state
                if chart.value == "—" && self.isRefreshing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.7)
                } else {
                    HStack(spacing: 2) {
                        Text(chart.value)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(chart.color)
                        
                        Text(chart.unit)
                            .font(.system(size: 14))
                            .foregroundColor(chart.color.opacity(0.7))
                            .padding(.top, 2)
                    }
                }
            }
            
            // Native chart
            SensorChartView(chart: chart)
                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AuthenticationManager())
    }
}

// Define a new TimeRange enum
enum TimeRange: String, CaseIterable, Identifiable {
    case hour = "Hour"
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case custom = "Custom"
    
    var id: String { self.rawValue }
    
    var apiParameter: String {
        switch self {
        case .hour: return "results=60" // Last 60 data points (approximately an hour)
        case .day: return "days=1"
        case .week: return "days=7"
        case .month: return "days=30"
        case .custom: return "" // Will be set dynamically
        }
    }
    
    var displayName: String {
        switch self {
        case .hour: return "Last Hour"
        case .day: return "24 Hours"
        case .week: return "7 Days"
        case .month: return "30 Days"
        case .custom: return "Custom"
        }
    }
    
    var chartDateFormat: String {
        switch self {
        case .hour: return "HH:mm"
        case .day: return "HH:mm"
        case .week: return "E d MMM"
        case .month: return "d MMM"
        case .custom: return "d MMM HH:mm"
        }
    }
}

// Detailed Chart View with time range selector and data analysis
struct DetailChartView: View {
    let chart: SensorChart
    let refreshAction: () -> Void
    
    @State private var selectedTimeRange: TimeRange = .hour
    @State private var detailedReadings: [SensorReading] = []
    @State private var isLoading = true
    @State private var showingExportOptions = false
    @State private var showingCustomDatePicker = false
    @State private var trendDirection: TrendDirection = .stable
    @State private var changeRate: Double = 0
    @State private var showExportSuccess = false
    @State private var exportMessage = ""
    @State private var customStartDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var customEndDate = Date()
    @State private var selectedTab = 0
    @State private var thresholdCrossings: [ThresholdEvent] = []
    
    // Metrics for prediction
    @State private var prediction: PredictionInfo?
    
    struct PredictionInfo {
        let nextValue: Double
        let confidence: Double
        let timestamp: Date
    }
    
    struct ThresholdEvent: Identifiable {
        let id = UUID()
        let timestamp: Date
        let value: Double
        let crossingUp: Bool
    }
    
    enum TrendDirection {
        case up, down, stable
        
        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .stable: return "arrow.forward"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .red
            case .down: return .blue
            case .stable: return .gray
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Current value display
                    HStack(spacing: 8) {
                        Image(systemName: chart.icon)
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(chart.color)
                            .cornerRadius(12)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(chart.title)
                                .font(.title3)
                                .fontWeight(.medium)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text(chart.value)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(chart.color)
                                
                                Text(chart.unit)
                                    .font(.system(size: 18))
                                    .foregroundColor(chart.color.opacity(0.7))
                                    .padding(.leading, 2)
                            }
                        }
                        
                        Spacer()
                        
                        // Trend indicator
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: trendDirection.icon)
                                    .font(.subheadline)
                                    .foregroundColor(trendDirection.color)
                                
                                Text(String(format: "%.1f%%", abs(changeRate)))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(trendDirection.color)
                            }
                            
                            Text(changeRate >= 0 ? "from previous" : "from previous")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(16)
                    
                    // Time range selector with custom date option
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Time Range")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                        
                        Picker("Time Range", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases) { range in
                                Text(range.displayName).tag(range)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: selectedTimeRange) { newValue in
                            if newValue == .custom {
                                showingCustomDatePicker = true
                            } else {
                                fetchDataForTimeRange()
                            }
                        }
                        
                        if selectedTimeRange == .custom {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("From")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(formatDateOnly(customStartDate))
                                        .font(.callout)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("To")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(formatDateOnly(customEndDate))
                                        .font(.callout)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    showingCustomDatePicker = true
                                }) {
                                    Text("Change")
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                                
                                Button(action: {
                                    fetchDataForCustomRange()
                                }) {
                                    Text("Apply")
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.top, 6)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(16)
                    
                    // Analysis Tabs
                    VStack(alignment: .leading, spacing: 10) {
                        Picker(selection: $selectedTab, label: Text("Analysis").hidden()) {
                            Text("Chart").tag(0)
                            Text("Stats").tag(1)
                            Text("Events").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        // Content based on selected tab
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(1.5)
                                    .padding()
                                Spacer()
                            }
                            .frame(height: 300)
                        } else if detailedReadings.isEmpty {
                            HStack {
                                Spacer()
                                Text("No data available for selected time range")
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .frame(height: 300)
                        } else {
                            switch selectedTab {
                            case 0: // Chart View
                                DetailChartContent(
                                    chart: chart,
                                    readings: detailedReadings,
                                    dateFormat: selectedTimeRange.chartDateFormat
                                )
                                .frame(height: 350)
                                .padding(.horizontal)
                            case 1: // Stats View
                                DataAnalysisGrid(readings: detailedReadings, unit: chart.unit)
                                    .padding()
                            case 2: // Events View
                                ThresholdEventsList(events: thresholdCrossings, unit: chart.unit)
                                    .frame(height: 300)
                                    .padding()
                            default:
                                EmptyView()
                            }
                        }
                    }
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(16)
                    
                    // Prediction Card (if available)
                    if let prediction = prediction {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                    .foregroundColor(.purple)
                                
                                Text("Prediction")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("\(Int(prediction.confidence * 100))% confidence")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                            
                            HStack(alignment: .center, spacing: 20) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Next reading prediction")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(String(format: "%.1f", prediction.nextValue))
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.primary)
                                        
                                        Text(chart.unit)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .padding(.leading, 2)
                                    }
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text("Expected at")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(formatDateTime(prediction.timestamp))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle(chart.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingExportOptions = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        refreshAction()
                    }
                }
            }
            .onAppear {
                fetchDataForTimeRange()
            }
            .sheet(isPresented: $showingCustomDatePicker) {
                NavigationStack {
                    VStack {
                        DatePicker(
                            "Start Date",
                            selection: $customStartDate,
                            in: ...customEndDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .padding()
                        
                        DatePicker(
                            "End Date",
                            selection: $customEndDate,
                            in: customStartDate...Date(),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(CompactDatePickerStyle())
                        .padding()
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showingCustomDatePicker = false
                                // If no custom date was set before, revert to hour
                                if selectedTimeRange == .custom && detailedReadings.isEmpty {
                                    selectedTimeRange = .hour
                                }
                            }
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Apply") {
                                showingCustomDatePicker = false
                                fetchDataForCustomRange()
                            }
                        }
                    }
                    .navigationTitle("Select Date Range")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.medium, .large])
            }
            .confirmationDialog("Export Options", isPresented: $showingExportOptions) {
                Button("Export as CSV") {
                    exportAsCSV()
                }
                
                Button("Share as Image") {
                    exportAsImage()
                }
                
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Choose how to export your data")
            }
            .overlay(
                Group {
                    if showExportSuccess {
                        VStack {
                            Spacer()
                            
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                
                                Text(exportMessage)
                                    .font(.subheadline)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 16)
                            }
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                            .padding(.bottom, 20)
                        }
                        .transition(.move(edge: .bottom))
                        .animation(.spring(), value: showExportSuccess)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    showExportSuccess = false
                                }
                            }
                        }
                    }
                }
            )
        }
    }
    
    // Fetch data for the selected time range
    private func fetchDataForTimeRange() {
        isLoading = true
        detailedReadings = []
        
        // Construct the URL based on the selected time range
        let urlString = "\(SensorChart.thingSpeakBaseURL)\(chart.fieldNumber).json?api_key=\(SensorChart.thingSpeakAPIKey)&\(selectedTimeRange.apiParameter)"
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { 
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
            
            guard let data = data, error == nil else {
                print("Error fetching data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let historyResponse = try decoder.decode(ThingSpeakHistoryResponse.self, from: data)
                
                var readings: [SensorReading] = []
                
                for feed in historyResponse.feeds {
                    if let valueStr = feed.getValue(forField: chart.fieldNumber),
                       let value = Double(valueStr) {
                        let reading = SensorReading(timestamp: feed.createdAt, value: value)
                        readings.append(reading)
                    }
                }
                
                DispatchQueue.main.async {
                    self.detailedReadings = readings
                    calculateTrend()
                    detectThresholdCrossings()
                    generatePrediction()
                }
                
            } catch {
                print("Error decoding data: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    // Fetch data for a custom date range
    private func fetchDataForCustomRange() {
        isLoading = true
        detailedReadings = []
        
        // Format dates for ThingSpeak API
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        
        let startDateString = dateFormatter.string(from: customStartDate)
        let endDateString = dateFormatter.string(from: customEndDate)
        
        // Construct the URL with start and end dates
        let urlString = "\(SensorChart.thingSpeakBaseURL)\(chart.fieldNumber).json?api_key=\(SensorChart.thingSpeakAPIKey)&start=\(startDateString)&end=\(endDateString)"
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { 
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
            
            guard let data = data, error == nil else {
                print("Error fetching data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let historyResponse = try decoder.decode(ThingSpeakHistoryResponse.self, from: data)
                
                var readings: [SensorReading] = []
                
                for feed in historyResponse.feeds {
                    if let valueStr = feed.getValue(forField: chart.fieldNumber),
                       let value = Double(valueStr) {
                        let reading = SensorReading(timestamp: feed.createdAt, value: value)
                        readings.append(reading)
                    }
                }
                
                DispatchQueue.main.async {
                    self.detailedReadings = readings
                    calculateTrend()
                    detectThresholdCrossings()
                    generatePrediction()
                }
                
            } catch {
                print("Error decoding data: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    // Calculate trend direction and change rate
    private func calculateTrend() {
        guard detailedReadings.count > 1 else {
            trendDirection = .stable
            changeRate = 0
            return
        }
        
        // Get first and last readings to calculate overall change
        let sortedReadings = detailedReadings.sorted { $0.timestamp < $1.timestamp }
        guard let firstReading = sortedReadings.first,
              let lastReading = sortedReadings.last else {
            return
        }
        
        let firstValue = firstReading.value
        let lastValue = lastReading.value
        
        if abs(lastValue - firstValue) < 0.1 {
            trendDirection = .stable
            changeRate = 0
        } else if lastValue > firstValue {
            trendDirection = .up
            changeRate = firstValue > 0 ? ((lastValue - firstValue) / firstValue) * 100 : 0
        } else {
            trendDirection = .down
            changeRate = firstValue > 0 ? ((firstValue - lastValue) / firstValue) * 100 : 0
        }
    }
    
    // Detect threshold crossings
    private func detectThresholdCrossings() {
        // Reset previous events
        thresholdCrossings = []
        
        // Get the threshold value for the current chart
        guard let threshold = getThresholdValue(for: chart.title),
              detailedReadings.count > 1 else {
            return
        }
        
        // Sort readings by timestamp
        let sortedReadings = detailedReadings.sorted { $0.timestamp < $1.timestamp }
        
        // Detect crossing events
        var wasAboveThreshold = sortedReadings.first!.value > threshold
        
        for i in 1..<sortedReadings.count {
            let reading = sortedReadings[i]
            let isAboveThreshold = reading.value > threshold
            
            // If threshold was crossed
            if isAboveThreshold != wasAboveThreshold {
                let event = ThresholdEvent(
                    timestamp: reading.timestamp,
                    value: reading.value,
                    crossingUp: isAboveThreshold
                )
                thresholdCrossings.append(event)
                wasAboveThreshold = isAboveThreshold
            }
        }
    }
    
    // Generate prediction for next value
    private func generatePrediction() {
        guard detailedReadings.count >= 5 else {
            prediction = nil
            return
        }
        
        // Sort readings by timestamp
        let sortedReadings = detailedReadings.sorted { $0.timestamp < $1.timestamp }
        
        // Simple linear regression for prediction
        let count = min(10, sortedReadings.count) // Use last 10 points
        let recentReadings = Array(sortedReadings.suffix(count))
        
        let xValues = recentReadings.indices.map { Double($0) }
        let yValues = recentReadings.map { $0.value }
        
        let meanX = xValues.reduce(0, +) / Double(xValues.count)
        let meanY = yValues.reduce(0, +) / Double(yValues.count)
        
        let numerator = zip(xValues, yValues).reduce(0) { $0 + ($1.0 - meanX) * ($1.1 - meanY) }
        let denominator = xValues.reduce(0) { $0 + pow($1 - meanX, 2) }
        
        guard denominator != 0 else {
            prediction = nil
            return
        }
        
        let slope = numerator / denominator
        let intercept = meanY - slope * meanX
        
        // Predict next value
        let nextX = Double(xValues.count)
        let predictedValue = slope * nextX + intercept
        
        // Add noise for realism
        let noiseRange = abs(slope * 0.8)
        let noise = Double.random(in: -noiseRange...noiseRange)
        let finalPrediction = predictedValue + noise
        
        // Calculate typical time interval between readings
        let timeIntervals = zip(recentReadings.dropFirst(), recentReadings).map { 
            $0.0.timestamp.timeIntervalSince($0.1.timestamp)
        }
        let avgInterval = timeIntervals.reduce(0, +) / Double(timeIntervals.count)
        
        // Predicted timestamp
        let nextTimestamp = sortedReadings.last!.timestamp.addingTimeInterval(abs(avgInterval))
        
        // Calculate confidence (higher for more stable data)
        let variance = yValues.reduce(0) { sum, y in
            let diff = y - meanY
            return sum + diff * diff
        } / Double(yValues.count)
        
        let stdDev = sqrt(variance)
        let meanValue = meanY
        let coefficientOfVariation = stdDev / meanValue
        
        // Map coefficient of variation to confidence (lower variation = higher confidence)
        let confidence = max(0.5, min(0.95, 1.0 - coefficientOfVariation))
        
        prediction = PredictionInfo(
            nextValue: finalPrediction,
            confidence: confidence,
            timestamp: nextTimestamp
        )
    }
    
    // Export data as CSV
    private func exportAsCSV() {
        // Create CSV content
        var csvContent = "Timestamp,\(chart.title) (\(chart.unit))\n"
        
        let sortedReadings = detailedReadings.sorted { $0.timestamp < $1.timestamp }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for reading in sortedReadings {
            let timestamp = dateFormatter.string(from: reading.timestamp)
            csvContent.append("\(timestamp),\(reading.value)\n")
        }
        
        // Save to file and share
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent("\(chart.title)_export.csv")
            
            do {
                try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
                print("CSV file created at \(fileURL.path)")
                
                // Show success message
                withAnimation {
                    exportMessage = "Data exported as CSV"
                    showExportSuccess = true
                }
                
                // In a real app, we would launch the share sheet here
                // UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            } catch {
                print("Error creating CSV file: \(error.localizedDescription)")
                
                withAnimation {
                    exportMessage = "Error exporting data"
                    showExportSuccess = true
                }
            }
        }
    }
    
    // Export as image (placeholder)
    private func exportAsImage() {
        // In a real app, this would use UIGraphicsImageRenderer to create an image of the chart
        // For this example, we'll just show a success message
        withAnimation {
            exportMessage = "Chart image saved to Photos"
            showExportSuccess = true
        }
    }
    
    // Format date for custom date display
    private func formatDateOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy HH:mm"
        return formatter.string(from: date)
    }
    
    // Format date for prediction
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }
    
    // Get threshold value for a specific sensor type
    private func getThresholdValue(for sensorType: String) -> Double? {
        switch sensorType {
        case "Temperature":
            return 30.0 // Threshold for high temperature
        case "Humidity":
            return 60.0 // Threshold for high humidity
        case "Soil Moisture":
            return 40.0 // Threshold for dry soil
        case "Air Quality":
            return 50.0 // Threshold for poor air quality
        default:
            return nil
        }
    }
}

// Detailed chart content
struct DetailChartContent: View {
    let chart: SensorChart
    let readings: [SensorReading]
    let dateFormat: String
    @State private var selectedReading: SensorReading?
    
    var body: some View {
        Chart {
            ForEach(readings) { reading in
                LineMark(
                    x: .value("Time", reading.timestamp),
                    y: .value(chart.title, reading.value)
                )
                .foregroundStyle(chart.color.gradient)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                AreaMark(
                    x: .value("Time", reading.timestamp),
                    y: .value(chart.title, reading.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            chart.color.opacity(0.2),
                            chart.color.opacity(0.01)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            
            if let threshold = getThresholdValue(for: chart.title) {
                RuleMark(y: .value("Threshold", threshold))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.secondary.opacity(0.4))
                    .annotation(position: .trailing) {
                        Text("Threshold")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
            }
            
            if let selected = selectedReading {
                PointMark(
                    x: .value("Time", selected.timestamp),
                    y: .value("Value", selected.value)
                )
                .foregroundStyle(chart.color)
                .symbolSize(100)
                .annotation(position: .top) {
                    VStack(alignment: .center, spacing: 2) {
                        Text("\(String(format: "%.1f", selected.value))\(chart.unit)")
                            .font(.caption)
                            .fontWeight(.bold)
                        
                        Text(formatDate(selected.timestamp))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(UIColor.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(formatChartDate(date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    AxisGridLine()
                        .foregroundStyle(.secondary.opacity(0.1))
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text("\(String(format: "%.1f", doubleValue))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                AxisGridLine()
                    .foregroundStyle(.secondary.opacity(0.1))
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let location = value.location
                                let xPosition = location.x - geometry[proxy.plotAreaFrame].origin.x
                                
                                guard xPosition >= 0, xPosition <= geometry[proxy.plotAreaFrame].width else {
                                    return
                                }
                                
                                let timeAsDate: Date = proxy.value(atX: xPosition) ?? Date()
                                selectNearestReading(to: timeAsDate)
                            }
                            .onEnded { _ in
                                // Optional: Uncomment to clear selection when released
                                // selectedReading = nil
                            }
                    )
            }
        }
    }
    
    private func selectNearestReading(to date: Date) {
        guard !readings.isEmpty else { return }
        
        let closestReading = readings.min(by: { 
            abs($0.timestamp.timeIntervalSince(date)) < abs($1.timestamp.timeIntervalSince(date))
        })
        
        selectedReading = closestReading
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatChartDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        return formatter.string(from: date)
    }
    
    private func getThresholdValue(for sensorType: String) -> Double? {
        switch sensorType {
        case "Temperature":
            return 30.0 // Threshold for high temperature
        case "Humidity":
            return 60.0 // Threshold for high humidity
        case "Soil Moisture":
            return 40.0 // Threshold for dry soil
        case "Air Quality":
            return 50.0 // Threshold for poor air quality
        default:
            return nil
        }
    }
}

// Threshold Events List
struct ThresholdEventsList: View {
    let events: [DetailChartView.ThresholdEvent]
    let unit: String
    
    var body: some View {
        if events.isEmpty {
            VStack {
                Spacer()
                Text("No threshold crossings detected")
                    .foregroundColor(.secondary)
                Spacer()
            }
        } else {
            List {
                ForEach(events) { event in
                    HStack {
                        Image(systemName: event.crossingUp ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundColor(event.crossingUp ? .red : .blue)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.crossingUp ? "Exceeded threshold" : "Dropped below threshold")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                
                            Text("\(String(format: "%.1f", event.value))\(unit)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(formatEventDate(event.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private func formatEventDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }
}

// Data Analysis Grid Component
struct DataAnalysisGrid: View {
    let readings: [SensorReading]
    let unit: String
    
    private var sortedReadings: [SensorReading] {
        readings.sorted { $0.timestamp < $1.timestamp }
    }
    
    private var minValue: Double {
        readings.map { $0.value }.min() ?? 0
    }
    
    private var maxValue: Double {
        readings.map { $0.value }.max() ?? 0
    }
    
    private var avgValue: Double {
        let sum = readings.reduce(0) { $0 + $1.value }
        return sum / Double(readings.count)
    }
    
    private var stdDeviation: Double {
        let mean = avgValue
        let variance = readings.reduce(0.0) { sum, reading in
            let difference = reading.value - mean
            return sum + (difference * difference)
        } / Double(readings.count)
        return sqrt(variance)
    }
    
    private var variability: String {
        let ratio = stdDeviation / avgValue
        if ratio < 0.05 {
            return "Very stable"
        } else if ratio < 0.1 {
            return "Stable"
        } else if ratio < 0.2 {
            return "Moderate"
        } else if ratio < 0.5 {
            return "Variable"
        } else {
            return "Highly variable"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Top stats row
            HStack {
                DataStatBox(
                    title: "Minimum",
                    value: String(format: "%.1f", minValue),
                    unit: unit,
                    icon: "arrow.down.to.line",
                    color: .blue
                )
                
                Spacer()
                
                DataStatBox(
                    title: "Maximum",
                    value: String(format: "%.1f", maxValue),
                    unit: unit,
                    icon: "arrow.up.to.line",
                    color: .red
                )
                
                Spacer()
                
                DataStatBox(
                    title: "Average",
                    value: String(format: "%.1f", avgValue),
                    unit: unit,
                    icon: "equal",
                    color: .purple
                )
            }
            
            // Bottom stats row
            HStack {
                DataStatBox(
                    title: "Std Deviation",
                    value: String(format: "%.2f", stdDeviation),
                    unit: unit,
                    icon: "waveform.path",
                    color: .orange
                )
                
                Spacer()
                
                DataStatBox(
                    title: "Variability",
                    value: variability,
                    unit: "",
                    icon: "chart.bar.xaxis",
                    color: .green
                )
                
                Spacer()
                
                let trend = calculateTrend()
                DataStatBox(
                    title: "Trend",
                    value: trend,
                    unit: "",
                    icon: "arrow.up.forward",
                    color: .cyan
                )
            }
        }
    }
    
    // Calculate trend as a separate function to break up complex expressions
    private func calculateTrend() -> String {
        guard sortedReadings.count >= 3 else { return "Insufficient data" }
        
        // Simple linear regression to determine trend
        let xValues = Array(0..<sortedReadings.count).map { Double($0) }
        let yValues = sortedReadings.map { $0.value }
        
        let meanX = xValues.reduce(0, +) / Double(xValues.count)
        let meanY = yValues.reduce(0, +) / Double(yValues.count)
        
        let numerator = zip(xValues, yValues).reduce(0) { $0 + ($1.0 - meanX) * ($1.1 - meanY) }
        let denominator = xValues.reduce(0) { $0 + pow($1 - meanX, 2) }
        
        guard denominator != 0 else { return "Stable" }
        
        let slope = numerator / denominator
        let slopePercentage = (slope / meanY) * 100
        
        if abs(slopePercentage) < 0.5 {
            return "Stable"
        } else if slopePercentage > 0 {
            return "Increasing (\(String(format: "%.1f", abs(slopePercentage)))%)"
        } else {
            return "Decreasing (\(String(format: "%.1f", abs(slopePercentage)))%)"
        }
    }
}

// Individual stat box
struct DataStatBox: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if unit.isEmpty {
                Text(value)
                    .font(.system(size: 13, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(unit)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
} 