import Cocoa
import SwiftUI

/// 应用管理器 - Observable 类
@Observable
class ApplicationManager {
    
    // MARK: - Observable Properties
    
    var runningApplications: [ApplicationInfo] = []
    
    // MARK: - Private Properties
    
    private var isRunning = false
    private var applicationObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    
    init() {
        setupApplicationObserver()
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Public Methods
    
    /// 启动应用管理器
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        loadRunningApplications()
        
        print("✅ 应用管理器已启动")
    }
    
    /// 停止应用管理器
    func stop() {
        guard isRunning else { return }
        
        isRunning = false
        
        if let observer = applicationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            applicationObserver = nil
        }
        
        print("⏹️ 应用管理器已停止")
    }
    
    /// 刷新运行中的应用列表
    func refresh() {
        loadRunningApplications()
    }
    
    /// 根据标识符获取应用
    func getApplication(by identifier: String) -> ApplicationInfo? {
        return runningApplications.first { $0.bundleIdentifier == identifier }
    }
    
    /// 切换到指定应用
    func switchToApplication(_ app: ApplicationInfo) {
        let workspace = NSWorkspace.shared
        
        // 通过 bundle identifier 激活应用
        if !app.bundleIdentifier.isEmpty {
            workspace.launchApplication(
                withBundleIdentifier: app.bundleIdentifier,
                options: [.default],
                additionalEventParamDescriptor: nil,
                launchIdentifier: nil
            )
        } else if !app.path.isEmpty {
            // 通过路径启动
            workspace.openApplication(at: URL(fileURLWithPath: app.path), configuration: NSWorkspace.OpenConfiguration())
        } else {
            // 通过应用名称启动
            workspace.launchApplication(app.displayName)
        }
        
        print("🔄 切换到应用: \(app.displayName)")
    }
    
    /// 获取绑定的应用列表（从用户偏好中）
    func getBoundApplications() -> [ApplicationInfo] {
        let bindings = UserPreferencesManager.shared.appBindings
        let applications = bindings.map { $0.application }
        print("📋 获取到 \(applications.count) 个绑定的应用")
        return applications
    }
    
    // MARK: - Private Methods
    
    private func loadRunningApplications() {
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications
        
        var applications: [ApplicationInfo] = []
        
        for app in runningApps {
            // 过滤掉系统应用和后台应用
            guard app.activationPolicy == .regular,
                  let bundleIdentifier = app.bundleIdentifier,
                  let appName = app.localizedName else {
                continue
            }
            
            // 获取窗口数量
            let windowCount = getWindowCount(for: app)
            
            let applicationInfo = ApplicationInfo(
                bundleIdentifier: bundleIdentifier,
                name: appName,
                path: app.bundleURL?.path ?? "",
                icon: app.icon,
                isRunning: true,
                windowCount: windowCount
            )
            
            applications.append(applicationInfo)
        }
        
        // 按应用名称排序
        applications.sort { $0.displayName < $1.displayName }
        
        runningApplications = applications
        
        print("📱 加载了 \(applications.count) 个运行中的应用")
    }
    
    private func setupApplicationObserver() {
        // 监听应用启动和退出
        let workspace = NSWorkspace.shared
        
        applicationObserver = workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadRunningApplications()
        }
        
        workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadRunningApplications()
        }
    }
    
    /// 获取应用的窗口数量（使用多种策略）
    private func getWindowCount(for app: NSRunningApplication) -> Int {
        // 策略1: 使用 Accessibility API（需要权限）
        if AXIsProcessTrusted() {
            return getWindowCountWithAccessibility(for: app)
        }
        
        // 策略2: 使用简化判断（无需权限）
        return getWindowCountSimple(for: app)
    }
    
    /// 使用 Accessibility API 获取窗口数量
    private func getWindowCountWithAccessibility(for app: NSRunningApplication) -> Int {
        guard let pid = app.processIdentifier as pid_t? else {
            return 0
        }
        
        // 使用 Accessibility API 获取窗口列表
        let appElement = AXUIElementCreateApplication(pid)
        
        var windowList: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowList)
        
        // 处理权限错误
        if result == .apiDisabled {
            print("⚠️ Accessibility API 被禁用，回退到简化模式")
            return getWindowCountSimple(for: app)
        } else if result == .invalidUIElement {
            print("⚠️ 无法访问应用 \(app.localizedName ?? "Unknown") 的 UI 元素")
            return getWindowCountSimple(for: app)
        } else if result == .cannotComplete {
            print("⚠️ 无法完成窗口数量查询，回退到简化模式")
            return getWindowCountSimple(for: app)
        }
        
        if result == .success, let windows = windowList as? [AXUIElement] {
            // 过滤掉不可见或最小化的窗口
            var visibleWindowCount = 0
            for window in windows {
                // 检查窗口是否可见
                var isMinimized: CFTypeRef?
                let minResult = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &isMinimized)
                
                if minResult == .success, let minimized = isMinimized as? Bool, !minimized {
                    visibleWindowCount += 1
                }
            }
            return max(visibleWindowCount, 1)  // 至少显示1个点表示应用在运行
        }
        
        // 如果无法获取窗口信息，回退到简化模式
        return getWindowCountSimple(for: app)
    }
    
    /// 使用简化方法获取窗口数量（无需权限）
    private func getWindowCountSimple(for app: NSRunningApplication) -> Int {
        // 简化实现：根据应用状态判断
        if app.isActive {
            return 1  // 当前活跃应用显示1个点
        } else if app.isHidden {
            return 0  // 隐藏的应用不显示点
        } else {
            return 1  // 其他运行中的应用显示1个点
        }
    }
}