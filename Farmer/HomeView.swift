import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @StateObject private var authManager = AuthenticationManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = true
    
    var body: some View {
        VStack(spacing: 20) {
            // App logo
            Image(systemName: "leaf.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(Color("AccentColor"))
                .padding(.bottom, 20)
            
            // Welcome message with user's name
            if let userName = authManager.user?.displayName {
                Text("Welcome, \(userName)!")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
            } else {
                Text("Welcome to Farmer!")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
            }
            
            Text("Your all-in-one farming companion")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 30)
            
            // Dashboard section
            VStack(spacing: 15) {
                dashboardCard(title: "Weather Forecast", icon: "cloud.sun.fill", color: .blue)
                dashboardCard(title: "Disease Detection", icon: "wand.and.stars", color: .purple)
                dashboardCard(title: "Crop Analytics", icon: "chart.xyaxis.line", color: .orange)
            }
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
        .padding()
    }
    
    // Dashboard card component
    private func dashboardCard(title: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 50)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                Text("Coming soon")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// Loading view that can be used for loading states
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

#Preview {
    HomeView()
} 