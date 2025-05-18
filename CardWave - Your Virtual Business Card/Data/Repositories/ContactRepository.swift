import Foundation
import Contacts

protocol ContactRepository {
    func saveContact(_ contact: Contact) async throws
    func fetchContacts() async throws -> [Contact]
}

class ContactRepositoryImpl: ContactRepository {
    func saveContact(_ contact: Contact) async throws {
        let store = CNContactStore()
        
        // Request access to contacts
        let authStatus = await withCheckedContinuation { continuation in
            store.requestAccess(for: .contacts) { success, error in
                continuation.resume(returning: success)
            }
        }
        
        guard authStatus else {
            throw ContactError.accessDenied
        }
        
        // Create a mutable contact
        let newContact = CNMutableContact()
        newContact.givenName = contact.name
        
        // Add phone number
        let phoneNumber = CNLabeledValue(
            label: CNLabelPhoneNumberMain,
            value: CNPhoneNumber(stringValue: contact.phoneNumber)
        )
        newContact.phoneNumbers = [phoneNumber]
        
        // Add email
        let email = CNLabeledValue(
            label: CNLabelWork,
            value: contact.email as NSString
        )
        newContact.emailAddresses = [email]
        
        // Save the contact
        let saveRequest = CNSaveRequest()
        saveRequest.add(newContact, toContainerWithIdentifier: nil)
        
        try store.execute(saveRequest)
    }
    
    func fetchContacts() async throws -> [Contact] {
        let store = CNContactStore()
        
        // Request access to contacts
        let authStatus = await withCheckedContinuation { continuation in
            store.requestAccess(for: .contacts) { success, error in
                continuation.resume(returning: success)
            }
        }
        
        guard authStatus else {
            throw ContactError.accessDenied
        }
        
        // Define which contact data to fetch
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor
        ]
        
        // Fetch contacts
        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        var contacts: [Contact] = []
        
        try store.enumerateContacts(with: request) { cnContact, _ in
            let name = "\(cnContact.givenName) \(cnContact.familyName)".trimmingCharacters(in: .whitespacesAndNewlines)
            let phoneNumber = cnContact.phoneNumbers.first?.value.stringValue ?? ""
            let email = cnContact.emailAddresses.first?.value as String? ?? ""
            
            let contact = Contact(name: name, phoneNumber: phoneNumber, email: email)
            contacts.append(contact)
        }
        
        return contacts
    }
}

enum ContactError: Error {
    case accessDenied
    case saveFailed
    case fetchFailed
}