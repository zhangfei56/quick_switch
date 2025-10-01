import Cocoa
import Combine

/// 模式切换器
class ModeSwitcher: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentMode: SwitchMode = .dock
    @Published var availableApplications: [ApplicationInfo] = []
    
    // MARK: - Private Properties
    
    private let applicationManager: ApplicationManager
    private let preferencesManager = UserPreferencesManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(applicationManager: ApplicationManager) {
        self.applicationManager = applicationManager
        loadCurrentMode()
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// 切换到指定模式
    func switchMode(_ mode: SwitchMode) {
        guard currentMode != mode else { return }
        
        currentMode = mode
        saveCurrentMode()
        updateAvailableApplications()
        
        // 发送模式切换通知
        NotificationCenter.default.post(
            name: .modeSwitched,
            object: self,
            userInfo: ["mode": mode]
        )
        
        print("Switched to mode: \(mode.displayName)")
    }
    
    /// 获取当前模式的应用列表
    func getApplicationsForCurrentMode() -> [ApplicationInfo] {
        return availableApplications
    }
    
    /// 获取指定模式的应用列表
    func getApplications(for mode: SwitchMode) -> [ApplicationInfo] {
        switch mode {
        case .dock:
            return applicationManager.dockApplications
        case .running:
            return applicationManager.runningApplications
        case .custom:
            return applicationManager.customApplications
        }
    }
    
    /// 刷新当前模式的应用列表
    func refreshCurrentMode() {
        updateAvailableApplications()
    }
    
    /// 循环切换模式
    func cycleMode() {
        let modes = SwitchMode.allCases
        guard let currentIndex = modes.firstIndex(of: currentMode) else { return }
        
        let nextIndex = (currentIndex + 1) % modes.count
        switchMode(modes[nextIndex])
    }
    
    // MARK: - Private Methods
    
    private func loadCurrentMode() {
        let preferences = preferencesManager.load()
        currentMode = preferences.switchMode
        updateAvailableApplications()
    }
    
    private func saveCurrentMode() {
        preferencesManager.updateSwitchMode(currentMode)
    }
    
    private func setupBindings() {
        // 监听应用管理器的应用列表变化
        applicationManager.$dockApplications
            .sink { [weak self] _ in
                self?.updateAvailableApplicationsIfNeeded(.dock)
            }
            .store(in: &cancellables)
        
        applicationManager.$runningApplications
            .sink { [weak self] _ in
                self?.updateAvailableApplicationsIfNeeded(.running)
            }
            .store(in: &cancellables)
        
        applicationManager.$customApplications
            .sink { [weak self] _ in
                self?.updateAvailableApplicationsIfNeeded(.custom)
            }
            .store(in: &cancellables)
    }
    
    private func updateAvailableApplicationsIfNeeded(_ mode: SwitchMode) {
        guard currentMode == mode else { return }
        updateAvailableApplications()
    }
    
    private func updateAvailableApplications() {
        availableApplications = getApplications(for: currentMode)
    }
}

// MARK: - 模式信息

extension ModeSwitcher {
    
    /// 获取模式信息
    func getModeInfo() -> ModeInfo {
        return ModeInfo(
            currentMode: currentMode,
            applicationCount: availableApplications.count,
            description: currentMode.description
        )
    }
    
    /// 获取所有模式的信息
    func getAllModesInfo() -> [ModeInfo] {
        return SwitchMode.allCases.map { mode in
            ModeInfo(
                currentMode: mode,
                applicationCount: getApplications(for: mode).count,
                description: mode.description
            )
        }
    }
}

// MARK: - 模式验证

extension ModeSwitcher {
    
    /// 验证模式是否可用
    func isModeAvailable(_ mode: SwitchMode) -> Bool {
        let apps = getApplications(for: mode)
        return !apps.isEmpty
    }
    
    /// 获取可用的模式列表
    func getAvailableModes() -> [SwitchMode] {
        return SwitchMode.allCases.filter { isModeAvailable($0) }
    }
    
    /// 验证当前模式
    func validateCurrentMode() -> ModeValidationResult {
        if availableApplications.isEmpty {
            return .noApplications("当前模式没有可用的应用")
        }
        
        if availableApplications.count > 9 {
            return .tooManyApplications("当前模式有 \(availableApplications.count) 个应用，只有前 9 个可以使用快捷键")
        }
        
        return .valid
    }
}

// MARK: - 模式排序

extension ModeSwitcher {
    
    /// 应用排序方式
    enum SortOrder {
        case alphabetical       // 字母顺序
        case usageFrequency    // 使用频率
        case lastUsed          // 最近使用
        case custom            // 自定义顺序
    }
    
    /// 设置应用排序方式
    func setSortOrder(_ order: SortOrder) {
        switch order {
        case .alphabetical:
            availableApplications.sort { $0.name < $1.name }
        case .usageFrequency:
            availableApplications.sort { $0.usageCount > $1.usageCount }
        case .lastUsed:
            availableApplications.sort { app1, app2 in
                guard let date1 = app1.lastUsed, let date2 = app2.lastUsed else {
                    return app1.lastUsed != nil
                }
                return date1 > date2
            }
        case .custom:
            // 保持用户自定义的顺序
            break
        }
    }
}

// MARK: - 快捷访问

extension ModeSwitcher {
    
    /// 获取快捷键对应的应用
    func getApplication(at index: Int) -> ApplicationInfo? {
        guard index >= 0 && index < availableApplications.count else {
            return nil
        }
        return availableApplications[index]
    }
    
    /// 获取应用的快捷键索引
    func getShortcutIndex(for app: ApplicationInfo) -> Int? {
        return availableApplications.firstIndex(of: app)
    }
    
    /// 检查应用是否有快捷键
    func hasShortcut(for app: ApplicationInfo) -> Bool {
        guard let index = getShortcutIndex(for: app) else { return false }
        return index < 9 // 只有前9个应用有快捷键
    }
}

// MARK: - 辅助类型

/// 模式信息
struct ModeInfo {
    let currentMode: SwitchMode
    let applicationCount: Int
    let description: String
}

/// 模式验证结果
enum ModeValidationResult {
    case valid
    case noApplications(String)
    case tooManyApplications(String)
    
    var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }
    
    var message: String? {
        switch self {
        case .valid:
            return nil
        case .noApplications(let msg),
             .tooManyApplications(let msg):
            return msg
        }
    }
}

// MARK: - 通知

extension Notification.Name {
    static let modeSwitched = Notification.Name("ModeSwitched")
    static let applicationsUpdated = Notification.Name("ApplicationsUpdated")
}

// MARK: - 模式推荐

extension ModeSwitcher {
    
    /// 获取推荐的模式
    func getRecommendedMode() -> SwitchMode {
        let preferences = preferencesManager.load()
        
        // 如果用户有自定义应用，推荐自定义模式
        if !applicationManager.customApplications.isEmpty {
            return .custom
        }
        
        // 如果运行的应用较多，推荐切换器模式
        if applicationManager.runningApplications.count > 5 {
            return .running
        }
        
        // 默认推荐 Dock 模式
        return .dock
    }
    
    /// 获取模式切换建议
    func getModeSwitchSuggestion() -> String? {
        let currentAppCount = availableApplications.count
        
        if currentMode == .dock && currentAppCount == 0 {
            return "Dock 模式没有可用应用，建议切换到运行中应用模式"
        }
        
        if currentMode == .running && currentAppCount > 9 {
            return "运行中应用过多(\(currentAppCount)个)，建议使用自定义模式"
        }
        
        if currentMode == .custom && currentAppCount == 0 {
            return "请添加应用到自定义列表，或切换到其他模式"
        }
        
        return nil
    }
}

// MARK: - 模式历史

extension ModeSwitcher {
    
    private static var modeHistory: [SwitchMode] = []
    
    /// 记录模式切换历史
    func recordModeSwitch() {
        ModeSwitcher.modeHistory.append(currentMode)
        
        // 只保留最近10次切换记录
        if ModeSwitcher.modeHistory.count > 10 {
            ModeSwitcher.modeHistory.removeFirst()
        }
    }
    
    /// 获取最常用的模式
    func getMostUsedMode() -> SwitchMode? {
        guard !ModeSwitcher.modeHistory.isEmpty else { return nil }
        
        let counts = ModeSwitcher.modeHistory.reduce(into: [:]) { counts, mode in
            counts[mode, default: 0] += 1
        }
        
        return counts.max(by: { $0.value < $1.value })?.key
    }
}
