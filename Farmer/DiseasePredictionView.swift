import SwiftUI
import UIKit

struct DiseasePredictionView: View {
    @State private var selectedImage: UIImage?
    @State private var isShowingImagePicker = false
    @State private var isShowingCamera = false
    @State private var isAnalyzing = false
    @State private var predictionResult: PredictionResult?
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Model information
    private let modelURL = "https://teachablemachine.withgoogle.com/models/LuJmYkuSE/"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cotton Disease Detection")
                            .font(.system(size: 28, weight: .bold))
                        
                        Text("Upload or take a photo of cotton leaves to detect diseases")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    // Image display area
                    ZStack {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                        } else {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    VStack(spacing: 16) {
                                        Image(systemName: "leaf.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(.green.opacity(0.6))
                                        
                                        Text("No image selected")
                                            .foregroundColor(.secondary)
                                    }
                                )
                        }
                        
                        if isAnalyzing {
                            Rectangle()
                                .fill(Color.black.opacity(0.5))
                                .cornerRadius(12)
                                .overlay(
                                    VStack(spacing: 16) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .scaleEffect(1.5)
                                            .tint(.white)
                                        
                                        Text("Analyzing image...")
                                            .foregroundColor(.white)
                                            .font(.headline)
                                    }
                                )
                        }
                    }
                    .frame(height: 300)
                    .padding(.horizontal)
                    
                    // Image selection buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            isShowingImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("Choose Photo")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            isShowingCamera = true
                        }) {
                            HStack {
                                Image(systemName: "camera")
                                Text("Take Photo")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Analyze button
                    if selectedImage != nil {
                        Button(action: {
                            analyzeImage()
                        }) {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                Text("Analyze Image")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isAnalyzing)
                        .padding(.horizontal)
                    }
                    
                    // Results display
                    if let result = predictionResult {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Detection Results")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ResultCard(result: result)
                                .padding(.horizontal)
                            
                            // Save to profile button
                            Button(action: {
                                saveToProfile(result)
                            }) {
                                HStack {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                    Text("Save to Profile")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Disease Detection")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $isShowingCamera) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
            }
            .alert("Disease Detection", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func analyzeImage() {
        guard let image = selectedImage else { return }
        
        isAnalyzing = true
        
        // Simulate model call (in real app, replace with TensorFlow Lite call)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // In actual implementation, we would use TensorFlow Lite to load the model
            // and perform inference on the image
            // For now, we'll simulate the result
            let diseases = [
                PredictionResult(
                    diseaseName: "Bacterial Blight",
                    confidence: 0.82,
                    description: "A bacterial disease that causes water-soaked lesions on leaves, which later turn brown with yellow halos.",
                    treatment: "Use disease-free seeds. Apply copper-based bactericides. Practice crop rotation with non-host crops for 2-3 years."
                ),
                PredictionResult(
                    diseaseName: "Leaf Curl Virus",
                    confidence: 0.78,
                    description: "Caused by a Gemini virus transmitted by whiteflies. Symptoms include upward curling of leaves, thickened veins, and reduced yield.",
                    treatment: "Remove and destroy infected plants. Use insecticides to control whitefly populations. Plant resistant varieties if available."
                ),
                PredictionResult(
                    diseaseName: "Healthy",
                    confidence: 0.95,
                    description: "The cotton plant appears healthy with no signs of disease.",
                    treatment: "Continue regular maintenance and monitoring for any signs of pests or diseases."
                ),
                PredictionResult(
                    diseaseName: "Target Spot",
                    confidence: 0.75,
                    description: "Fungal disease causing circular lesions with concentric rings that resemble a target or bullseye.",
                    treatment: "Apply fungicides at the first sign of disease. Improve air circulation by proper spacing. Avoid overhead irrigation."
                )
            ]
            
            // For demo, just pick one randomly
            // In real app, this would be the actual prediction result
            self.predictionResult = diseases.randomElement()!
            self.isAnalyzing = false
        }
    }
    
    private func saveToProfile(_ result: PredictionResult) {
        // Here we would save the detection to the user's profile
        // For this demo, we'll just show an alert
        alertMessage = "Disease detection saved to your profile!"
        showAlert = true
        
        // Notify the ProfileView to refresh
        NotificationCenter.default.post(name: Notification.Name("NewDiseaseDetection"), object: nil, userInfo: [
            "diseaseName": result.diseaseName,
            "confidence": result.confidence,
            "date": Date()
        ])
    }
}

// MARK: - Supporting Types
struct PredictionResult {
    let diseaseName: String
    let confidence: Double
    let description: String
    let treatment: String
}

struct ResultCard: View {
    let result: PredictionResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(result.diseaseName)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("Confidence: \(Int(result.confidence * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(confidenceColor.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(result.confidence))
                        .stroke(confidenceColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(result.confidence * 100))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(confidenceColor)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                
                Text(result.description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Recommended Treatment")
                    .font(.headline)
                
                Text(result.treatment)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var confidenceColor: Color {
        if result.diseaseName == "Healthy" {
            return .green
        } else if result.confidence > 0.8 {
            return .red
        } else if result.confidence > 0.6 {
            return .orange
        } else {
            return .yellow
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    DiseasePredictionView()} 