import Cocoa
import Combine

/// 应用管理器
class ApplicationManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var dockApplications: [ApplicationInfo] = []
    @Published var runningApplications: [ApplicationInfo] = []
    @Published var customApplications: [ApplicationInfo] = []
    @Published var currentMode: SwitchMode = .dock
    
    // MARK: - Private Properties
    
    private let systemIntegration = SystemIntegrationManager.shared
    private let preferencesManager = UserPreferencesManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var isRunning = false
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// 启动应用管理器
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        
        // 加载用户偏好
        loadUserPreferences()
        
        // 开始监听系统事件
        startSystemEventMonitoring()
        
        // 刷新应用列表
        refreshApplicationLists()
        
        print("Application manager started")
    }
    
    /// 停止应用管理器
    func stop() {
        guard isRunning else { return }
        
        isRunning = false
        
        // 停止系统事件监听
        systemIntegration.stopAllMonitoring()
        
        // 清理资源
        cancellables.removeAll()
        
        print("Application manager stopped")
    }
    
    /// 切换模式
    func switchMode(_ mode: SwitchMode) {
        currentMode = mode
        preferencesManager.updateSwitchMode(mode)
        
        // 根据模式刷新应用列表
        refreshApplicationLists()
    }
    
    /// 刷新应用列表
    func refreshApplicationLists() {
        switch currentMode {
        case .dock:
            refreshDockApplications()
        case .running:
            refreshRunningApplications()
        case .custom:
            refreshCustomApplications()
        }
    }
    
    /// 启动应用
    func launchApplication(_ app: ApplicationInfo) {
        guard let url = URL(fileURLWithPath: app.path) as URL? else {
            print("Invalid application path: \(app.path)")
            return
        }
        
        let success = systemIntegration.launchApplication(at: url)
        if success {
            // 更新使用统计
            updateUsageStatistics(for: app)
        }
    }
    
    /// 切换到应用
    func switchToApplication(_ app: ApplicationInfo) {
        // 查找对应的运行中的应用
        let runningApp = systemIntegration.getRunningApplications().first { runningApp in
            runningApp.bundleIdentifier == app.bundleIdentifier
        }
        
        if let runningApp = runningApp {
            let success = systemIntegration.activateApplication(runningApp)
            if success {
                // 更新使用统计
                updateUsageStatistics(for: app)
            }
        } else {
            // 应用未运行，尝试启动
            launchApplication(app)
        }
    }
    
    /// 添加自定义应用
    func addCustomApplication(_ app: ApplicationInfo) {
        guard !customApplications.contains(where: { $0.bundleIdentifier == app.bundleIdentifier }) else {
            return
        }
        
        customApplications.append(app)
        saveCustomApplications()
    }
    
    /// 移除自定义应用
    func removeCustomApplication(_ app: ApplicationInfo) {
        customApplications.removeAll { $0.bundleIdentifier == app.bundleIdentifier }
        saveCustomApplications()
    }
    
    /// 获取当前模式的应用列表
    func getApplicationsForCurrentMode() -> [ApplicationInfo] {
        switch currentMode {
        case .dock:
            return dockApplications
        case .running:
            return runningApplications
        case .custom:
            return customApplications
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // 监听用户偏好变化
        preferencesManager.permissionStatusPublisher
            .sink { [weak self] _ in
                self?.refreshApplicationLists()
            }
            .store(in: &cancellables)
    }
    
    private func loadUserPreferences() {
        let preferences = preferencesManager.load()
        currentMode = preferences.switchMode
        loadCustomApplications()
    }
    
    private func startSystemEventMonitoring() {
        // 监听应用启动
        systemIntegration.startMonitoringApplicationLaunches { [weak self] app in
            self?.handleApplicationLaunched(app)
        }
        
        // 监听应用终止
        systemIntegration.startMonitoringApplicationTerminations { [weak self] app in
            self?.handleApplicationTerminated(app)
        }
        
        // 监听应用激活
        systemIntegration.startMonitoringApplicationActivations { [weak self] app in
            self?.handleApplicationActivated(app)
        }
    }
    
    private func refreshDockApplications() {
        let runningApps = systemIntegration.getRunningApplications()
        let dockApps = systemIntegration.getDockApplications()
        
        dockApplications = dockApps.compactMap { app in
            systemIntegration.getApplicationInfo(for: app)
        }.sorted()
    }
    
    private func refreshRunningApplications() {
        let runningApps = systemIntegration.getRunningApplications()
        
        runningApplications = runningApps.compactMap { app in
            systemIntegration.getApplicationInfo(for: app)
        }.sorted()
    }
    
    private func refreshCustomApplications() {
        // 自定义应用列表从用户偏好中加载
        loadCustomApplications()
    }
    
    private func handleApplicationLaunched(_ app: NSRunningApplication) {
        DispatchQueue.main.async { [weak self] in
            self?.refreshApplicationLists()
        }
    }
    
    private func handleApplicationTerminated(_ app: NSRunningApplication) {
        DispatchQueue.main.async { [weak self] in
            self?.refreshApplicationLists()
        }
    }
    
    private func handleApplicationActivated(_ app: NSRunningApplication) {
        // 可以在这里添加应用激活时的逻辑
    }
    
    private func updateUsageStatistics(for app: ApplicationInfo) {
        // 这里可以集成使用统计功能
        print("Application used: \(app.name)")
    }
    
    private func loadCustomApplications() {
        // 从用户偏好中加载自定义应用列表
        let apps = preferencesManager.loadCustomApplications()
        customApplications = apps.sorted()
    }
    
    private func saveCustomApplications() {
        // 保存自定义应用列表到用户偏好
        preferencesManager.saveCustomApplications(customApplications)
    }
}

// MARK: - 应用搜索

extension ApplicationManager {
    /// 搜索应用
    func searchApplications(query: String) -> [ApplicationInfo] {
        let allApps = getApplicationsForCurrentMode()
        
        guard !query.isEmpty else {
            return allApps
        }
        
        return allApps.filter { app in
            app.name.localizedCaseInsensitiveContains(query) ||
            app.bundleIdentifier.localizedCaseInsensitiveContains(query)
        }
    }
}

// MARK: - 应用排序

extension ApplicationManager {
    /// 按使用频率排序
    func sortByUsageFrequency() {
        switch currentMode {
        case .dock:
            dockApplications.sort { $0.usageCount > $1.usageCount }
        case .running:
            runningApplications.sort { $0.usageCount > $1.usageCount }
        case .custom:
            customApplications.sort { $0.usageCount > $1.usageCount }
        }
    }
    
    /// 按名称排序
    func sortByName() {
        switch currentMode {
        case .dock:
            dockApplications.sort()
        case .running:
            runningApplications.sort()
        case .custom:
            customApplications.sort()
        }
    }
    
    /// 按最近使用时间排序
    func sortByLastUsed() {
        switch currentMode {
        case .dock:
            dockApplications.sort { app1, app2 in
                guard let date1 = app1.lastUsed, let date2 = app2.lastUsed else {
                    return app1.lastUsed != nil
                }
                return date1 > date2
            }
        case .running:
            runningApplications.sort { app1, app2 in
                guard let date1 = app1.lastUsed, let date2 = app2.lastUsed else {
                    return app1.lastUsed != nil
                }
                return date1 > date2
            }
        case .custom:
            customApplications.sort { app1, app2 in
                guard let date1 = app1.lastUsed, let date2 = app2.lastUsed else {
                    return app1.lastUsed != nil
                }
                return date1 > date2
            }
        }
    }
}
