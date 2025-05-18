import SwiftUI

struct ActionButton: View {
    var title: String
    var subtitle: String
    var systemImage: String
    var color: Color
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundColor(color)
                .padding(.trailing, 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Preview
struct ActionButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ActionButton(
                title: "Send Contact",
                subtitle: "Share your contact info",
                systemImage: "arrow.up.circle.fill",
                color: .blue
            )
            
            ActionButton(
                title: "Receive Contact",
                subtitle: "Get someone's contact info",
                systemImage: "arrow.down.circle.fill",
                color: .green
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}