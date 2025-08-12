import Foundation
#if canImport(Security)
import Security
#endif

/// 简单的 Keychain 封装，用于安全存储敏感信息，例如 API Key。
@MainActor
final class KeychainService {
    static let shared = KeychainService()
    private init() {}

    private let service = "MoodTrackerApp"
    private let account = "OpenAIAPIKey"

    /// 保存 API Key 到 Keychain。
    @discardableResult
    func saveAPIKey(_ key: String) -> Bool {
        #if canImport(Security)
        let data = Data(key.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
        #else
        UserDefaults.standard.set(key, forKey: account)
        return true
        #endif
    }

    /// 从 Keychain 中读取 API Key。
    func getAPIKey() -> String? {
        #if canImport(Security)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
        #else
        return UserDefaults.standard.string(forKey: account)
        #endif
    }
}

