import Cocoa

/// 应用信息模型
struct ApplicationInfo: Codable, Identifiable, Hashable {
    let id: String
    let bundleIdentifier: String
    let name: String
    let path: String
    let iconData: Data?
    var isRunning: Bool
    var launchDate: Date?
    var usageCount: Int
    var lastUsed: Date?
    
    // MARK: - Initialization
    
    init(bundleIdentifier: String, name: String, path: String, icon: NSImage? = nil, isRunning: Bool = false) {
        self.id = bundleIdentifier
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.path = path
        self.iconData = icon?.tiffRepresentation
        self.isRunning = isRunning
        self.launchDate = nil
        self.usageCount = 0
        self.lastUsed = nil
    }
    
    // MARK: - Computed Properties
    
    var icon: NSImage? {
        guard let iconData = iconData else { return nil }
        return NSImage(data: iconData)
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

