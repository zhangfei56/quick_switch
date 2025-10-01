import Cocoa
import ApplicationServices

/// 系统集成管理器
class SystemIntegrationManager {
    static let shared = SystemIntegrationManager()
    
    private let workspace = NSWorkspace.shared
    private let notificationCenter = NSWorkspace.shared.notificationCenter
    
    private init() {}
    
    // MARK: - 应用管理
    
    /// 获取所有运行中的应用
    func getRunningApplications() -> [NSRunningApplication] {
        return workspace.runningApplications
    }
    
    /// 获取 Dock 中的应用
    func getDockApplications() -> [NSRunningApplication] {
        // 注意：macOS 没有直接 API 获取 Dock 应用
        // 这里返回当前运行的应用作为替代
        return workspace.runningApplications.filter { app in
            // 过滤掉系统应用和后台应用
            return app.activationPolicy == .regular
        }
    }
    
    /// 启动应用
    func launchApplication(at url: URL) -> Bool {
        do {
            let app = try workspace.launchApplication(at: url, options: [], configuration: [:])
            return app != nil
        } catch {
            print("Failed to launch application: \(error)")
            return false
        }
    }
    
    /// 激活应用
    func activateApplication(_ app: NSRunningApplication) -> Bool {
        return app.activate(options: [.activateIgnoringOtherApps])
    }
    
    /// 隐藏应用
    func hideApplication(_ app: NSRunningApplication) -> Bool {
        return app.hide()
    }
    
    /// 退出应用
    func terminateApplication(_ app: NSRunningApplication) -> Bool {
        return app.terminate()
    }
    
    // MARK: - 应用信息获取
    
    /// 获取应用图标
    func getApplicationIcon(for app: NSRunningApplication) -> NSImage? {
        guard let bundleURL = app.bundleURL else { return nil }
        return workspace.icon(forFile: bundleURL.path)
    }
    
    /// 获取应用信息
    func getApplicationInfo(for app: NSRunningApplication) -> ApplicationInfo? {
        guard let bundleURL = app.bundleURL,
              let bundleIdentifier = app.bundleIdentifier,
              let localizedName = app.localizedName else {
            return nil
        }
        
        let icon = getApplicationIcon(for: app)
        
        return ApplicationInfo(
            bundleIdentifier: bundleIdentifier,
            name: localizedName,
            path: bundleURL.path,
            icon: icon,
            isRunning: true
        )
    }

    /// 通过应用 URL 获取应用信息（适用于未运行的应用）
    func getApplicationInfo(at url: URL) -> ApplicationInfo? {
        guard let bundle = Bundle(url: url) else { return nil }
        let bundleIdentifier = bundle.bundleIdentifier ?? url.lastPathComponent
        let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? url.deletingPathExtension().lastPathComponent
        let icon = workspace.icon(forFile: url.path)
        return ApplicationInfo(
            bundleIdentifier: bundleIdentifier,
            name: name,
            path: url.path,
            icon: icon,
            isRunning: false
        )
    }

    /// 通过 Bundle Identifier 查找应用并获取信息
    func getApplicationInfo(forBundleIdentifier bundleIdentifier: String) -> ApplicationInfo? {
        guard let url = workspace.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return nil
        }
        return getApplicationInfo(at: url)
    }
    
    // MARK: - 窗口管理
    
    /// 检查应用是否全屏
    func isApplicationFullscreen(_ app: NSRunningApplication) -> Bool {
        // 使用 Accessibility API 检查窗口状态
        guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        
        for window in windowList {
            guard let ownerPID = window[kCGWindowOwnerPID as String] as? Int32,
                  ownerPID == app.processIdentifier else {
                continue
            }
            
            // 检查窗口层级和大小
            if let layer = window[kCGWindowLayer as String] as? Int,
               layer == 0, // 主窗口层
               let bounds = window[kCGWindowBounds as String] as? [String: Any],
               let width = bounds["Width"] as? Double,
               let height = bounds["Height"] as? Double {
                
                // 检查是否占满整个屏幕
                let screenFrame = NSScreen.main?.frame ?? CGRect.zero
                return width >= screenFrame.width && height >= screenFrame.height
            }
        }
        
        return false
    }
    
    /// 检查应用是否最小化
    func isApplicationMinimized(_ app: NSRunningApplication) -> Bool {
        return app.isHidden
    }
    
    // MARK: - 系统事件监听
    
    /// 开始监听应用启动事件
    func startMonitoringApplicationLaunches(completion: @escaping (NSRunningApplication) -> Void) {
        notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                completion(app)
            }
        }
    }
    
    /// 开始监听应用终止事件
    func startMonitoringApplicationTerminations(completion: @escaping (NSRunningApplication) -> Void) {
        notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                completion(app)
            }
        }
    }
    
    /// 开始监听应用激活事件
    func startMonitoringApplicationActivations(completion: @escaping (NSRunningApplication) -> Void) {
        notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                completion(app)
            }
        }
    }
    
    /// 开始监听应用隐藏事件
    func startMonitoringApplicationHides(completion: @escaping (NSRunningApplication) -> Void) {
        notificationCenter.addObserver(
            forName: NSWorkspace.didHideApplicationNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                completion(app)
            }
        }
    }
    
    /// 开始监听应用显示事件
    func startMonitoringApplicationUnhides(completion: @escaping (NSRunningApplication) -> Void) {
        notificationCenter.addObserver(
            forName: NSWorkspace.didUnhideApplicationNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                completion(app)
            }
        }
    }
    
    // MARK: - 清理
    
    /// 停止所有监听
    func stopAllMonitoring() {
        notificationCenter.removeObserver(self)
    }
}

// MARK: - 应用类型检测

extension SystemIntegrationManager {
    /// 检测应用类型
    func detectApplicationType(_ app: NSRunningApplication) -> ApplicationType {
        guard let bundleIdentifier = app.bundleIdentifier else {
            return .unknown
        }
        
        // 游戏检测
        if isGameApplication(bundleIdentifier) {
            return .game
        }
        
        // 视频播放器检测
        if isVideoPlayerApplication(bundleIdentifier) {
            return .videoPlayer
        }
        
        // 开发工具检测
        if isDevelopmentToolApplication(bundleIdentifier) {
            return .developmentTool
        }
        
        // 系统应用检测
        if isSystemApplication(bundleIdentifier) {
            return .system
        }
        
        return .regular
    }
    
    private func isGameApplication(_ bundleIdentifier: String) -> Bool {
        let gameIdentifiers = [
            "com.valvesoftware.steam",
            "com.blizzard.worldofwarcraft",
            "com.ea.origin",
            "com.epicgames.launcher",
            "com.riotgames.leagueoflegends"
        ]
        
        return gameIdentifiers.contains(bundleIdentifier)
    }
    
    private func isVideoPlayerApplication(_ bundleIdentifier: String) -> Bool {
        let videoPlayerIdentifiers = [
            "com.apple.QuickTimePlayerX",
            "com.videolan.vlc",
            "com.plexapp.plexmediaserver",
            "com.netflix.app"
        ]
        
        return videoPlayerIdentifiers.contains(bundleIdentifier)
    }
    
    private func isDevelopmentToolApplication(_ bundleIdentifier: String) -> Bool {
        let devToolIdentifiers = [
            "com.apple.dt.Xcode",
            "com.microsoft.VSCode",
            "com.jetbrains.intellij",
            "com.sublimetext.3"
        ]
        
        return devToolIdentifiers.contains(bundleIdentifier)
    }
    
    private func isSystemApplication(_ bundleIdentifier: String) -> Bool {
        return bundleIdentifier.hasPrefix("com.apple.")
    }
}

// MARK: - 应用类型枚举

enum ApplicationType {
    case regular
    case game
    case videoPlayer
    case developmentTool
    case system
    case unknown
    
    var shouldBeSilent: Bool {
        switch self {
        case .game, .videoPlayer:
            return true
        default:
            return false
        }
    }
}
