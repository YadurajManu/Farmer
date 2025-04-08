import SwiftUI

struct AnimatedFarmingIcon: View {
    let imageName: String
    let tint: Color
    
    @State private var isAnimating = false
    @State private var isRotating = false
    @State private var isFloating = false
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(tint.opacity(0.15))
                .frame(width: 220, height: 220)
            
            // Second layer
            Circle()
                .stroke(tint.opacity(0.3), lineWidth: 8)
                .frame(width: 180, height: 180)
                .scaleEffect(isAnimating ? 1.1 : 0.9)
                .animation(
                    Animation.easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            // Icon
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(tint)
                .rotationEffect(Angle(degrees: isRotating ? 360 : 0))
                .offset(y: isFloating ? -5 : 5)
                .animation(
                    Animation.easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                    value: isFloating
                )
        }
        .onAppear {
            isAnimating = true
            isFloating = true
            
            withAnimation(Animation.linear(duration: 20).repeatForever(autoreverses: false)) {
                isRotating = true
            }
        }
    }
}

struct FarmingParticlesView: View {
    @State private var particles: [Particle] = []
    let colors: [Color] = [.green, .blue, .yellow, .orange]
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            // Create initial particles
            for _ in 0..<15 {
                createParticle()
            }
            
            // Timer to create new particles
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                withAnimation {
                    updateParticles()
                }
            }
        }
    }
    
    func createParticle() {
        let particle = Particle(
            position: CGPoint(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
            ),
            size: CGFloat.random(in: 3...6),
            color: colors.randomElement() ?? .green,
            opacity: Double.random(in: 0.3...0.7)
        )
        particles.append(particle)
    }
    
    func updateParticles() {
        // Remove some old particles
        if particles.count > 25 {
            particles.removeFirst(5)
        }
        
        // Create new particles
        for _ in 0..<3 {
            createParticle()
        }
        
        // Update existing particles
        for index in particles.indices {
            var particle = particles[index]
            
            // Move particle upward and slightly to the side
            let newPosition = CGPoint(
                x: particle.position.x + CGFloat.random(in: -5...5),
                y: particle.position.y - CGFloat.random(in: 1...5)
            )
            
            // If particle moves off screen, remove it
            if newPosition.y < 0 || newPosition.x < 0 || newPosition.x > UIScreen.main.bounds.width {
                particles.remove(at: index)
                continue
            }
            
            particle.position = newPosition
            particle.opacity *= 0.98
            
            particles[index] = particle
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let size: CGFloat
    let color: Color
    var opacity: Double
}

#Preview {
    ZStack {
        Color.black.opacity(0.1).ignoresSafeArea()
        VStack {
            AnimatedFarmingIcon(imageName: "leaf.fill", tint: .green)
            Spacer().frame(height: 50)
            AnimatedFarmingIcon(imageName: "cloud.sun.fill", tint: .blue)
        }
        FarmingParticlesView()
    }
} 