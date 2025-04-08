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
                        // Header section
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Farm Dashboard")
                                    .font(.system(size: 28, weight: .bold))
                                
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
                        .padding(.top, 16)
                        
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
                    NavigationStack {
                        VStack(spacing: 20) {
                            Text("\(chart.value)\(chart.unit)")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundColor(chart.color)
                            
                            SensorChartView(chart: chart)
                                .frame(height: 300)
                                .padding(.horizontal)
                        }
                        .padding()
                        .navigationTitle(chart.title)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    showFullScreenChart = false
                                }
                            }
                        }
                    }
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