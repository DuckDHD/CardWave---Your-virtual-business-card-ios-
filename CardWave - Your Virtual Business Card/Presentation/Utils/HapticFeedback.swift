import Foundation
import UIKit

class HapticFeedback {
    static let shared = HapticFeedback()
    
    private init() {}
    
    func playTransferStarted() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func playTransferCompleted() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Add a slight delay for the second feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
            impactGenerator.impactOccurred()
        }
    }
    
    func playTransferFailed() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    func playTransferProgress() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.5)
    }
}