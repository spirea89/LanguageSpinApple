import Foundation

enum L10n {
    static func t(_ key: String, language: String, ui: [String: [String: String]], fallback: String = "en") -> String {
        if let value = ui[key]?[language], !value.isEmpty {
            return value
        }
        if let value = ui[key]?[fallback], !value.isEmpty {
            return value
        }
        return key
    }
}
