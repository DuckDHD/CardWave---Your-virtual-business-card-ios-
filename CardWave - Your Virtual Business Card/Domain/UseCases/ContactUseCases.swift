import Foundation
import Contacts

protocol ContactUseCase {
    func saveContactToDevice(_ contact: Contact) async throws
    func fetchContactFromDevice() async throws -> [Contact]
}

class ContactInteractor: ContactUseCase {
    private let repository: ContactRepository
    
    init(repository: ContactRepository) {
        self.repository = repository
    }
    
    func saveContactToDevice(_ contact: Contact) async throws {
        try await repository.saveContact(contact)
    }
    
    func fetchContactFromDevice() async throws -> [Contact] {
        return try await repository.fetchContacts()
    }
}