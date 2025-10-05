import Cocoa

/// 应用信息模型
struct ApplicationInfo: Codable, Identifiable, Hashable {
    let id: String
    let bundleIdentifier: String
    let name: String
    let path: String
    // 移除 iconData 字段，避免在 UserDefaults 中存储大量图标数据
    var isRunning: Bool
    var windowCount: Int  // 窗口数量
    var launchDate: Date?
    var usageCount: Int
    var lastUsed: Date?
    
    // MARK: - Initialization
    
    init(bundleIdentifier: String, name: String, path: String, icon: NSImage? = nil, isRunning: Bool = false, windowCount: Int = 0) {
        self.id = bundleIdentifier
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.path = path
        
        // 不再存储图标数据，避免 UserDefaults 数据过大
        // 图标将在需要时动态获取
        
        self.isRunning = isRunning
        self.windowCount = windowCount
        self.launchDate = nil
        self.usageCount = 0
        self.lastUsed = nil
    }
    
    // MARK: - Computed Properties
    
    var icon: NSImage? {
        // 动态获取应用图标，避免存储大量数据
        if !bundleIdentifier.isEmpty {
            // 通过 bundle identifier 获取图标
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
                return NSWorkspace.shared.icon(forFile: appURL.path)
            }
        }
        
        if !path.isEmpty {
            // 通过路径获取图标
            return NSWorkspace.shared.icon(forFile: path)
        }
        
        // 返回默认图标
        return NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil)
    }
    
    var displayName: String {
        return name.isEmpty ? bundleIdentifier : name
    }
    
    // MARK: - Methods
    
    mutating func updateUsage() {
        usageCount += 1
        lastUsed = Date()
    }
    
    mutating func setRunning(_ running: Bool) {
        isRunning = running
        if running {
            launchDate = Date()
        } else {
            launchDate = nil
        }
    }
}

// MARK: - Equatable

extension ApplicationInfo: Equatable {
    static func == (lhs: ApplicationInfo, rhs: ApplicationInfo) -> Bool {
        return lhs.bundleIdentifier == rhs.bundleIdentifier
    }
}

// MARK: - Comparable

extension ApplicationInfo: Comparable {
    static func < (lhs: ApplicationInfo, rhs: ApplicationInfo) -> Bool {
        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }
}

