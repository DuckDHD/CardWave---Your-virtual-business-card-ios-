import Foundation

struct UserSettings: Codable {
    var userContact: Contact
    var autoShareEnabled: Bool
    
    static func defaultSettings() -> UserSettings {
        return UserSettings(
            userContact: Contact.empty(),
            autoShareEnabled: true
        )
    }
}