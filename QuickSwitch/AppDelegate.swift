import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Properties
    
    private var statusBarManager: StatusBarManager?
    private var applicationManager: ApplicationManager?
    private var shortcutEngine: ShortcutEngine?
    private var eventListenerService: EventListenerService?
    private var silentModeManager: SilentModeManager?
    private var modeSwitcher: ModeSwitcher?
    private var launchBarDisplay: LaunchBarDisplay?
    private var settingsWindowController: SettingsWindowController?
    
    // MARK: - Application Lifecycle
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        checkAccessibilityPermission()
        setupApplication()
        initializeServices()
        startServices()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        stopServices()
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - Private Methods
    
    private func setupApplication() {
        // 设置为后台应用，不显示在 Dock 中
        NSApp.setActivationPolicy(.accessory)
        
        // 禁用应用菜单
        NSApp.mainMenu = nil
    }
    
    private func checkAccessibilityPermission() {
        let accessibilityManager = AccessibilityManager.shared
        
        if !accessibilityManager.isAccessibilityEnabled {
            // 请求辅助功能权限
            accessibilityManager.requestAccessibilityPermission()
            
            // 显示权限提示
            showPermissionAlert()
        }
    }
    
    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "需要辅助功能权限"
        alert.informativeText = "Quick Switch 需要辅助功能权限来监听全局快捷键。请在系统偏好设置中授予权限。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "打开系统偏好设置")
        alert.addButton(withTitle: "稍后")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            AccessibilityManager.shared.openAccessibilityPreferences()
        }
    }
    
    private func initializeServices() {
        // 初始化核心服务
        applicationManager = ApplicationManager()
        shortcutEngine = ShortcutEngine()
        eventListenerService = EventListenerService()
        silentModeManager = SilentModeManager()
        
        // 初始化业务逻辑服务
        if let appManager = applicationManager {
            modeSwitcher = ModeSwitcher(applicationManager: appManager)
        }
        
        // 初始化 UI 服务
        statusBarManager = StatusBarManager()
        launchBarDisplay = LaunchBarDisplay()
        settingsWindowController = SettingsWindowController()
        
        // 设置服务间的依赖关系
        setupServiceDependencies()
    }
    
    private func setupServiceDependencies() {
        guard let applicationManager = applicationManager,
              let shortcutEngine = shortcutEngine,
              let eventListenerService = eventListenerService else {
            return
        }
        
        // 设置快捷键引擎的应用管理器
        shortcutEngine.applicationManager = applicationManager
        
        // 设置事件监听服务的快捷键引擎
        eventListenerService.shortcutEngine = shortcutEngine
        
        // 设置状态栏管理器的应用管理器
        statusBarManager?.applicationManager = applicationManager
        statusBarManager?.settingsWindowController = settingsWindowController
        statusBarManager?.launchBarDisplay = launchBarDisplay
        
        // 集成静默模式管理器
        setupSilentModeIntegration()

        // 订阅偏好设置变化
        subscribeToPreferencesChanges()
        
        // 订阅应用列表和模式变化，刷新菜单和快捷键
        applicationManager.$dockApplications
            .sink { [weak self] _ in
                self?.statusBarManager?.refreshMenu()
                self?.shortcutEngine?.updateApplicationShortcuts()
            }
            .store(in: &cancellables)
        
        applicationManager.$runningApplications
            .sink { [weak self] _ in
                self?.statusBarManager?.refreshMenu()
                self?.shortcutEngine?.updateApplicationShortcuts()
            }
            .store(in: &cancellables)
        
        applicationManager.$customApplications
            .sink { [weak self] _ in
                self?.statusBarManager?.refreshMenu()
                self?.shortcutEngine?.updateApplicationShortcuts()
            }
            .store(in: &cancellables)
        
        applicationManager.$currentMode
            .sink { [weak self] _ in
                self?.statusBarManager?.refreshMenu()
                self?.shortcutEngine?.updateApplicationShortcuts()
            }
            .store(in: &cancellables)
    }
    
    private func setupSilentModeIntegration() {
        // 监听静默模式状态变化，禁用/启用快捷键
        silentModeManager?.$isInSilentMode
            .sink { [weak self] isInSilentMode in
                if isInSilentMode {
                    self?.eventListenerService?.stop()
                    print("进入静默模式，快捷键已禁用")
                } else {
                    self?.eventListenerService?.start()
                    print("退出静默模式，快捷键已启用")
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func startServices() {
        // 启动应用管理
        applicationManager?.start()
        
        // 启动快捷键引擎
        shortcutEngine?.start()
        // 加载持久化快捷键
        shortcutEngine?.loadPersistedShortcuts()
        
        // 启动事件监听
        if !(silentModeManager?.isInSilentMode ?? false) {
            eventListenerService?.start()
        }
        
        // 启动状态栏
        statusBarManager?.start()
        statusBarManager?.refreshMenu()
        
        print("Quick Switch 已启动")
        print("使用 Option + 1-9 来快速切换应用")
    }

    // MARK: - Preferences Wiring
    
    private func subscribeToPreferencesChanges() {
        let prefsManager = UserPreferencesManager.shared
        prefsManager.preferencesPublisher
            .sink { [weak self] preferences in
                guard let self = self else { return }
                // 更新应用管理器模式（不回写偏好）
                if let appManager = self.applicationManager {
                    appManager.currentMode = preferences.switchMode
                    appManager.refreshApplicationLists()
                }
                // 更新快捷键修饰键
                self.shortcutEngine?.setModifierKey(preferences.modifierKey)
                // 刷新状态栏菜单
                self.statusBarManager?.refreshMenu()
            }
            .store(in: &cancellables)
    }
    
    private func stopServices() {
        // 停止所有服务
        eventListenerService?.stop()
        shortcutEngine?.stop()
        applicationManager?.stop()
        statusBarManager?.stop()
        
        print("Quick Switch 已停止")
    }
}

// MARK: - Combine Import

import Combine

