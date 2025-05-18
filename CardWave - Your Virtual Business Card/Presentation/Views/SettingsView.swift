import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel = SettingsViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "gear.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                    
                    Text("Settings")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Configure your contact information")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Contact form
                VStack(alignment: .leading, spacing: 20) {
                    Text("Your Contact Information")
                        .font(.headline)
                    
                    VStack(spacing: 16) {
                        TextField("Name", text: $viewModel.userContact.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Phone Number", text: $viewModel.userContact.phoneNumber)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.phonePad)
                        
                        TextField("Email", text: $viewModel.userContact.email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    Button(action: {
                        viewModel.importFromContacts()
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle")
                            Text("Import from Contacts")
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
                
                // Auto-share settings
                VStack(alignment: .leading, spacing: 16) {
                    Text("Automatic Sharing")
                        .font(.headline)
                    
                    Toggle("Enable automatic contact sharing", isOn: $viewModel.autoShareEnabled)
                    
                    Text("When enabled, your contact information will be automatically shared when your phone is near another device with this app.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Save button
                Button(action: {
                    viewModel.saveSettings()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Save Settings")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .padding(.horizontal)
                .disabled(viewModel.userContact.name.isEmpty || 
                          viewModel.userContact.phoneNumber.isEmpty || 
                          viewModel.userContact.email.isEmpty)
                .opacity(viewModel.userContact.name.isEmpty || 
                         viewModel.userContact.phoneNumber.isEmpty || 
                         viewModel.userContact.email.isEmpty ? 0.6 : 1)
                
                Spacer()
            }
            .padding(.bottom)
        }
        .navigationBarTitle("Settings", displayMode: .inline)
        .alert("Success", isPresented: $viewModel.showSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Settings saved successfully!")
        }
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}