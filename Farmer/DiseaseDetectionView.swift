import SwiftUI
import UIKit

struct DiseaseDetectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var inputImage: UIImage?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cotton Disease Detection")
                        .font(.system(size: 24, weight: .bold))
                        
                    Text("Upload or take a photo of cotton leaves to detect diseases")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Image display area
                ZStack {
                    if let image = inputImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                    } else {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .cornerRadius(12)
                            .overlay(
                                VStack(spacing: 12) {
                                    Image(systemName: "leaf")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                    
                                    Text("No image selected")
                                        .foregroundColor(.secondary)
                                }
                            )
                    }
                }
                .frame(height: 300)
                .padding(.horizontal)
                
                // Image selection buttons
                HStack(spacing: 16) {
                    Button(action: {
                        showImagePicker = true
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
                        showCamera = true
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
                
                Spacer()
            }
            .padding(.vertical)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                DiseaseImagePicker(image: $inputImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showCamera) {
                DiseaseImagePicker(image: $inputImage, sourceType: .camera)
            }
        }
    }
}

// MARK: - Image Picker
struct DiseaseImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: DiseaseImagePicker
        
        init(_ parent: DiseaseImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    DiseaseDetectionView()
} 