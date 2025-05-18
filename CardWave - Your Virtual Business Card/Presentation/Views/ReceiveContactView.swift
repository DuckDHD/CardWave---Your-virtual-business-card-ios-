import SwiftUI

struct ReceiveContactView: View {
    @EnvironmentObject var viewModel: ContactViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(.green)
                    
                    Text("Receive Contact")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Get someone's contact information via NFC")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                if let receivedContact = viewModel.receivedContact {
                    // Received contact card
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Received Contact")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .frame(width: 24)
                                Text(receivedContact.name)
                                    .font(.body)
                            }
                            
                            HStack {
                                Image(systemName: "phone.fill")
                                    .frame(width: 24)
                                Text(receivedContact.phoneNumber)
                                    .font(.body)
                            }
                            
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .frame(width: 24)
                                Text(receivedContact.email)
                                    .font(.body)
                            }
                        }
                        
                        HStack {
                            Button(action: {
                                viewModel.saveReceivedContact()
                            }) {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                    Text("Save to Contacts")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            
                            Button(action: {
                                viewModel.receivedContact = nil
                            }) {
                                HStack {
                                    Image(systemName: "xmark")
                                    Text("Dismiss")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                } else {
                    // Receive button
                    Button(action: {
                        viewModel.receiveContact()
                    }) {
                        HStack {
                            Image(systemName: "wave.3.left")
                            Text("Receive via NFC")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: Color.green.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                    
                    // Instructions
                    VStack(spacing: 8) {
                        Text("How to receive")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            InstructionRow(number: "1", text: "Tap 'Receive via NFC'")
                            InstructionRow(number: "2", text: "Hold your iPhone near the sender's iPhone")
                            InstructionRow(number: "3", text: "Wait for the contact to appear")
                            InstructionRow(number: "4", text: "Save the contact to your device")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.bottom)
        }
        .navigationBarTitle("Receive Contact", displayMode: .inline)
        .overlay(
            Group {
                if viewModel.isNFCSessionActive && viewModel.receivedContact == nil {
                    ZStack {
                        Color.black.opacity(0.7)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 30) {
                            NFCAnimationView(
                                isReceiving: true,
                                transferCompleted: viewModel.transferCompleted
                            )
                            .frame(height: 200)
                            
                            TransferStatusView(
                                status: $viewModel.transferStatus,
                                isReceiving: true
                            )
                            .padding(.horizontal)
                        }
                    }
                    .transition(.opacity)
                }
            }
        )
        .alert("Success", isPresented: $viewModel.showSuccessAlert) {
            Button("OK", role: .cancel) {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Contact saved to your device successfully!")
        }
    }
}