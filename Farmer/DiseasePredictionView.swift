import SwiftUI

struct DiseasePredictionView: View {
    @State private var selectedImage: UIImage?
    @State private var isShowingImagePicker = false
    @State private var isAnalyzing = false
    @State private var resultText = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Header section
                    VStack(spacing: 10) {
                        Text("Disease Detection")
                            .font(.system(size: 28, weight: .bold))
                            .multilineTextAlignment(.center)
                        
                        Text("Upload a photo of your plant to detect diseases")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Image upload section
                    VStack(spacing: 20) {
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .cornerRadius(12)
                                .shadow(radius: 5)
                        } else {
                            // Empty image placeholder
                            ZStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 250)
                                    .cornerRadius(12)
                                
                                VStack(spacing: 12) {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(Color("AccentColor"))
                                    
                                    Text("No image selected")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        // Upload button
                        Button {
                            isShowingImagePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "photo.fill")
                                Text(selectedImage == nil ? "Upload Image" : "Change Image")
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color("AccentColor"))
                            .cornerRadius(30)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Analyze button
                    if selectedImage != nil {
                        Button {
                            analyzeImage()
                        } label: {
                            HStack {
                                if isAnalyzing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .padding(.trailing, 8)
                                } else {
                                    Image(systemName: "wand.and.stars")
                                }
                                
                                Text(isAnalyzing ? "Analyzing..." : "Analyze Image")
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 30)
                            .background(Color.purple)
                            .cornerRadius(30)
                            .shadow(color: Color.purple.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isAnalyzing)
                    }
                    
                    // Results section
                    if !resultText.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Analysis Results")
                                .font(.headline)
                                .padding(.bottom, 5)
                            
                            Text(resultText)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Disease Detection")
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
        }
    }
    
    private func analyzeImage() {
        guard selectedImage != nil else { return }
        
        // Simulate analysis
        isAnalyzing = true
        resultText = ""
        
        // In a real app, you would send the image to an API or ML model
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isAnalyzing = false
            resultText = "Your plant appears to be healthy. No diseases detected. Keep monitoring for best results."
        }
    }
}

// Image Picker Component
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
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
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    DiseasePredictionView()
} 