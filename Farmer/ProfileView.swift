import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Kingfisher

// Disease Detection History model
struct DiseaseDetectionHistory: Identifiable {
    let id = UUID()
    let date: Date
    let diseaseName: String
    let confidence: Double
    let imageUrl: String? // In a real app, this would be an actual URL to a stored image
    
    // For demo purposes
    static let sampleData = [
        DiseaseDetectionHistory(
            date: Date().addingTimeInterval(-86400 * 2), // 2 days ago
            diseaseName: "Bacterial Blight",
            confidence: 0.78,
            imageUrl: nil
        ),
        DiseaseDetectionHistory(
            date: Date().addingTimeInterval(-86400 * 5), // 5 days ago
            diseaseName: "Healthy",
            confidence: 0.92,
            imageUrl: nil
        )
    ]
}

struct FarmerProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var profileImage: UIImage?
    @State private var isShowingImagePicker = false
    @State private var isShowingEditProfile = false
    @State private var isLoading = true
    @State private var displayName = ""
    @State private var email = ""
    @State private var photoURL: URL?
    @State private var diseaseDetections = [DiseaseDetectionHistory]()
    @State private var showingDiseaseDetection = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile header
                    VStack(spacing: 16) {
                        // Profile image
                        ZStack {
                            if let photoURL = photoURL {
                                KFImage(photoURL)
                                    .placeholder {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.white)
                                            .frame(width: 100, height: 100)
                                            .background(Color.gray)
                                            .clipShape(Circle())
                                    }
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                                    .frame(width: 100, height: 100)
                                    .background(Color.gray)
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                            
                            // Edit button overlay
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        isShowingEditProfile = true
                                    }) {
                                        Image(systemName: "pencil")
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(Color.blue)
                                            .clipShape(Circle())
                                    }
                                }
                            }
                            .frame(width: 100, height: 100)
                        }
                        
                        // User info
                        VStack(spacing: 4) {
                            Text(displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Disease Detection History Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "leaf.arrow.circlepath")
                                .foregroundColor(.green)
                            
                            Text("Disease Detection History")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                // Show full history
                            }) {
                                Text("See All")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        if diseaseDetections.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    Image(systemName: "leaf")
                                        .font(.system(size: 30))
                                        .foregroundColor(.secondary)
                                    
                                    Text("No disease detection history")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                Spacer()
                            }
                        } else {
                            ForEach(diseaseDetections.prefix(3)) { detection in
                                DiseaseHistoryCard(detection: detection)
                                    .padding(.horizontal)
                            }
                        }
                        
                        Button(action: {
                            showingDiseaseDetection = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("New Detection")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Settings section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Settings")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        SettingsRow(icon: "gear", text: "Account Settings") {
                            // Navigate to account settings
                        }
                        
                        SettingsRow(icon: "bell", text: "Notifications") {
                            // Navigate to notifications settings
                        }
                        
                        SettingsRow(icon: "lock.shield", text: "Privacy & Security") {
                            // Navigate to privacy settings
                        }
                        
                        SettingsRow(icon: "questionmark.circle", text: "Help & Support") {
                            // Navigate to help
                        }
                        
                        Button(action: {
                            authManager.signOut()
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.circle")
                                    .foregroundColor(.red)
                                Text("Sign Out")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showingDiseaseDetection) {
                DiseaseDetectionView()
            }
            .onAppear {
                loadProfileData()
                loadDiseaseDetections()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NewDiseaseDetection"))) { _ in
                loadDiseaseDetections()
            }
        }
    }
    
    // Load profile data
    private func loadProfileData() {
        isLoading = true
        
        guard let user = Auth.auth().currentUser else {
            isLoading = false
            return
        }
        
        displayName = user.displayName ?? "User"
        email = user.email ?? "No email"
        
        if let photoURL = user.photoURL {
            self.photoURL = photoURL
        }
        
        isLoading = false
    }
    
    // Load disease detections from UserDefaults
    private func loadDiseaseDetections() {
        guard let savedData = UserDefaults.standard.array(forKey: "diseaseDetections") as? [[String: Any]] else {
            // If no saved data, use sample data for demo
            diseaseDetections = DiseaseDetectionHistory.sampleData
            return
        }
        
        // Convert dictionaries to DiseaseDetectionHistory objects
        var detections = [DiseaseDetectionHistory]()
        
        for item in savedData {
            guard let dateValue = item["date"] as? TimeInterval,
                  let diseaseName = item["diseaseName"] as? String,
                  let confidence = item["confidence"] as? Double else {
                continue
            }
            
            let imageUrl = item["imageUrl"] as? String
            
            let detection = DiseaseDetectionHistory(
                date: Date(timeIntervalSince1970: dateValue),
                diseaseName: diseaseName,
                confidence: confidence,
                imageUrl: imageUrl
            )
            
            detections.append(detection)
        }
        
        // Sort by date, most recent first
        diseaseDetections = detections.sorted { $0.date > $1.date }
    }
}

// Settings row component
struct SettingsRow: View {
    let icon: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                Text(text)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
}

// Disease History Card component
struct DiseaseHistoryCard: View {
    let detection: DiseaseDetectionHistory
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        HStack {
            // Disease icon or image
            ZStack {
                if let imageUrl = detection.imageUrl, let url = URL(string: imageUrl) {
                    KFImage(url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                } else {
                    Image(systemName: "leaf.circle")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(detection.diseaseName == "Healthy" ? Color.green : Color.orange)
                        .cornerRadius(8)
                }
            }
            
            // Disease info
            VStack(alignment: .leading, spacing: 4) {
                Text(detection.diseaseName)
                    .font(.headline)
                
                Text("Confidence: \(Int(detection.confidence * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(dateFormatter.string(from: detection.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 4)
            
            Spacer()
            
            // Status indicator
            VStack {
                Circle()
                    .fill(detection.diseaseName == "Healthy" ? Color.green : Color.orange)
                    .frame(width: 12, height: 12)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
} 
