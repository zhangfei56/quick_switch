import Cocoa
import Combine

/// 快捷键引擎
class ShortcutEngine: ObservableObject {
    
    // MARK: - Properties
    
    @Published var registeredShortcuts: [Shortcut] = []
    @Published var isRunning = false
    
    weak var applicationManager: ApplicationManager?
    
    private let preferencesManager = UserPreferencesManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var shortcutActions: [String: () -> Void] = [:]
    
    // MARK: - Initialization
    
    init() {
        setupDefaultShortcuts()
    }
    
    // MARK: - Public Methods
    
    /// 启动快捷键引擎
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        
        // 加载用户配置
        loadUserConfiguration()
        
        // 注册默认快捷键
        registerDefaultShortcuts()
        
        print("Shortcut engine started")
    }
    
    /// 停止快捷键引擎
    func stop() {
        guard isRunning else { return }
        
        isRunning = false
        
        // 清理资源
        cancellables.removeAll()
        shortcutActions.removeAll()
        
        print("Shortcut engine stopped")
    }
    
    /// 注册快捷键
    func registerShortcut(_ shortcut: Shortcut, action: @escaping () -> Void) {
        // 检查冲突
        if let conflict = detectConflict(for: shortcut) {
            print("Shortcut conflict detected: \(conflict)")
            return
        }
        
        // 注册快捷键
        registeredShortcuts.append(shortcut)
        shortcutActions[shortcut.identifier] = action
        
        print("Shortcut registered: \(shortcut.displayName)")
    }
    
    /// 取消注册快捷键
    func unregisterShortcut(_ shortcut: Shortcut) {
        registeredShortcuts.removeAll { $0.id == shortcut.id }
        shortcutActions.removeValue(forKey: shortcut.identifier)
        
        print("Shortcut unregistered: \(shortcut.displayName)")
    }
    
    /// 检查快捷键是否已注册
    func isShortcutRegistered(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> Bool {
        return registeredShortcuts.contains { shortcut in
            shortcut.keyCode == keyCode && shortcut.modifiers == modifiers
        }
    }
    
    /// 执行快捷键
    func executeShortcut(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        guard let shortcut = registeredShortcuts.first(where: { shortcut in
            shortcut.keyCode == keyCode && shortcut.modifiers == modifiers
        }) else {
            return
        }
        
        // 执行对应的操作
        if let action = shortcutActions[shortcut.identifier] {
            action()
        }
    }
    
    /// 检测快捷键冲突
    func detectConflicts() -> [ShortcutConflict] {
        var conflicts: [ShortcutConflict] = []
        
        for i in 0..<registeredShortcuts.count {
            for j in (i+1)..<registeredShortcuts.count {
                let shortcut1 = registeredShortcuts[i]
                let shortcut2 = registeredShortcuts[j]
                
                if shortcut1.keyCode == shortcut2.keyCode && shortcut1.modifiers == shortcut2.modifiers {
                    let conflict = ShortcutConflict(
                        shortcut1: shortcut1,
                        shortcut2: shortcut2,
                        description: "快捷键冲突: \(shortcut1.displayName) 和 \(shortcut2.displayName)"
                    )
                    conflicts.append(conflict)
                }
            }
        }
        
        return conflicts
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultShortcuts() {
        // 设置默认的数字键快捷键 (Option + 1-9)
        for i in 1...9 {
            let keyCode = UInt16(17 + i) // 数字键 1-9 的 keyCode
            let shortcut = Shortcut(
                keyCode: keyCode,
                modifiers: .option,
                identifier: "app_switch_\(i)"
            )
            
            let action = { [weak self] in
                self?.switchToApplication(at: i - 1)
            }
            
            registerShortcut(shortcut, action: action)
        }
    }
    
    private func loadUserConfiguration() {
        let preferences = preferencesManager.load()
        
        // 更新修饰键
        updateModifierKey(preferences.modifierKey)
    }
    
    private func registerDefaultShortcuts() {
        // 注册应用切换快捷键
        registerApplicationSwitchShortcuts()
    }
    
    private func registerApplicationSwitchShortcuts() {
        // 为当前模式的应用注册快捷键
        guard let applicationManager = applicationManager else { return }
        
        let applications = applicationManager.getApplicationsForCurrentMode()
        
        for (index, app) in applications.prefix(9).enumerated() {
            let keyCode = UInt16(17 + index + 1) // 数字键 1-9
            let shortcut = Shortcut(
                keyCode: keyCode,
                modifiers: .option,
                identifier: "app_\(app.bundleIdentifier)"
            )
            
            let action = { [weak self] in
                self?.switchToApplication(app)
            }
            
            registerShortcut(shortcut, action: action)
        }
    }
    
    private func switchToApplication(at index: Int) {
        guard let applicationManager = applicationManager else { return }
        
        let applications = applicationManager.getApplicationsForCurrentMode()
        
        guard index < applications.count else { return }
        
        let app = applications[index]
        applicationManager.switchToApplication(app)
    }
    
    private func switchToApplication(_ app: ApplicationInfo) {
        applicationManager?.switchToApplication(app)
    }
    
    private func updateModifierKey(_ modifier: NSEvent.ModifierFlags) {
        // 更新所有快捷键的修饰键
        for shortcut in registeredShortcuts {
            let newShortcut = Shortcut(
                keyCode: shortcut.keyCode,
                modifiers: modifier,
                identifier: shortcut.identifier
            )
            
            if let action = shortcutActions[shortcut.identifier] {
                unregisterShortcut(shortcut)
                registerShortcut(newShortcut, action: action)
            }
        }
    }

    // MARK: - Public API
    
    /// 更新修饰键并重新注册快捷键
    func setModifierKey(_ modifier: NSEvent.ModifierFlags) {
        updateModifierKey(modifier)
        reregisterAllShortcuts()
    }
    
    private func detectConflict(for shortcut: Shortcut) -> ShortcutConflict? {
        for existingShortcut in registeredShortcuts {
            if existingShortcut.keyCode == shortcut.keyCode && existingShortcut.modifiers == shortcut.modifiers {
                return ShortcutConflict(
                    shortcut1: existingShortcut,
                    shortcut2: shortcut,
                    description: "快捷键冲突: \(existingShortcut.displayName) 和 \(shortcut.displayName)"
                )
            }
        }
        return nil
    }
}

// MARK: - 快捷键冲突

struct ShortcutConflict {
    let shortcut1: Shortcut
    let shortcut2: Shortcut
    let description: String
}

// MARK: - 快捷键验证

extension ShortcutEngine {
    /// 验证快捷键是否有效
    func validateShortcut(_ shortcut: Shortcut) -> ShortcutValidationResult {
        // 检查是否为空
        if shortcut.keyCode == 0 {
            return .invalid("无效的按键")
        }
        
        // 检查修饰键
        if shortcut.modifiers.isEmpty {
            return .invalid("必须至少包含一个修饰键")
        }
        
        // 检查冲突
        if let conflict = detectConflict(for: shortcut) {
            return .conflict(conflict)
        }
        
        // 检查系统快捷键冲突
        if isSystemShortcut(shortcut) {
            return .systemConflict("与系统快捷键冲突")
        }
        
        return .valid
    }
    
    private func isSystemShortcut(_ shortcut: Shortcut) -> Bool {
        // 检查常见的系统快捷键
        let systemShortcuts: [(UInt16, NSEvent.ModifierFlags)] = [
            (48, .command), // Cmd+Tab
            (48, [.command, .shift]), // Cmd+Shift+Tab
            (53, .command), // Cmd+Esc
            (49, .command), // Cmd+Space
        ]
        
        return systemShortcuts.contains { keyCode, modifiers in
            shortcut.keyCode == keyCode && shortcut.modifiers == modifiers
        }
    }
}

// MARK: - 快捷键验证结果

enum ShortcutValidationResult {
    case valid
    case invalid(String)
    case conflict(ShortcutConflict)
    case systemConflict(String)
    
    var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .invalid(let message):
            return message
        case .conflict(let conflict):
            return conflict.description
        case .systemConflict(let message):
            return message
        }
    }
}

// MARK: - 快捷键管理

extension ShortcutEngine {
    /// 重新注册所有快捷键
    func reregisterAllShortcuts() {
        // 清除现有快捷键
        let existingShortcuts = registeredShortcuts
        for shortcut in existingShortcuts {
            unregisterShortcut(shortcut)
        }
        
        // 重新注册
        registerDefaultShortcuts()
    }
    
    /// 更新应用快捷键
    func updateApplicationShortcuts() {
        // 移除现有的应用快捷键
        let appShortcuts = registeredShortcuts.filter { $0.identifier.hasPrefix("app_") }
        for shortcut in appShortcuts {
            unregisterShortcut(shortcut)
        }
        
        // 重新注册应用快捷键
        registerApplicationSwitchShortcuts()
    }
}
