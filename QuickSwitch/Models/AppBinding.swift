import Foundation

/// 应用绑定配置
struct AppBinding: Codable, Identifiable, Hashable {
    let id = UUID()
    let key: ShortcutKey
    let application: ApplicationInfo
    let order: Int
    
    // 为了向后兼容，提供额外的便捷属性
    var appIdentifier: String {
        return application.path
    }
    
    var displayName: String {
        return application.displayName
    }
    
    var bundleIdentifier: String {
        return application.bundleIdentifier
    }
    
    init(key: ShortcutKey, application: ApplicationInfo, order: Int) {
        self.key = key
        self.application = application
        self.order = order
    }
}

/// 快捷键类型
enum ShortcutKey: Codable, Hashable, CaseIterable {
    case number(Int)      // 1-9
    case letter(String)   // A-Z
    case function(Int)    // F1-F12
    
    /// 所有可用的快捷键
    static var allCases: [ShortcutKey] {
        var cases: [ShortcutKey] = []
        
        // 数字键 1-9
        for i in 1...9 {
            cases.append(.number(i))
        }
        
        // 字母键 A-Z
        for char in "ABCDEFGHIJKLMNOPQRSTUVWXYZ" {
            cases.append(.letter(String(char)))
        }
        
        // 功能键 F1-F12
        for i in 1...12 {
            cases.append(.function(i))
        }
        
        return cases
    }
    
    /// 显示名称
    var displayName: String {
        switch self {
        case .number(let num):
            return "\(num)"
        case .letter(let letter):
            return letter
        case .function(let num):
            return "F\(num)"
        }
    }
    
    /// 键值（用于排序和比较）
    var keyValue: String {
        switch self {
        case .number(let num):
            return "N\(num)"
        case .letter(let letter):
            return "L\(letter)"
        case .function(let num):
            return "F\(num)"
        }
    }
}

/// 启动条视图模式
enum LaunchBarViewMode: String, CaseIterable, Codable {
    case bound = "bound"      // 绑定视图：显示用户预设绑定的应用
    case running = "running"  // 运行视图：显示当前所有打开的应用
    
    var displayName: String {
        switch self {
        case .bound:
            return "绑定应用"
        case .running:
            return "运行应用"
        }
    }
}

