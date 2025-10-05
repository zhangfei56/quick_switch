import Cocoa
import SwiftUI
import Foundation

/// 用户偏好设置模型
struct UserPreferences: Codable, Equatable {
    
    static func == (lhs: UserPreferences, rhs: UserPreferences) -> Bool {
        return lhs.triggerModifier == rhs.triggerModifier &&
               lhs.appBindings == rhs.appBindings &&
               lhs.showWindowCount == rhs.showWindowCount
    }
    // MARK: - 核心设置
    
    /// 触发修饰键（默认 Option）
    var triggerModifier: NSEvent.ModifierFlags = .option
    
    /// 应用绑定列表
    var appBindings: [AppBinding] = []
    
    /// 是否显示窗口数
    var showWindowCount: Bool = true
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case triggerModifierRawValue, appBindings, showWindowCount
    }
    
    init() {
        // 使用默认值
    }
    
    init(triggerModifier: NSEvent.ModifierFlags, appBindings: [AppBinding], showWindowCount: Bool) {
        self.triggerModifier = triggerModifier
        self.appBindings = appBindings
        self.showWindowCount = showWindowCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appBindings = try container.decodeIfPresent([AppBinding].self, forKey: .appBindings) ?? []
        showWindowCount = try container.decodeIfPresent(Bool.self, forKey: .showWindowCount) ?? true
        
        let triggerModifierRawValue = try container.decodeIfPresent(UInt.self, forKey: .triggerModifierRawValue) ?? NSEvent.ModifierFlags.option.rawValue
        triggerModifier = NSEvent.ModifierFlags(rawValue: triggerModifierRawValue)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(appBindings, forKey: .appBindings)
        try container.encode(showWindowCount, forKey: .showWindowCount)
        try container.encode(triggerModifier.rawValue, forKey: .triggerModifierRawValue)
    }
}

// MARK: - 用户偏好管理（Observable 类）

@Observable
class UserPreferencesManager {
    static let shared = UserPreferencesManager()
    
    // MARK: - Published Properties
    
    var triggerModifier: NSEvent.ModifierFlags {
        didSet { savePreferences() }
    }
    
    var appBindings: [AppBinding] {
        didSet { savePreferences() }
    }
    
    var showWindowCount: Bool {
        didSet { savePreferences() }
    }
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let preferencesKey = "QuickSwitchUserPreferences"
    private let defaultsManager = UserDefaultsManager.shared
    
    // MARK: - Initialization
    
    private init() {
        let preferences = Self.loadPreferences()
        self.triggerModifier = preferences.triggerModifier
        self.appBindings = preferences.appBindings
        self.showWindowCount = preferences.showWindowCount
    }
    
    // MARK: - Public Methods
    
    func save(_ preferences: UserPreferences) {
        self.triggerModifier = preferences.triggerModifier
        self.appBindings = preferences.appBindings
        self.showWindowCount = preferences.showWindowCount
    }
    
    func load() -> UserPreferences {
        return UserPreferences(
            triggerModifier: triggerModifier,
            appBindings: appBindings,
            showWindowCount: showWindowCount
        )
    }
    
    func resetToDefaults() {
        triggerModifier = .option
        appBindings = []
        showWindowCount = true
        userDefaults.removeObject(forKey: preferencesKey)
    }
    
    // MARK: - 应用绑定管理
    
    func addAppBinding(_ binding: AppBinding) {
        appBindings.append(binding)
    }
    
    func removeAppBinding(withKey key: ShortcutKey) {
        appBindings.removeAll { $0.key == key }
    }
    
    func updateAppBinding(at index: Int, with binding: AppBinding) {
        guard index >= 0 && index < appBindings.count else { return }
        appBindings[index] = binding
    }
    
    /// 清理 UserDefaults 数据（解决数据过大问题）
    func cleanupUserDefaults() {
        defaultsManager.cleanupOldData()
    }
    
    /// 检查数据大小并诊断问题
    func diagnoseDataSize() {
        defaultsManager.diagnose()
    }
    
    // MARK: - Private Methods
    
    private func savePreferences() {
        let preferences = UserPreferences(
            triggerModifier: triggerModifier,
            appBindings: appBindings,
            showWindowCount: showWindowCount
        )
        
        // 使用安全的保存方法，自动处理数据大小问题
        if defaultsManager.safeSave(preferences, forKey: preferencesKey) {
            NotificationCenter.default.post(name: .preferencesChanged, object: nil)
        }
    }
    
    private static func loadPreferences() -> UserPreferences {
        // 使用安全的加载方法
        return UserDefaultsManager.shared.safeLoad(UserPreferences.self, forKey: "QuickSwitchUserPreferences") ?? UserPreferences()
    }
}

// MARK: - 偏好更改通知

extension Notification.Name {
    static let preferencesChanged = Notification.Name("QuickSwitchPreferencesChanged")
    static let switchToApplication = Notification.Name("QuickSwitchSwitchToApplication")
    static let hideLaunchBar = Notification.Name("QuickSwitchHideLaunchBar")
}
