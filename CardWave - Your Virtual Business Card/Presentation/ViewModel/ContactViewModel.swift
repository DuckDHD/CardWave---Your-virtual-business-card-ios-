import Foundation
import SwiftUI
import Combine


class ContactViewModel: ObservableObject {
    @Published var contact = Contact.empty()
    @Published var receivedContact: Contact?
    @Published var isNFCSessionActive = false
    @Published var showSuccessAlert = false
    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    @Published var isLoading = false
    @Published var contacts: [Contact] = []
    @Published var transferStatus: TransferStatusView.TransferStatus = .preparing
    @Published var transferProgress: Double = 0.0
    @Published var transferCompleted = false
    @Published var isAutoDetectionActive = false
    @Published var showAutoReceivedAlert = false
    
    private var nfcService: NFCServiceProtocol
    private let contactUseCase: ContactUseCase
    private let settingsService: SettingsServiceProtocol
    private var progressTimer: Timer?
    
    init(nfcService: NFCServiceProtocol = NFCService(), 
         contactUseCase: ContactUseCase = ContactInteractor(repository: ContactRepositoryImpl()),
         settingsService: SettingsServiceProtocol = SettingsService()) {
        self.nfcService = nfcService
        self.contactUseCase = contactUseCase
        self.settingsService = settingsService
        
        setupNFCCallbacks()
        loadUserContact()
    }
    
    private func loadUserContact() {
        do {
            let settings = try settingsService.loadSettings()
            self.contact = settings.userContact
            
            // Start auto detection if enabled
            if settings.autoShareEnabled {
                startAutoDetection()
            }
        } catch {
            self.errorMessage = "Failed to load settings: \(error.localizedDescription)"
            self.showErrorAlert = true
        }
    }
    
    private func setupNFCCallbacks() {
        nfcService.onSessionStarted = { [weak self] in
            DispatchQueue.main.async {
                self?.isNFCSessionActive = true
                self?.isLoading = true
                self?.transferStatus = .searching
                self?.transferProgress = 0.0
                self?.transferCompleted = false
                
                // Add haptic feedback
                HapticFeedback.shared.playTransferStarted()
                
                // Start simulating transfer progress after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self?.transferStatus = .connecting
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self?.startTransferProgressSimulation()
                    }
                }
            }
        }
        
        nfcService.onSessionEnded = { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isNFCSessionActive = false
                self?.isLoading = false
                self?.stopTransferProgressSimulation()
                
                if success {
                    self?.transferStatus = .completed
                    self?.transferCompleted = true
                    self?.showSuccessAlert = true
                    HapticFeedback.shared.playTransferCompleted()
                } else if let error = error {
                    self?.transferStatus = .failed(message: error.localizedDescription)
                    self?.errorMessage = error.localizedDescription
                    self?.showErrorAlert = true
                    HapticFeedback.shared.playTransferFailed()
                }
            }
        }
        
        nfcService.onAutoContactReceived = { [weak self] contact in
            DispatchQueue.main.async {
                self?.receivedContact = contact
                self?.showAutoReceivedAlert = true
                HapticFeedback.shared.playTransferCompleted()
            }
        }
    }
    
    func startAutoDetection() {
        do {
            let settings = try settingsService.loadSettings()
            
            if settings.autoShareEnabled && !settings.userContact.name.isEmpty {
                isAutoDetectionActive = true
                nfcService.startBackgroundDetection(with: settings.userContact)
            } else {
                isAutoDetectionActive = false
            }
        } catch {
            isAutoDetectionActive = false
            self.errorMessage = "Failed to start auto detection: \(error.localizedDescription)"
            self.showErrorAlert = true
        }
    }
    
    func stopAutoDetection() {
        isAutoDetectionActive = false
        nfcService.stopBackgroundDetection()
    }
    
    private func startTransferProgressSimulation() {
        transferStatus = .transferring(progress: 0.0)
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Simulate progress with a non-linear curve for more realism
            if self.transferProgress < 0.95 {
                let increment = 0.01 * (1.0 - self.transferProgress * 0.5) // Slow down as we progress
                self.transferProgress += increment
                
                // Update the transfer status
                self.transferStatus = .transferring(progress: self.transferProgress)
                
                // Add occasional haptic feedback during transfer
                if Int(self.transferProgress * 100) % 20 == 0 && self.transferProgress > 0 {
                    HapticFeedback.shared.playTransferProgress()
                }
            }
        }
    }
    
    private func stopTransferProgressSimulation() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    func sendContact() {
        Task {
            do {
                try await nfcService.startSendingSession(with: contact)
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                    self.isLoading = false
                    self.transferStatus = .failed(message: error.localizedDescription)
                }
            }
        }
    }
    
    func receiveContact() {
        Task {
            do {
                let contact = try await nfcService.startReceivingSession()
                await MainActor.run {
                    self.receivedContact = contact
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                    self.isLoading = false
                    self.transferStatus = .failed(message: error.localizedDescription)
                }
            }
        }
    }
    
    func saveReceivedContact() {
        guard let contact = receivedContact else { return }
        
        Task {
            do {
                try await contactUseCase.saveContactToDevice(contact)
                await MainActor.run {
                    self.showSuccessAlert = true
                    self.receivedContact = nil
                    self.showAutoReceivedAlert = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to save contact: \(error.localizedDescription)"
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    func dismissReceivedContact() {
        receivedContact = nil
        showAutoReceivedAlert = false
    }
    
    func loadContacts() {
        Task {
            do {
                let contacts = try await contactUseCase.fetchContactFromDevice()
                await MainActor.run {
                    self.contacts = contacts
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load contacts: \(error.localizedDescription)"
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    func selectContact(_ contact: Contact) {
        self.contact = contact
    }
}
