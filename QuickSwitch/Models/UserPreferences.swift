import Cocoa
import Combine
import Foundation

/// 用户偏好设置模型
struct UserPreferences: Codable {
    // MARK: - 切换模式设置
    
    /// 当前切换模式
    var switchMode: SwitchMode = .dock
    
    /// 修饰键设置
    var modifierKey: NSEvent.ModifierFlags = .option
    
    // MARK: - 界面设置
    
    /// 是否显示状态栏图标
    var showStatusBarIcon: Bool = true
    
    /// 是否启用启动条
    var launchBarEnabled: Bool = false
    
    /// 启动条位置
    var launchBarPosition: LaunchBarPosition = .bottom
    
    /// 启动条透明度
    var launchBarOpacity: Double = 0.8
    
    // MARK: - 静默模式设置
    
    /// 静默应用列表
    var silentApplications: Set<String> = []
    
    /// 是否自动检测全屏应用
    var autoDetectFullscreen: Bool = true
    
    /// 是否自动检测游戏
    var autoDetectGames: Bool = true
    
    // MARK: - 统计设置
    
    /// 是否启用使用统计
    var enableUsageStatistics: Bool = true
    
    /// 统计数据保留天数
    var statisticsRetentionDays: Int = 30
    
    // MARK: - 高级设置
    
    /// 快捷键响应延迟（毫秒）
    var shortcutResponseDelay: Int = 50
    
    /// 是否启用快捷键冲突检测
    var enableConflictDetection: Bool = true
    
    /// 是否启用应用分组
    var enableApplicationGroups: Bool = false
    
    /// 是否启用工作空间
    var enableWorkspaces: Bool = false
    
    // MARK: - 初始化
    
    init() {
        // 使用默认值
    }
}

// MARK: - 切换模式枚举

enum SwitchMode: String, CaseIterable, Codable {
    case dock = "dock"
    case running = "running"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .dock:
            return "Dock 模式"
        case .running:
            return "切换器模式"
        case .custom:
            return "自定义模式"
        }
    }
    
    var description: String {
        switch self {
        case .dock:
            return "映射 macOS Dock 上的应用程序"
        case .running:
            return "映射当前打开的应用程序"
        case .custom:
            return "用户完全自定义应用程序列表"
        }
    }
}

// MARK: - 启动条位置枚举

enum LaunchBarPosition: String, CaseIterable, Codable {
    case top = "top"
    case bottom = "bottom"
    case left = "left"
    case right = "right"
    case topLeft = "topLeft"
    case topRight = "topRight"
    case bottomLeft = "bottomLeft"
    case bottomRight = "bottomRight"
    
    var displayName: String {
        switch self {
        case .top:
            return "顶部"
        case .bottom:
            return "底部"
        case .left:
            return "左侧"
        case .right:
            return "右侧"
        case .topLeft:
            return "左上角"
        case .topRight:
            return "右上角"
        case .bottomLeft:
            return "左下角"
        case .bottomRight:
            return "右下角"
        }
    }
}

// MARK: - 用户偏好管理

class UserPreferencesManager {
    static let shared = UserPreferencesManager()
    
    private let userDefaults = UserDefaults.standard
    private let preferencesKey = "QuickSwitchUserPreferences"
    
    private init() {}
    
    // MARK: - 保存和加载
    
    func save(_ preferences: UserPreferences) {
        do {
            let data = try JSONEncoder().encode(preferences)
            userDefaults.set(data, forKey: preferencesKey)
        } catch {
            print("Failed to save user preferences: \(error)")
        }
    }
    
    func load() -> UserPreferences {
        guard let data = userDefaults.data(forKey: preferencesKey) else {
            return UserPreferences()
        }
        
        do {
            return try JSONDecoder().decode(UserPreferences.self, from: data)
        } catch {
            print("Failed to load user preferences: \(error)")
            return UserPreferences()
        }
    }
    
    // MARK: - 重置设置
    
    func resetToDefaults() {
        userDefaults.removeObject(forKey: preferencesKey)
    }
    
    // MARK: - 特定设置更新
    
    func updateSwitchMode(_ mode: SwitchMode) {
        var preferences = load()
        preferences.switchMode = mode
        save(preferences)
    }
    
    func updateModifierKey(_ modifier: NSEvent.ModifierFlags) {
        var preferences = load()
        preferences.modifierKey = modifier
        save(preferences)
    }
    
    func addSilentApplication(_ bundleIdentifier: String) {
        var preferences = load()
        preferences.silentApplications.insert(bundleIdentifier)
        save(preferences)
    }
    
    func removeSilentApplication(_ bundleIdentifier: String) {
        var preferences = load()
        preferences.silentApplications.remove(bundleIdentifier)
        save(preferences)
    }
    
    // MARK: - Publishers
    
    var permissionStatusPublisher: AnyPublisher<Bool, Never> {
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .map { _ in true } // 简化实现，实际应该检查权限状态
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
