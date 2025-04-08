import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var backgroundOffset = -100.0
    
    // Custom farm-themed colors
    private let primaryColor = Color("AccentColor")
    private let secondaryColor = Color.green
    
    // Background gradient colors
    private let gradientColors: [Color] = [
        Color(red: 0.95, green: 0.97, blue: 0.95),
        Color.white
    ]
    
    let onboardingData: [OnboardingPage] = [
        OnboardingPage(
            image: "leaf.fill",
            title: "Welcome",
            description: "Your complete farming companion for weather insights and crop health.",
            tintColor: .green,
            bgShape: "wave1"
        ),
        OnboardingPage(
            image: "cloud.sun.fill",
            title: "Weather",
            description: "Get real-time weather updates tailored for your farm location.",
            tintColor: .blue,
            bgShape: "wave2"
        ),
        OnboardingPage(
            image: "wand.and.stars",
            title: "Disease Detection",
            description: "Identify crop diseases early with our advanced AI technology.",
            tintColor: .purple,
            bgShape: "wave3"
        ),
        OnboardingPage(
            image: "chart.xyaxis.line",
            title: "Analytics",
            description: "Track growth patterns and optimize your farming practices.",
            tintColor: .orange,
            bgShape: "wave4"
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with subtle animation
                LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                // Abstract shape
                getBackgroundShape(for: currentPage)
                    .offset(x: backgroundOffset, y: geometry.size.height * 0.05)
                    .opacity(0.15)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 20).repeatForever(autoreverses: true)) {
                            backgroundOffset = 100.0
                        }
                    }
                
                VStack(spacing: 0) {
                    // Logo or branding
                    HStack {
                        Text("FARMER")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .tracking(5)
                            .foregroundColor(primaryColor)
                            .padding(.top, geometry.safeAreaInsets.top + 16)
                            .padding(.leading, 24)
                        Spacer()
                    }
                    
                    // Main content area
                    ZStack {
                        // Content
                        TabView(selection: $currentPage) {
                            ForEach(0..<onboardingData.count, id: \.self) { index in
                                EnhancedOnboardingPageView(
                                    page: onboardingData[index],
                                    screenWidth: geometry.size.width,
                                    screenHeight: geometry.size.height
                                )
                                .tag(index)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .animation(.easeInOut, value: currentPage)
                    }
                    .frame(height: geometry.size.height * 0.75)
                    
                    // Bottom navigation area
                    VStack(spacing: 40) {
                        // Progress indicator
                        HStack(spacing: 12) {
                            ForEach(0..<onboardingData.count, id: \.self) { index in
                                Capsule()
                                    .fill(currentPage == index ? onboardingData[index].tintColor : Color.gray.opacity(0.2))
                                    .frame(width: currentPage == index ? 20 : 8, height: 8)
                                    .animation(.spring(), value: currentPage)
                            }
                        }
                        
                        // Action buttons
                        HStack {
                            // Skip button
                            if currentPage < onboardingData.count - 1 {
                                Button {
                                    withAnimation(.easeOut) {
                                        hasCompletedOnboarding = true
                                    }
                                } label: {
                                    Text("Skip")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 20)
                            } else {
                                Spacer()
                            }
                            
                            Spacer()
                            
                            // Next/Start button
                            Button {
                                if currentPage < onboardingData.count - 1 {
                                    withAnimation {
                                        currentPage += 1
                                    }
                                } else {
                                    withAnimation(.easeOut) {
                                        hasCompletedOnboarding = true
                                    }
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Text(currentPage < onboardingData.count - 1 ? "Next" : "Get Started")
                                        .font(.system(size: 16, weight: .semibold))
                                    
                                    Image(systemName: currentPage < onboardingData.count - 1 ? "arrow.right" : "checkmark")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 15)
                                .padding(.horizontal, 25)
                                .background(onboardingData[currentPage].tintColor)
                                .cornerRadius(30)
                                .shadow(color: onboardingData[currentPage].tintColor.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 16)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: currentPage)
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    @ViewBuilder
    private func getBackgroundShape(for page: Int) -> some View {
        let shapeName = onboardingData[page].bgShape
        
        switch shapeName {
            case "wave1":
                WaveShape(amplitude: 120, frequency: 0.3, phase: 0)
                    .fill(onboardingData[page].tintColor.opacity(0.2))
                    .frame(height: 400)
            case "wave2":
                WaveShape(amplitude: 100, frequency: 0.2, phase: .pi/4)
                    .fill(onboardingData[page].tintColor.opacity(0.2))
                    .frame(height: 400)
            case "wave3":
                WaveShape(amplitude: 150, frequency: 0.5, phase: .pi/2)
                    .fill(onboardingData[page].tintColor.opacity(0.2))
                    .frame(height: 400)
            case "wave4":
                WaveShape(amplitude: 130, frequency: 0.4, phase: .pi)
                    .fill(onboardingData[page].tintColor.opacity(0.2))
                    .frame(height: 400)
            default:
                WaveShape(amplitude: 120, frequency: 0.3, phase: 0)
                    .fill(onboardingData[page].tintColor.opacity(0.2))
                    .frame(height: 400)
        }
    }
}

struct WaveShape: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath()
        
        // Start at the bottom left corner
        path.move(to: CGPoint(x: 0, y: rect.height))
        
        // Draw wave
        for x in stride(from: 0, to: rect.width, by: 1) {
            let relativeX = x / rect.width
            let sine = sin(relativeX * .pi * frequency + phase)
            let y = amplitude * sine + rect.height/2
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // Line to bottom right
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        
        // Close the path
        path.close()
        
        return Path(path.cgPath)
    }
}

struct OnboardingPage: Identifiable {
    var id = UUID()
    var image: String
    var title: String
    var description: String
    var tintColor: Color
    var bgShape: String
}

struct EnhancedOnboardingPageView: View {
    var page: OnboardingPage
    var screenWidth: CGFloat
    var screenHeight: CGFloat
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 40) {
            // Icon in circular background with soft shadow
            ZStack {
                Circle()
                    .fill(page.tintColor.opacity(0.1))
                    .frame(width: screenWidth * 0.5, height: screenWidth * 0.5)
                
                // Second decorative circle
                Circle()
                    .stroke(page.tintColor.opacity(0.2), lineWidth: 15)
                    .frame(width: screenWidth * 0.4, height: screenWidth * 0.4)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                    .animation(
                        Animation.easeInOut(duration: 3)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                Image(systemName: page.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: screenWidth * 0.2, height: screenWidth * 0.2)
                    .foregroundColor(page.tintColor)
                    .shadow(color: page.tintColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 50)
            
            // Text content
            VStack(spacing: 24) {
                Text(page.title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                
                Text(page.description)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 15)
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
        .onDisappear {
            isAnimating = false
        }
    }
}

#Preview {
    OnboardingView()
} 