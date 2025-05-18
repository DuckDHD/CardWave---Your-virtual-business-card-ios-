import SwiftUI

struct TransferStatusView: View {
    enum TransferStatus: Equatable {
        case preparing
        case searching
        case connecting
        case transferring(progress: Double)
        case completed
        case failed(message: String)
        
        var title: String {
            switch self {
            case .preparing:
                return "Preparing"
            case .searching:
                return "Searching for device"
            case .connecting:
                return "Connecting"
            case .transferring:
                return "Transferring"
            case .completed:
                return "Completed"
            case .failed:
                return "Failed"
            }
        }
        
        var systemImage: String {
            switch self {
            case .preparing:
                return "gear"
            case .searching:
                return "antenna.radiowaves.left.and.right"
            case .connecting:
                return "link"
            case .transferring:
                return "arrow.left.arrow.right"
            case .completed:
                return "checkmark.circle"
            case .failed:
                return "xmark.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .preparing, .searching, .connecting:
                return .blue
            case .transferring:
                return .orange
            case .completed:
                return .green
            case .failed:
                return .red
            }
        }
        
        // Custom implementation of Equatable for TransferStatus
        static func == (lhs: TransferStatus, rhs: TransferStatus) -> Bool {
            switch (lhs, rhs) {
            case (.preparing, .preparing),
                 (.searching, .searching),
                 (.connecting, .connecting),
                 (.completed, .completed):
                return true
            case let (.transferring(lhsProgress), .transferring(rhsProgress)):
                return lhsProgress == rhsProgress
            case let (.failed(lhsMessage), .failed(rhsMessage)):
                return lhsMessage == rhsMessage
            default:
                return false
            }
        }
    }
    
    @Binding var status: TransferStatus
    let isReceiving: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: status.systemImage)
                    .font(.system(size: 20))
                    .foregroundColor(status.color)
                    .symbolEffect(.pulse, options: .repeating, value: isAnimating)
                
                Text(status.title)
                    .font(.headline)
                    .foregroundColor(status.color)
                
                if case .transferring(let progress) = status {
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if case .transferring(let progress) = status {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: status.color))
            }
            
            if case .failed(let message) = status {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .animation(.easeInOut, value: status)
    }
    
    private var isAnimating: Bool {
        switch status {
        case .preparing, .searching, .connecting, .transferring:
            return true
        case .completed, .failed:
            return false
        }
    }
}
