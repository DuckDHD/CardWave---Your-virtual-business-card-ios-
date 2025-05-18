import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: ContactViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // App logo/header
                Image(systemName: "wave.3.right.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                
                Text("NFC Contact Share")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Quickly share your contact information using NFC")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                // Main action buttons
                VStack(spacing: 16) {
                    NavigationLink(destination: SendContactView()) {
                        ActionButton(
                            title: "Send Contact",
                            subtitle: "Share your contact info",
                            systemImage: "arrow.up.circle.fill",
                            color: .blue
                        )
                    }
                    
                    NavigationLink(destination: ReceiveContactView()) {
                        ActionButton(
                            title: "Receive Contact",
                            subtitle: "Get someone's contact info",
                            systemImage: "arrow.down.circle.fill",
                            color: .green
                        )
                    }
                    
                    NavigationLink(destination: SettingsView()) {
                        ActionButton(
                            title: "Settings",
                            subtitle: "Configure your contact info",
                            systemImage: "gear.circle.fill",
                            color: .orange
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Status indicator for automatic mode
                if viewModel.isAutoDetectionActive {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundColor(.blue)
                                .symbolEffect(.pulse, options: .repeating)
                            Text("Automatic sharing active")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                    }
                }
                
                // Instructions
                VStack(spacing: 8) {
                    Text("How to use")
                        .font(.headline)
                    
                    Text("Just bring your phone near another device with this app to automatically share contacts, or use the manual send/receive options.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
            .onAppear {
                viewModel.startAutoDetection()
            }
        }
        .alert("Contact Received", isPresented: $viewModel.showAutoReceivedAlert) {
            Button("Save", role: .none) {
                viewModel.saveReceivedContact()
            }
            Button("Dismiss", role: .cancel) {
                viewModel.dismissReceivedContact()
            }
        } message: {
            if let contact = viewModel.receivedContact {
                Text("Received contact from \(contact.name)")
            } else {
                Text("Received a new contact")
            }
        }
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}