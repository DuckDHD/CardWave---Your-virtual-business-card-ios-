import Foundation


protocol SettingsServiceProtocol {
    func saveSettings(_ settings: UserSettings) throws
    func loadSettings() throws -> UserSettings
}

class SettingsService: SettingsServiceProtocol {
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "nfc_contact_share_settings"
    
    func saveSettings(_ settings: UserSettings) throws {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(settings)
            userDefaults.set(data, forKey: settingsKey)
        } catch {
            throw SettingsError.saveFailed
        }
    }
    
    func loadSettings() throws -> UserSettings {
        guard let data = userDefaults.data(forKey: settingsKey) else {
            // Return default settings if none exist
            return UserSettings.defaultSettings()
        }
        
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(UserSettings.self, from: data)
        } catch {
            throw SettingsError.loadFailed
        }
    }
}

enum SettingsError: Error {
    case saveFailed
    case loadFailed
}
