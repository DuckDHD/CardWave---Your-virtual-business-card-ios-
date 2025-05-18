import SwiftUI

struct NFCAnimationView: View {
    enum TransferState {
        case waiting
        case connecting
        case transferring
        case completed
        case failed
    }
    
    @State private var waveAnimation: CGFloat = 0
    @State private var rotationAnimation: Double = 0
    @State private var scaleAnimation: CGFloat = 1
    @State private var particlesAnimation: Bool = false
    @State private var transferProgress: CGFloat = 0
    @State private var transferState: TransferState = .waiting
    @State private var showCompletionEffect: Bool = false
    
    let isReceiving: Bool
    let transferCompleted: Bool
    
    init(isReceiving: Bool = false, transferCompleted: Bool = false) {
        self.isReceiving = isReceiving
        self.transferCompleted = transferCompleted
    }
    
    var body: some View {
        ZStack {
            // Background waves
            ForEach(0..<3) { i in
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                isReceiving ? Color.green.opacity(0.7) : Color.blue.opacity(0.7),
                                isReceiving ? Color.green.opacity(0.2) : Color.blue.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .scaleEffect(waveAnimation + CGFloat(i) * 0.3)
                    .opacity(1.0 - Double(i) * 0.2)
            }
            
            // Transfer particles (only show during transferring state)
            if transferState == .transferring || transferState == .completed {
                TransferParticlesView(
                    isActive: $particlesAnimation,
                    isReceiving: isReceiving,
                    progress: $transferProgress
                )
            }
            
            // Phone icons
            HStack(spacing: 50) {
                // Sending phone
                Image(systemName: "iphone")
                    .font(.system(size: 40))
                    .foregroundColor(isReceiving ? .secondary : .blue)
                    .rotationEffect(.degrees(isReceiving ? 0 : rotationAnimation))
                    .scaleEffect(isReceiving ? 1 : scaleAnimation)
                    .overlay(
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .scaleEffect(isReceiving ? 0 : (transferState == .transferring ? 0.3 : 0))
                            .blur(radius: 5)
                    )
                
                // Receiving phone
                Image(systemName: "iphone")
                    .font(.system(size: 40))
                    .foregroundColor(isReceiving ? .green : .secondary)
                    .rotationEffect(.degrees(isReceiving ? rotationAnimation : 0))
                    .scaleEffect(isReceiving ? scaleAnimation : 1)
                    .overlay(
                        Circle()
                            .fill(Color.green.opacity(0.3))
                            .scaleEffect(isReceiving ? (transferState == .transferring ? 0.3 : 0) : 0)
                            .blur(radius: 5)
                    )
            }
            
            // Success checkmark overlay (only show when completed)
            if showCompletionEffect {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                    )
                    .transition(.scale.combined(with: .opacity))
            }
            
            // Error X overlay (only show when failed)
            if transferState == .failed {
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                    )
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: transferCompleted) { newValue in
            if newValue {
                completeTransfer()
            }
        }
    }
    
    private func startAnimations() {
        // Initial waiting state
        transferState = .waiting
        
        // Start wave animations
        withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            waveAnimation = 1.3
        }
        
        // After a short delay, transition to connecting state
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            transferState = .connecting
            
            // Start subtle rotation and scale animations
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                rotationAnimation = 5
                scaleAnimation = 1.1
            }
            
            // After another delay, transition to transferring state
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                transferState = .transferring
                
                // Start particle animations
                particlesAnimation = true
                
                // Animate transfer progress
                withAnimation(Animation.easeInOut(duration: 3.0)) {
                    transferProgress = 1.0
                }
            }
        }
    }
    
    private func completeTransfer() {
        transferState = .completed
        
        // Stop the ongoing animations
        withAnimation(.easeOut(duration: 0.5)) {
            waveAnimation = 1.5
            rotationAnimation = 0
            scaleAnimation = 1.0
        }
        
        // Show completion effect
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            showCompletionEffect = true
        }
    }
}

// Particle animation for data transfer visualization
struct TransferParticlesView: View {
    @Binding var isActive: Bool
    let isReceiving: Bool
    @Binding var progress: CGFloat
    
    @State private var particles: [Particle] = []
    
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
            generateParticles()
        }
        .onChange(of: isActive) { newValue in
            if newValue {
                generateParticles()
            }
        }
    }
    
    private func generateParticles() {
        particles = []
        
        // Create 15 particles
        for _ in 0..<15 {
            let startX: CGFloat = isReceiving ? 200 : 50
            let endX: CGFloat = isReceiving ? 50 : 200
            
            let particle = Particle(
                id: UUID(),
                position: CGPoint(x: startX, y: 100 + CGFloat.random(in: -30...30)),
                color: isReceiving ? Color.green : Color.blue,
                size: CGFloat.random(in: 4...8),
                speed: Double.random(in: 0.5...2.0),
                delay: Double.random(in: 0...3.0),
                startPosition: CGPoint(x: startX, y: 100 + CGFloat.random(in: -30...30)),
                endPosition: CGPoint(x: endX, y: 100 + CGFloat.random(in: -30...30)),
                opacity: 0
            )
            
            particles.append(particle)
        }
        
        // Animate each particle
        for i in 0..<particles.count {
            let particle = particles[i]
            
            // Fade in
            withAnimation(Animation.easeIn(duration: 0.3).delay(particle.delay)) {
                particles[i].opacity = 1
            }
            
            // Move from start to end
            withAnimation(Animation.easeInOut(duration: particle.speed).delay(particle.delay).repeatForever(autoreverses: false)) {
                particles[i].position = particle.endPosition
            }
        }
    }
}

// Particle model for transfer animation
struct Particle: Identifiable {
    let id: UUID
    var position: CGPoint
    let color: Color
    let size: CGFloat
    let speed: Double
    let delay: Double
    let startPosition: CGPoint
    let endPosition: CGPoint
    var opacity: Double
}