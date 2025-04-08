import SwiftUI

// MARK: - CustomTextField
struct CustomTextField: View {
    var placeholder: String
    var icon: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    @State private var isShowingPassword: Bool = false
    
    var body: some View {
        HStack {
            // Icon
            Image(systemName: icon)
                .foregroundColor(Color("AccentColor"))
                .frame(width: 20)
                .padding(.leading, 12)
            
            // TextField / SecureField
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(Color.gray.opacity(0.7))
                }
                
                if isSecure && !isShowingPassword {
                    SecureField("", text: $text)
                        .keyboardType(keyboardType)
                } else {
                    TextField("", text: $text)
                        .keyboardType(keyboardType)
                }
            }
            .padding(.leading, 8)
            
            // Show/hide password button for secure fields
            if isSecure {
                Button(action: {
                    isShowingPassword.toggle()
                }) {
                    Image(systemName: isShowingPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 12)
            }
        }
        .frame(height: 55)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// MARK: - PrimaryButton
struct PrimaryButton: View {
    var title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            if !isLoading {
                action()
            }
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 8)
                }
                
                if let icon = icon, !isLoading {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("AccentColor"))
                    .opacity(isLoading ? 0.8 : 1)
            )
            .shadow(color: Color("AccentColor").opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(isLoading)
    }
}

// MARK: - SecondaryButton
struct SecondaryButton: View {
    var title: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
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
}

// MARK: - FarmingDivider
struct FarmingDivider: View {
    var text: String
    
    var body: some View {
        HStack {
            VStack { Divider() }.padding(.trailing, 15)
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            VStack { Divider() }.padding(.leading, 15)
        }
    }
}

// MARK: - AuthErrorMessage
struct AuthErrorMessage: View {
    var message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.red)
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.1))
        )
    }
}

// MARK: - AuthSuccessMessage
struct AuthSuccessMessage: View {
    var message: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.green)
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.1))
        )
    }
}

// MARK: - SocialLoginButton
struct SocialLoginButton: View {
    var icon: String
    var title: String
    var backgroundColor: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
            )
        }
    }
}

// MARK: - HeaderText
struct HeaderText: View {
    var title: String
    var subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - PreviewProvider
#Preview {
    VStack(spacing: 20) {
        CustomTextField(placeholder: "Email Address", icon: "envelope", text: .constant(""))
        CustomTextField(placeholder: "Password", icon: "lock", text: .constant(""), isSecure: true)
        PrimaryButton(title: "Sign In", action: {})
        PrimaryButton(title: "Loading...", isLoading: true, action: {})
        SecondaryButton(title: "Create Account", action: {})
        FarmingDivider(text: "OR CONTINUE WITH")
        AuthErrorMessage(message: "Invalid email address")
        AuthSuccessMessage(message: "Password reset email sent")
    }
    .padding()
} 