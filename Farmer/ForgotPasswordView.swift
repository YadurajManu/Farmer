import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthenticationManager()
    @State private var email = ""
    @State private var showSuccessAlert = false
    @State private var isEmailSent = false
    @FocusState private var isEmailFieldFocused: Bool
    
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
            
            VStack(spacing: 30) {
                // Header
                VStack(alignment: .center, spacing: 20) {
                    // Back button
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                    }
                    
                    // Icon
                    Image(systemName: "lock.shield")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(Color("AccentColor"))
                        .padding(.top, 20)
                    
                    Text("Reset Your Password")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                    
                    Text("Enter your email address and we'll send you a link to reset your password")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Error message
                if let errorMessage = authManager.errorMessage {
                    AuthErrorMessage(message: errorMessage)
                }
                
                // Success message
                if isEmailSent {
                    AuthSuccessMessage(message: "Password reset email sent. Please check your inbox and follow the instructions.")
                }
                
                // Form
                VStack(spacing: 20) {
                    if !isEmailSent {
                        CustomTextField(
                            placeholder: "Email Address",
                            icon: "envelope",
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        .focused($isEmailFieldFocused)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .submitLabel(.send)
                        .onSubmit {
                            resetPassword()
                        }
                        
                        // Submit button
                        PrimaryButton(
                            title: "Send Reset Link",
                            icon: "envelope.badge",
                            isLoading: authManager.isLoading
                        ) {
                            resetPassword()
                        }
                    } else {
                        // Actions after email is sent
                        VStack(spacing: 16) {
                            Button {
                                // Open mail app if available
                                if let url = URL(string: "message://") {
                                    if UIApplication.shared.canOpenURL(url) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                    Text("Open Mail App")
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color("AccentColor"))
                                .cornerRadius(12)
                            }
                            
                            Button {
                                email = ""
                                isEmailSent = false
                                authManager.errorMessage = nil
                                DispatchQueue.main.async {
                                    isEmailFieldFocused = true
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "envelope.badge")
                                    Text("Use Different Email")
                                }
                                .foregroundColor(Color("AccentColor"))
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color("AccentColor"), lineWidth: 1)
                                )
                            }
                        }
                    }
                    
                    // Back to login button
                    Button {
                        dismiss()
                    } label: {
                        Text("Back to Login")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 10)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 5) {
                    Text("Can't access your email?")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Button {
                        // This could lead to a contact support page
                        // For now just dismiss
                        dismiss()
                    } label: {
                        Text("Contact Support")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color("AccentColor"))
                    }
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isEmailFieldFocused = true
            }
        }
    }
    
    private func resetPassword() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        authManager.resetPassword(for: email) { result in
            switch result {
            case .success:
                isEmailSent = true
            case .failure:
                // Error is already set in authManager.errorMessage
                break
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
} 