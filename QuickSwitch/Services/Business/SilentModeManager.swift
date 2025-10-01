import Cocoa
import Combine

/// 静默模式管理器
class SilentModeManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isInSilentMode = false
    @Published var silentApplications: Set<String> = []
    @Published var currentActiveApplication: NSRunningApplication?
    
    // MARK: - Private Properties
    
    private let systemIntegration = SystemIntegrationManager.shared
    private let preferencesManager = UserPreferencesManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var preferences: UserPreferences
    
    // MARK: - Initialization
    
    init() {
        preferences = preferencesManager.load()
        silentApplications = preferences.silentApplications
        setupBindings()
        startMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// 检查当前是否应该静默
    func shouldIgnoreShortcut() -> Bool {
        guard let currentApp = currentActiveApplication else { return false }
        
        // 检查是否在静默应用列表中
        if let bundleId = currentApp.bundleIdentifier,
           silentApplications.contains(bundleId) {
            return true
        }
        
        // 自动检测全屏应用
        if preferences.autoDetectFullscreen && isApplicationFullscreen(currentApp) {
            return true
        }
        
        // 自动检测游戏
        if preferences.autoDetectGames && isGameApplication(currentApp) {
            return true
        }
        
        return false
    }
    
    /// 添加应用到静默列表
    func addToSilentMode(_ bundleIdentifier: String) {
        silentApplications.insert(bundleIdentifier)
        savePreferences()
    }
    
    /// 从静默列表移除应用
    func removeFromSilentMode(_ bundleIdentifier: String) {
        silentApplications.remove(bundleIdentifier)
        savePreferences()
    }
    
    /// 切换应用的静默状态
    func toggleSilentMode(for bundleIdentifier: String) {
        if silentApplications.contains(bundleIdentifier) {
            removeFromSilentMode(bundleIdentifier)
        } else {
            addToSilentMode(bundleIdentifier)
        }
    }
    
    /// 检查应用是否在静默列表中
    func isApplicationInSilentMode(_ bundleIdentifier: String) -> Bool {
        return silentApplications.contains(bundleIdentifier)
    }
    
    /// 批量添加应用到静默列表
    func addMultipleToSilentMode(_ bundleIdentifiers: [String]) {
        silentApplications.formUnion(bundleIdentifiers)
        savePreferences()
    }
    
    /// 清除所有静默应用
    func clearAllSilentApplications() {
        silentApplications.removeAll()
        savePreferences()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // 监听活动应用变化
        systemIntegration.startMonitoringApplicationActivations { [weak self] app in
            self?.currentActiveApplication = app
            self?.updateSilentModeStatus()
        }
    }
    
    private func startMonitoring() {
        // 定期检查静默模式状态
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateSilentModeStatus()
            }
            .store(in: &cancellables)
    }
    
    private func updateSilentModeStatus() {
        isInSilentMode = shouldIgnoreShortcut()
    }
    
    private func savePreferences() {
        preferences.silentApplications = silentApplications
        preferencesManager.save(preferences)
    }
    
    // MARK: - Application Detection
    
    private func isApplicationFullscreen(_ app: NSRunningApplication) -> Bool {
        return systemIntegration.isApplicationFullscreen(app)
    }
    
    private func isGameApplication(_ app: NSRunningApplication) -> Bool {
        let appType = systemIntegration.detectApplicationType(app)
        return appType == .game
    }
    
    private func isVideoPlayerApplication(_ app: NSRunningApplication) -> Bool {
        let appType = systemIntegration.detectApplicationType(app)
        return appType == .videoPlayer
    }
}

// MARK: - 自动检测管理

extension SilentModeManager {
    
    /// 启用/禁用全屏自动检测
    func setAutoDetectFullscreen(_ enabled: Bool) {
        preferences.autoDetectFullscreen = enabled
        savePreferences()
    }
    
    /// 启用/禁用游戏自动检测
    func setAutoDetectGames(_ enabled: Bool) {
        preferences.autoDetectGames = enabled
        savePreferences()
    }
    
    /// 获取建议的静默应用列表
    func getSuggestedSilentApplications() -> [ApplicationInfo] {
        let runningApps = systemIntegration.getRunningApplications()
        
        return runningApps.compactMap { app in
            let appType = systemIntegration.detectApplicationType(app)
            
            // 建议游戏和视频播放器添加到静默列表
            if appType.shouldBeSilent {
                return systemIntegration.getApplicationInfo(for: app)
            }
            return nil
        }
    }
}

// MARK: - 预设静默应用

extension SilentModeManager {
    
    /// 常见的应该静默的应用 Bundle ID
    static let commonSilentApplications = [
        // 游戏平台
        "com.valvesoftware.steam",
        "com.epicgames.launcher",
        "com.blizzard.worldofwarcraft",
        "com.ea.origin",
        "com.riotgames.leagueoflegends",
        
        // 视频播放器
        "com.apple.QuickTimePlayerX",
        "com.videolan.vlc",
        "com.plexapp.plexmediaserver",
        "com.netflix.app",
        "com.apple.TV",
        
        // 远程桌面
        "com.microsoft.rdc.macos",
        "com.teamviewer.TeamViewer",
        "com.apple.ScreenSharing",
        
        // 虚拟机
        "com.vmware.fusion",
        "com.parallels.desktop",
        "org.virtualbox.app.VirtualBox",
        
        // 演示软件
        "com.apple.Keynote",
        "com.microsoft.Powerpoint",
    ]
    
    /// 应用预设的静默应用列表
    func applyCommonSilentApplications() {
        addMultipleToSilentMode(SilentModeManager.commonSilentApplications)
    }
    
    /// 检查是否使用了预设列表
    func isUsingCommonPresets() -> Bool {
        let commonSet = Set(SilentModeManager.commonSilentApplications)
        return silentApplications.isSuperset(of: commonSet)
    }
}

// MARK: - 静默模式统计

extension SilentModeManager {
    
    /// 获取静默模式统计信息
    func getSilentModeStatistics() -> SilentModeStatistics {
        let totalSilentApps = silentApplications.count
        let runningApps = systemIntegration.getRunningApplications()
        let currentlySilentApps = runningApps.filter { app in
            guard let bundleId = app.bundleIdentifier else { return false }
            return silentApplications.contains(bundleId)
        }.count
        
        return SilentModeStatistics(
            totalSilentApplications: totalSilentApps,
            currentlySilentApplications: currentlySilentApps,
            isCurrentlyInSilentMode: isInSilentMode,
            autoDetectFullscreen: preferences.autoDetectFullscreen,
            autoDetectGames: preferences.autoDetectGames
        )
    }
}

// MARK: - 静默模式统计信息

struct SilentModeStatistics {
    let totalSilentApplications: Int
    let currentlySilentApplications: Int
    let isCurrentlyInSilentMode: Bool
    let autoDetectFullscreen: Bool
    let autoDetectGames: Bool
}

// MARK: - 静默模式通知

extension Notification.Name {
    static let silentModeChanged = Notification.Name("SilentModeChanged")
    static let silentApplicationsChanged = Notification.Name("SilentApplicationsChanged")
}

// MARK: - 导入导出

extension SilentModeManager {
    
    /// 导出静默应用列表
    func exportSilentApplications() -> Data? {
        let exportData = SilentApplicationsExport(
            version: 1,
            applications: Array(silentApplications),
            exportDate: Date()
        )
        
        return try? JSONEncoder().encode(exportData)
    }
    
    /// 导入静默应用列表
    func importSilentApplications(from data: Data) throws {
        let importData = try JSONDecoder().decode(SilentApplicationsExport.self, from: data)
        addMultipleToSilentMode(importData.applications)
    }
}

// MARK: - 导出数据结构

struct SilentApplicationsExport: Codable {
    let version: Int
    let applications: [String]
    let exportDate: Date
}
