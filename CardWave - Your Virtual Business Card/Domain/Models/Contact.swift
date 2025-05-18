import Foundation

struct Contact: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var phoneNumber: String
    var email: String
    
    static func empty() -> Contact {
        Contact(name: "", phoneNumber: "", email: "")
    }
    
    static func sample() -> Contact {
        Contact(name: "John Doe", phoneNumber: "+1 (555) 123-4567", email: "john.doe@example.com")
    }
}