import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// Main authentication container view
struct AuthenticationView: View {
    @StateObject private var authManager = AuthenticationManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = true
    
    var body: some View {
        NavigationStack {
            Group {
                switch authManager.authState {
                case .signedIn:
                    HomeView()
                    
                case .signedOut:
                    if !hasCompletedOnboarding {
                        OnboardingView()
                    } else {
                        LoginViewAuth()
                    }
                    
                case .loading:
                    LoadingView()
                }
            }
        }
    }
}

// Login Screen
struct LoginViewAuth: View {
    @StateObject private var authManager = AuthenticationManager()
    @State private var loginDetails = LoginDetails()
    @State private var showForgotPassword = false
    @State private var forgotPasswordEmail = ""
    @State private var showResetSuccessMessage = false
    @State private var navigateToHome = false
    
    // Background gradient
    private let gradientColors: [Color] = [
        Color(red: 0.95, green: 0.97, blue: 0.95),
        Color.white
    ]
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // Header
                    VStack(alignment: .leading) {
                        // App logo
                        HStack {
                            Spacer()
                            Image(systemName: "leaf.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(Color("AccentColor"))
                                .padding(.bottom, 40)
                            Spacer()
                        }
                        
                        HeaderText(
                            title: "Welcome Back",
                            subtitle: "Login to continue managing your farm"
                        )
                    }
                    .padding(.top, 20)
                    
                    // Error message
                    if let errorMessage = authManager.errorMessage {
                        AuthErrorMessage(message: errorMessage)
                    }
                    
                    // Success message for password reset
                    if showResetSuccessMessage {
                        AuthSuccessMessage(message: "Password reset email sent. Please check your inbox.")
                            .onAppear {
                                // Auto-dismiss after 5 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                    showResetSuccessMessage = false
                                }
                            }
                    }
                    
                    // Form fields
                    VStack(spacing: 20) {
                        CustomTextField(
                            placeholder: "Email Address",
                            icon: "envelope",
                            text: $loginDetails.email,
                            keyboardType: .emailAddress
                        )
                        
                        CustomTextField(
                            placeholder: "Password",
                            icon: "lock",
                            text: $loginDetails.password,
                            isSecure: true
                        )
                        
                        // Forgot password link
                        HStack {
                            Spacer()
                            NavigationLink {
                                ForgotPasswordView()
                            } label: {
                                Text("Forgot Password?")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color("AccentColor"))
                            }
                        }
                    }
                    
                    // Login button
                    VStack(spacing: 16) {
                        PrimaryButton(
                            title: "Sign In",
                            icon: "arrow.right",
                            isLoading: authManager.isLoading
                        ) {
                            login()
                        }
                        
                        // OR divider
                        FarmingDivider(text: "OR")
                        
                        // Create account button
                        NavigationLink {
                            SignUpViewAuth()
                        } label: {
                            Text("Create Account")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color("AccentColor"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 55)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color("AccentColor"), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            
            // Home navigation
            NavigationLink(isActive: $navigateToHome) {
                MainTabViewAuth()
            } label: {
                EmptyView()
            }
        }
        .navigationBarHidden(true)
        .onChange(of: authManager.authState) { newValue in
            if newValue == .signedIn {
                navigateToHome = true
            }
        }
    }
    
    private func login() {
        authManager.loginUser(with: loginDetails) { _ in
            // Handle in onChange of authState
        }
    }
    
    private func resetPassword() {
        if !forgotPasswordEmail.isEmpty {
            authManager.resetPassword(for: forgotPasswordEmail) { result in
                forgotPasswordEmail = ""
                
                switch result {
                case .success:
                    showResetSuccessMessage = true
                case .failure:
                    // Error is already set in authManager.errorMessage
                    break
                }
            }
        }
    }
}

// Sign Up Screen
struct SignUpViewAuth: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var authManager = AuthenticationManager()
    @State private var registrationDetails = RegistrationDetails()
    @State private var navigateToHome = false
    @State private var termsAccepted = false
    
    // Background gradient
    private let gradientColors: [Color] = [
        Color(red: 0.95, green: 0.97, blue: 0.95),
        Color.white
    ]
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // Header with back button
                    HStack {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 10)
                    
                    // Title
                    HeaderText(
                        title: "Create Account",
                        subtitle: "Sign up to start managing your farm"
                    )
                    .padding(.top, 10)
                    
                    // Error message
                    if let errorMessage = authManager.errorMessage {
                        AuthErrorMessage(message: errorMessage)
                    }
                    
                    // Form fields
                    VStack(spacing: 20) {
                        CustomTextField(
                            placeholder: "Full Name",
                            icon: "person",
                            text: $registrationDetails.fullName
                        )
                        
                        CustomTextField(
                            placeholder: "Email Address",
                            icon: "envelope",
                            text: $registrationDetails.email,
                            keyboardType: .emailAddress
                        )
                        
                        CustomTextField(
                            placeholder: "Password",
                            icon: "lock",
                            text: $registrationDetails.password,
                            isSecure: true
                        )
                        
                        CustomTextField(
                            placeholder: "Confirm Password",
                            icon: "lock.shield",
                            text: $registrationDetails.confirmPassword,
                            isSecure: true
                        )
                        
                        // Terms and Conditions
                        HStack(alignment: .top, spacing: 10) {
                            Button {
                                termsAccepted.toggle()
                            } label: {
                                Image(systemName: termsAccepted ? "checkmark.square.fill" : "square")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(termsAccepted ? Color("AccentColor") : .gray)
                            }
                            
                            Text("I agree to the Terms and Conditions and Privacy Policy")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Sign Up button
                    VStack(spacing: 16) {
                        PrimaryButton(
                            title: "Create Account",
                            icon: "person.fill.badge.plus",
                            isLoading: authManager.isLoading
                        ) {
                            signUp()
                        }
                        .disabled(!termsAccepted)
                        .opacity(termsAccepted ? 1.0 : 0.6)
                        
                        // OR divider
                        FarmingDivider(text: "OR")
                        
                        // Back to login button
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("Already have an account? Login")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color("AccentColor"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 55)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color("AccentColor"), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            
            // Navigation to home after successful registration
            NavigationLink(isActive: $navigateToHome) {
                MainTabViewAuth()
            } label: {
                EmptyView()
            }
        }
        .navigationBarHidden(true)
        .onChange(of: authManager.authState) { newValue in
            if newValue == .signedIn {
                navigateToHome = true
            }
        }
    }
    
    private func signUp() {
        guard termsAccepted else {
            authManager.errorMessage = "Please accept the terms and conditions"
            return
        }
        
        authManager.registerUser(with: registrationDetails) { _ in
            // Handle in onChange of authState
        }
    }
}

// Main app tabbed view
struct MainTabViewAuth: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        TabView {
            // Dashboard tab
            HomeView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            
            // Disease Prediction tab
            DiseasePredictionView()
                .tabItem {
                    Label("Disease Detection", systemImage: "leaf.circle.fill")
                }
            
            // Profile tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .environmentObject(authManager)
    }
}

// Profile View
struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showSettings = false
    @State private var showNotifications = false
    @State private var showPrivacy = false
    @State private var showHelp = false
    @State private var showAbout = false
    @State private var showEditProfile = false
    @State private var profilePhotoURL: String = ""
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            VStack {
                // User profile header
                VStack(spacing: 16) {
                    // Profile photo with async loading
                    if !profilePhotoURL.isEmpty {
                        AsyncImage(url: URL(string: profilePhotoURL)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 100, height: 100)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 2))
                            case .failure:
                                defaultProfileImage
                            @unknown default:
                                defaultProfileImage
                            }
                        }
                    } else {
                        defaultProfileImage
                    }
                    
                    if let userName = authManager.user?.displayName {
                        Text(userName)
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    
                    if let email = authManager.user?.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Edit profile button
                    Button(action: {
                        showEditProfile = true
                    }) {
                        Text("Edit Profile")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color("AccentColor"))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color("AccentColor"), lineWidth: 1)
                            )
                    }
                    .padding(.top, 5)
                }
                .padding(.bottom, 30)
                
                // Profile options
                VStack(spacing: 0) {
                    NavigationLink(destination: SettingsView()) {
                        profileOptionRow(icon: "gear", title: "Settings")
                    }
                    
                    NavigationLink(destination: NotificationsView()) {
                        profileOptionRow(icon: "bell", title: "Notifications")
                    }
                    
                    NavigationLink(destination: PrivacySecurityView()) {
                        profileOptionRow(icon: "lock.shield", title: "Privacy & Security")
                    }
                    
                    NavigationLink(destination: HelpSupportView()) {
                        profileOptionRow(icon: "questionmark.circle", title: "Help & Support")
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        profileOptionRow(icon: "info.circle", title: "About")
                    }
                }
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                Spacer()
                
                // Sign out button
                Button(action: {
                    authManager.signOut()
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(Color.red)
                    .cornerRadius(30)
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showEditProfile, onDismiss: {
                loadProfileData()
                authManager.checkAuthState()
            }) {
                EditProfileView()
            }
            .onAppear {
                loadProfileData()
            }
        }
    }
    
    private var defaultProfileImage: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
            .foregroundColor(Color("AccentColor"))
    }
    
    private func loadProfileData() {
        guard let user = authManager.user else { return }
        
        // First check if user has a photoURL in Auth
        if let photoURL = user.photoURL?.absoluteString, !photoURL.isEmpty {
            profilePhotoURL = photoURL
        } else {
            // If not, check Firestore for a photoURL
            db.collection("users").document(user.uid).getDocument { document, error in
                if let document = document, document.exists,
                   let data = document.data(),
                   let photoURL = data["photoURL"] as? String,
                   !photoURL.isEmpty {
                    DispatchQueue.main.async {
                        profilePhotoURL = photoURL
                    }
                }
            }
        }
    }
    
    private func profileOptionRow(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 30)
                .foregroundColor(Color("AccentColor"))
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
    }
}

// Edit Profile View
struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var displayName: String = ""
    @State private var photoURL: String = ""
    @State private var phone: String = ""
    @State private var location: String = ""
    @State private var bio: String = ""
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0.0
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Photo")) {
                    HStack {
                        Spacer()
                        
                        ZStack {
                            if let selectedImage = selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 2))
                            } else if !photoURL.isEmpty {
                                AsyncImage(url: URL(string: photoURL)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .clipShape(Circle())
                                    case .failure:
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundColor(Color("AccentColor"))
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 2))
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(Color("AccentColor"))
                            }
                            
                            if isUploading {
                                Circle()
                                    .trim(from: 0, to: CGFloat(uploadProgress))
                                    .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                    .foregroundColor(Color("AccentColor"))
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: 110, height: 110)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    
                    Button("Change Photo") {
                        showImagePicker = true
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                Section(header: Text("Personal Information")) {
                    TextField("Display Name", text: $displayName)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Location", text: $location)
                }
                
                Section(header: Text("About")) {
                    TextEditor(text: $bio)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button(action: saveProfile) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Save Changes")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(isLoading)
                }
            }
            .onAppear(perform: loadUserProfile)
            .navigationTitle("Edit Profile")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Profile Update"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if alertMessage.contains("successfully") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
        }
    }
    
    private func loadUserProfile() {
        guard let user = authManager.user else { return }
        
        isLoading = true
        
        // Get basic profile info from Auth
        displayName = user.displayName ?? ""
        photoURL = user.photoURL?.absoluteString ?? ""
        
        // Get additional profile data from Firestore
        db.collection("users").document(user.uid).getDocument { document, error in
            isLoading = false
            
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                let data = document.data() ?? [:]
                
                // Update UI with Firestore data
                DispatchQueue.main.async {
                    phone = data["phone"] as? String ?? ""
                    location = data["location"] as? String ?? ""
                    bio = data["bio"] as? String ?? ""
                    
                    // If photoURL is empty in Auth but exists in Firestore
                    if photoURL.isEmpty {
                        photoURL = data["photoURL"] as? String ?? ""
                    }
                }
            } else {
                // Create user document if it doesn't exist
                let userData: [String: Any] = [
                    "email": user.email ?? "",
                    "displayName": displayName,
                    "createdAt": FieldValue.serverTimestamp()
                ]
                
                db.collection("users").document(user.uid).setData(userData) { error in
                    if let error = error {
                        print("Error creating user document: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func saveProfile() {
        guard let user = authManager.user else { return }
        
        isLoading = true
        
        // If image was selected, upload it first
        if let selectedImage = selectedImage {
            uploadImage(selectedImage, userId: user.uid) { result in
                switch result {
                case .success(let imageUrl):
                    // Now update Auth profile and Firestore with the image URL
                    updateAuthProfile(userId: user.uid, displayName: displayName, photoURL: imageUrl)
                case .failure(let error):
                    isLoading = false
                    alertMessage = "Failed to upload image: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        } else {
            // No image to upload, just update profile
            updateAuthProfile(userId: user.uid, displayName: displayName, photoURL: nil)
        }
    }
    
    private func uploadImage(_ image: UIImage, userId: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            completion(.failure(NSError(domain: "com.farmer.app", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image"])))
            return
        }
        
        isUploading = true
        uploadProgress = 0.0
        
        // Create a storage reference
        let profilePicsRef = storage.child("profile_images/\(userId)_\(UUID().uuidString).jpg")
        
        // Upload the image
        let uploadTask = profilePicsRef.putData(imageData, metadata: nil) { metadata, error in
            isUploading = false
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Get download URL
            profilePicsRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let downloadURL = url {
                    completion(.success(downloadURL))
                } else {
                    completion(.failure(NSError(domain: "com.farmer.app", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                }
            }
        }
        
        // Track upload progress
        uploadTask.observe(.progress) { snapshot in
            if let progress = snapshot.progress {
                let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                DispatchQueue.main.async {
                    self.uploadProgress = percentComplete
                }
            }
        }
    }
    
    private func updateAuthProfile(userId: String, displayName: String, photoURL: URL?) {
        // Update Firebase Auth profile
        authManager.updateProfile(displayName: displayName, photoURL: photoURL) { result in
            switch result {
            case .success:
                // Now update additional data in Firestore
                var userData: [String: Any] = [
                    "displayName": displayName,
                    "phone": phone,
                    "location": location,
                    "bio": bio,
                    "updatedAt": FieldValue.serverTimestamp()
                ]
                
                if let photoURL = photoURL {
                    userData["photoURL"] = photoURL.absoluteString
                }
                
                // Update Firestore document
                self.db.collection("users").document(userId).setData(userData, merge: true) { error in
                    DispatchQueue.main.async {
                        isLoading = false
                        
                        if let error = error {
                            alertMessage = "Error saving data: \(error.localizedDescription)"
                            showAlert = true
                            return
                        }
                        
                        alertMessage = "Profile updated successfully!"
                        showAlert = true
                        
                        // Refresh user data in auth manager
                        authManager.checkAuthState()
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    isLoading = false
                    alertMessage = "Error updating profile: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}

// Settings View
struct SettingsView: View {
    @AppStorage("pushNotifications") private var pushNotificationsEnabled = true
    @AppStorage("emailNotifications") private var emailNotificationsEnabled = true
    @AppStorage("darkMode") private var darkModeEnabled = false
    @State private var selectedLanguage = "English"
    @State private var locationUseEnabled = true
    @State private var showDeleteAccountAlert = false
    @State private var showDeleteAccountConfirmation = false
    @State private var deleteAccountPassword = ""
    @State private var showPasswordField = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                Toggle("Dark Mode", isOn: $darkModeEnabled)
                
                Picker("Language", selection: $selectedLanguage) {
                    Text("English").tag("English")
                    Text("Hindi").tag("Hindi")
                    Text("Spanish").tag("Spanish")
                }
            }
            
            Section(header: Text("App Permissions")) {
                Toggle("Location Services", isOn: $locationUseEnabled)
                    .onChange(of: locationUseEnabled) { newValue in
                        // Here we would request location permissions
                    }
            }
            
            Section(header: Text("Data Management")) {
                Button("Clear Cache") {
                    // Implement cache clearing functionality
                }
                
                Button("Export Data") {
                    // Implement data export
                }
            }
            
            Section(header: Text("Account")) {
                NavigationLink(destination: ChangePasswordView()) {
                    Text("Change Password")
                }
                
                Button("Delete Account") {
                    showDeleteAccountAlert = true
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Settings")
        .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                showDeleteAccountConfirmation = true
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
        .alert("Confirm Deletion", isPresented: $showDeleteAccountConfirmation) {
            Button("Cancel", role: .cancel) { 
                deleteAccountPassword = ""
                showPasswordField = false
            }
            
            if showPasswordField {
                SecureField("Enter your password", text: $deleteAccountPassword)
                Button("Delete Account", role: .destructive) {
                    deleteAccount()
                }
            } else {
                Button("Confirm", role: .destructive) {
                    showPasswordField = true
                }
            }
        } message: {
            if showPasswordField {
                Text("Please enter your password to confirm account deletion")
            } else {
                Text("This will permanently delete your account and all your data. Are you absolutely sure?")
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func deleteAccount() {
        guard !deleteAccountPassword.isEmpty else {
            errorMessage = "Please enter your password"
            showErrorAlert = true
            return
        }
        
        authManager.deleteAccount(password: deleteAccountPassword) { result in
            switch result {
            case .success:
                // Account deleted - AuthManager will handle sign out
                break
            case .failure(let error):
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}

// Change Password View
struct ChangePasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    var body: some View {
        Form {
            Section(header: Text("Current Password")) {
                SecureField("Current Password", text: $currentPassword)
            }
            
            Section(header: Text("New Password")) {
                SecureField("New Password", text: $newPassword)
                SecureField("Confirm New Password", text: $confirmPassword)
                
                Text("Password must be at least 6 characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                Button(action: changePassword) {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Update Password")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .disabled(authManager.isLoading || currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
            }
        }
        .navigationTitle("Change Password")
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(isSuccess ? "Success" : "Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if isSuccess {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
    }
    
    private func changePassword() {
        // Validate new password
        if newPassword.count < 6 {
            alertMessage = "Password must be at least 6 characters"
            showAlert = true
            return
        }
        
        // Check if passwords match
        if newPassword != confirmPassword {
            alertMessage = "New passwords do not match"
            showAlert = true
            return
        }
        
        // Change password
        authManager.changePassword(from: currentPassword, to: newPassword) { result in
            switch result {
            case .success:
                isSuccess = true
                alertMessage = "Password updated successfully"
                showAlert = true
            case .failure(let error):
                isSuccess = false
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
}

// Notifications View
struct NotificationsView: View {
    @AppStorage("pushNotifications") private var pushNotificationsEnabled = true
    @AppStorage("emailNotifications") private var emailNotificationsEnabled = true
    @AppStorage("weatherAlerts") private var weatherAlertsEnabled = true
    @AppStorage("diseaseAlerts") private var diseaseAlertsEnabled = true
    @AppStorage("marketPriceAlerts") private var marketPriceAlertsEnabled = false
    
    var body: some View {
        Form {
            Section(header: Text("General")) {
                Toggle("Push Notifications", isOn: $pushNotificationsEnabled)
                Toggle("Email Notifications", isOn: $emailNotificationsEnabled)
            }
            
            Section(header: Text("Alert Types")) {
                Toggle("Weather Alerts", isOn: $weatherAlertsEnabled)
                Toggle("Disease Detection Alerts", isOn: $diseaseAlertsEnabled)
                Toggle("Market Price Alerts", isOn: $marketPriceAlertsEnabled)
            }
            
            Section(header: Text("Frequency")) {
                Picker("Notification Frequency", selection: .constant("Daily")) {
                    Text("Real-time").tag("Real-time")
                    Text("Daily").tag("Daily")
                    Text("Weekly").tag("Weekly")
                }
            }
        }
        .navigationTitle("Notifications")
    }
}

// Privacy & Security View
struct PrivacySecurityView: View {
    @State private var biometricAuthEnabled = false
    @State private var dataCollectionEnabled = true
    
    var body: some View {
        Form {
            Section(header: Text("Security")) {
                Toggle("Use Face ID / Touch ID", isOn: $biometricAuthEnabled)
                
                NavigationLink(destination: Text("Two-Factor Authentication")) {
                    Text("Two-Factor Authentication")
                }
            }
            
            Section(header: Text("Privacy")) {
                Toggle("Allow Data Collection", isOn: $dataCollectionEnabled)
                
                NavigationLink(destination: Text("Data Collection Details")) {
                    Text("Manage Data Collection")
                }
                
                NavigationLink(destination: Text("Privacy Policy")) {
                    Text("Privacy Policy")
                }
            }
        }
        .navigationTitle("Privacy & Security")
    }
}

// Help & Support View
struct HelpSupportView: View {
    var body: some View {
        List {
            Section(header: Text("Help Center")) {
                NavigationLink(destination: FAQView()) {
                    Label("Frequently Asked Questions", systemImage: "questionmark.circle")
                }
                
                NavigationLink(destination: Text("User Guide")) {
                    Label("User Guide", systemImage: "book")
                }
                
                NavigationLink(destination: Text("Tutorials")) {
                    Label("Video Tutorials", systemImage: "play.circle")
                }
            }
            
            Section(header: Text("Contact Us")) {
                Button(action: {
                    // Open email app
                    if let url = URL(string: "mailto:support@farmerapp.com") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("Email Support", systemImage: "envelope")
                }
                
                Button(action: {
                    // Open phone app
                    if let url = URL(string: "tel:+911234567890") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("Call Support", systemImage: "phone")
                }
                
                NavigationLink(destination: Text("Chat Support")) {
                    Label("Live Chat", systemImage: "message")
                }
            }
            
            Section(header: Text("Feedback")) {
                NavigationLink(destination: Text("Bug Report")) {
                    Label("Report a Bug", systemImage: "ant")
                }
                
                NavigationLink(destination: Text("Feature Request")) {
                    Label("Request a Feature", systemImage: "star")
                }
            }
        }
        .navigationTitle("Help & Support")
    }
}

// FAQ View
struct FAQView: View {
    var body: some View {
        List {
            Section {
                FAQItem(question: "How do I scan plants for diseases?", 
                        answer: "Open the Disease Detection tab, tap on 'Upload Image' and take a photo of your plant. Our AI will analyze the image and provide results.")
                
                FAQItem(question: "How accurate is the disease detection?", 
                        answer: "Our disease detection system has an accuracy of approximately 85% for common plant diseases. For best results, ensure good lighting and clear focus.")
                
                FAQItem(question: "Can I use this app offline?", 
                        answer: "Basic features work offline, but disease detection and weather updates require an internet connection.")
                
                FAQItem(question: "How do I reset my password?", 
                        answer: "Go to the login screen, tap on 'Forgot Password', and follow the instructions sent to your email.")
            }
        }
        .navigationTitle("FAQs")
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(question)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
            }
            
            if isExpanded {
                Text(answer)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
            }
        }
        .padding(.vertical, 5)
    }
}

// About View
struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // App logo
                Image(systemName: "leaf.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(Color("AccentColor"))
                    .padding(.top, 30)
                
                // App name and version
                VStack(spacing: 5) {
                    Text("Farmer")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("Version 1.0.0")
                        .foregroundColor(.secondary)
                }
                
                // Description
                Text("Farmer is your all-in-one farming companion app designed to help farmers monitor crop health, detect diseases, and get weather updates.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Divider()
                    .padding(.vertical)
                
                // Team info
                VStack(alignment: .leading, spacing: 20) {
                    Text("Development Team")
                        .font(.headline)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Yaduraj Singh")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text("Lead Developer")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.vertical)
                
                // Legal info
                VStack(spacing: 15) {
                    Button("Terms of Service") {
                        // Open terms of service
                    }
                    
                    Button("Privacy Policy") {
                        // Open privacy policy
                    }
                    
                    Button("Open Source Licenses") {
                        // Open licenses
                    }
                }
                
                Text("© 2024 Farmer App. All rights reserved.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 30)
                    .padding(.bottom, 50)
            }
            .padding()
        }
        .navigationTitle("About")
    }
}

// MARK: - Shared Components

// Loading view for auth and other screens
struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(2)
            
            Text("Loading...")
                .font(.system(size: 16, weight: .semibold))
                .padding(.top, 20)
        }
    }
}

// Preview
struct AuthViews_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
} 