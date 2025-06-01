import SwiftUI

struct CreateForumPostView: View {
    @EnvironmentObject var viewModel: ForumViewModel // Injected from ForumHomeView
    @Environment(\.presentationMode) var presentationMode // To dismiss the view

    @State private var postTitle: String = ""
    @State private var postContent: String = ""
    @State private var selectedCategory: String = "General" // Default category
    // Add more state vars if needed, e.g., for tags

    // Example categories - could be fetched from Firestore or be static
    let categories = ["General", "Cotton", "Wheat", "Pest Control", "Soil Health", "Tips & Tricks", "Questions"]

    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSubmitting = false


    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Post Details")) {
                    TextField("Post Title", text: $postTitle)

                    // Larger text area for content
                    VStack(alignment: .leading) {
                        Text("Content").font(.caption).foregroundColor(.gray)
                        TextEditor(text: $postContent)
                            .frame(height: 200) // Give it a decent default height
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                            )
                    }

                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }

                Section {
                    Button(action: submitPost) {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                            } else {
                                Text("Submit Post")
                            }
                            Spacer()
                        }
                    }
                    .disabled(postTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              postContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              isSubmitting)
                }
            }
            .navigationTitle("New Forum Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Post Submission"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func submitPost() {
        guard !postTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !postContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Title and content cannot be empty."
            showingAlert = true
            return
        }

        isSubmitting = true

        viewModel.createPost(
            title: postTitle,
            content: postContent,
            category: selectedCategory,
            tags: nil // Add tag input if implemented
        ) { success, error in
            isSubmitting = false
            if success {
                alertMessage = "Post submitted successfully!"
                showingAlert = true
                // Dismiss the view after a short delay or after user taps OK on alert
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Allow alert to show
                     presentationMode.wrappedValue.dismiss()
                }
            } else {
                alertMessage = "Failed to submit post: \(error?.localizedDescription ?? "Unknown error")"
                showingAlert = true
            }
        }
    }
}

struct CreateForumPostView_Previews: PreviewProvider {
    static var previews: some View {
        let mockViewModel = ForumViewModel()
        // You can also simulate a logged-in user via AuthenticationManager if your
        // viewModel.createPost relies on it directly for user info,
        // but here it's encapsulated within the VM.

        return CreateForumPostView()
            .environmentObject(mockViewModel)
    }
}
