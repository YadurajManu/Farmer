import SwiftUI
import FirebaseAuth

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
                            Button("Forgot Password?") {
                                showForgotPassword = true
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color("AccentColor"))
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
        .alert("Reset Password", isPresented: $showForgotPassword) {
            TextField("Email", text: $forgotPasswordEmail)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            Button("Cancel", role: .cancel) {
                forgotPasswordEmail = ""
            }
            
            Button("Reset") {
                resetPassword()
            }
        } message: {
            Text("Enter your email address and we'll send you a link to reset your password.")
        }
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
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some View {
        TabView {
            // Home tab
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            // Profile tab with logout button
            VStack {
                Text("Profile")
                    .font(.largeTitle)
                
                Spacer()
                
                Button("Log Out") {
                    authManager.signOut()
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(8)
                
                Spacer()
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
        }
    }
}

// Preview
struct AuthViews_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
} 