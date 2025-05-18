import Foundation
import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
    @Published var userContact: Contact
    @Published var autoShareEnabled: Bool = true
    @Published var showSuccessAlert = false
    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    
    private let settingsService: SettingsServiceProtocol
    private let contactUseCase: ContactUseCase
    
    init(settingsService: SettingsServiceProtocol = SettingsService(),
         contactUseCase: ContactUseCase = ContactInteractor(repository: ContactRepositoryImpl())) {
        self.settingsService = settingsService
        self.contactUseCase = contactUseCase
        
        // Initialize with empty contact, will be updated in loadSettings()
        self.userContact = Contact.empty()
        
        loadSettings()
    }
    
    func loadSettings() {
        do {
            let settings = try settingsService.loadSettings()
            DispatchQueue.main.async {
                self.userContact = settings.userContact
                self.autoShareEnabled = settings.autoShareEnabled
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load settings: \(error.localizedDescription)"
                self.showErrorAlert = true
            }
        }
    }
    
    func saveSettings() {
        let settings = UserSettings(
            userContact: userContact,
            autoShareEnabled: autoShareEnabled
        )
        
        do {
            try settingsService.saveSettings(settings)
            DispatchQueue.main.async {
                self.showSuccessAlert = true
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to save settings: \(error.localizedDescription)"
                self.showErrorAlert = true
            }
        }
    }
    
    func importFromContacts() {
        Task {
            do {
                let contacts = try await contactUseCase.fetchContactFromDevice()
                if let firstContact = contacts.first {
                    await MainActor.run {
                        self.userContact = firstContact
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to import contact: \(error.localizedDescription)"
                    self.showErrorAlert = true
                }
            }
        }
    }
}
