import SwiftUI

struct SendContactView: View {
    @EnvironmentObject var viewModel: ContactViewModel
    @State private var showContactPicker = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                    
                    Text("Send Contact")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Share your contact information via NFC")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Contact form
                VStack(alignment: .leading, spacing: 20) {
                    Text("Contact Information")
                        .font(.headline)
                    
                    VStack(spacing: 16) {
                        TextField("Name", text: $viewModel.contact.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Phone Number", text: $viewModel.contact.phoneNumber)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.phonePad)
                        
                        TextField("Email", text: $viewModel.contact.email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    Button(action: {
                        showContactPicker = true
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle")
                            Text("Select from Contacts")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Send button
                Button(action: {
                    viewModel.sendContact()
                }) {
                    HStack {
                        Image(systemName: "wave.3.right")
                        Text("Send via NFC")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .padding(.horizontal)
                .disabled(viewModel.contact.name.isEmpty || 
                          viewModel.contact.phoneNumber.isEmpty || 
                          viewModel.contact.email.isEmpty)
                .opacity(viewModel.contact.name.isEmpty || 
                         viewModel.contact.phoneNumber.isEmpty || 
                         viewModel.contact.email.isEmpty ? 0.6 : 1)
                
                // Instructions
                VStack(spacing: 8) {
                    Text("How to send")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        InstructionRow(number: "1", text: "Fill in your contact details")
                        InstructionRow(number: "2", text: "Tap 'Send via NFC'")
                        InstructionRow(number: "3", text: "Hold your iPhone near the receiver's iPhone")
                        InstructionRow(number: "4", text: "Wait for confirmation")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.bottom)
        }
        .navigationBarTitle("Send Contact", displayMode: .inline)
        .overlay(
            Group {
                if viewModel.isNFCSessionActive {
                    ZStack {
                        Color.black.opacity(0.7)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 30) {
                            NFCAnimationView(
                                isReceiving: false,
                                transferCompleted: viewModel.transferCompleted
                            )
                            .frame(height: 200)
                            
                            TransferStatusView(
                                status: $viewModel.transferStatus,
                                isReceiving: false
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
            Text("Contact information sent successfully!")
        }
        .sheet(isPresented: $showContactPicker) {
            ContactPickerView()
        }
    }
}

struct InstructionRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .frame(width: 24, height: 24)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

struct ContactPickerView: View {
    @EnvironmentObject var viewModel: ContactViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.contacts) { contact in
                    Button(action: {
                        viewModel.selectContact(contact)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        VStack(alignment: .leading) {
                            Text(contact.name)
                                .font(.headline)
                            Text(contact.phoneNumber)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationBarTitle("Select Contact", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                viewModel.loadContacts()
            }
        }
    }
}