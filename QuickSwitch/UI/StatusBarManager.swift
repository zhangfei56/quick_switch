import Cocoa

/// 状态栏管理器
class StatusBarManager {
    
    // MARK: - Properties
    
    private var statusItem: NSStatusItem?
    private var statusBarMenu: NSMenu?
    
    weak var applicationManager: ApplicationManager?
    
    // MARK: - Initialization
    
    init() {
        setupStatusBar()
    }
    
    // MARK: - Public Methods
    
    /// 启动状态栏
    func start() {
        createStatusBarItem()
        updateStatusBarMenu()
    }
    
    /// 停止状态栏
    func stop() {
        removeStatusBarItem()
    }
    
    /// 更新状态栏图标
    func updateStatusBarIcon() {
        // 这里可以更新状态栏图标以反映当前状态
        statusItem?.button?.image = NSImage(systemSymbolName: "command", accessibilityDescription: "Quick Switch")
    }
    
    /// 显示状态栏菜单
    func showStatusBarMenu() {
        statusItem?.menu = statusBarMenu
    }
    
    /// 隐藏状态栏菜单
    func hideStatusBarMenu() {
        statusItem?.menu = nil
    }
    
    // MARK: - Private Methods
    
    private func setupStatusBar() {
        // 状态栏设置
    }
    
    private func createStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "command", accessibilityDescription: "Quick Switch")
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
    }
    
    private func removeStatusBarItem() {
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }
    
    private func updateStatusBarMenu() {
        let menu = NSMenu()
        
        // 添加模式切换菜单
        addModeSwitchMenuItems(to: menu)
        
        // 添加分隔符
        menu.addItem(NSMenuItem.separator())
        
        // 添加应用快速访问菜单
        addApplicationMenuItems(to: menu)
        
        // 添加分隔符
        menu.addItem(NSMenuItem.separator())
        
        // 添加设置菜单
        addSettingsMenuItems(to: menu)
        
        // 添加分隔符
        menu.addItem(NSMenuItem.separator())
        
        // 添加退出菜单
        addQuitMenuItem(to: menu)
        
        statusBarMenu = menu
    }
    
    private func addModeSwitchMenuItems(to menu: NSMenu) {
        let modeMenuItem = NSMenuItem(title: "切换模式", action: nil, keyEquivalent: "")
        let modeSubmenu = NSMenu()
        
        // Dock 模式
        let dockModeItem = NSMenuItem(title: "Dock 模式", action: #selector(switchToDockMode), keyEquivalent: "")
        dockModeItem.target = self
        dockModeItem.state = applicationManager?.currentMode == .dock ? .on : .off
        modeSubmenu.addItem(dockModeItem)
        
        // 切换器模式
        let runningModeItem = NSMenuItem(title: "切换器模式", action: #selector(switchToRunningMode), keyEquivalent: "")
        runningModeItem.target = self
        runningModeItem.state = applicationManager?.currentMode == .running ? .on : .off
        modeSubmenu.addItem(runningModeItem)
        
        // 自定义模式
        let customModeItem = NSMenuItem(title: "自定义模式", action: #selector(switchToCustomMode), keyEquivalent: "")
        customModeItem.target = self
        customModeItem.state = applicationManager?.currentMode == .custom ? .on : .off
        modeSubmenu.addItem(customModeItem)
        
        modeMenuItem.submenu = modeSubmenu
        menu.addItem(modeMenuItem)
    }
    
    private func addApplicationMenuItems(to menu: NSMenu) {
        guard let applicationManager = applicationManager else { return }
        
        let applications = applicationManager.getApplicationsForCurrentMode()
        
        if applications.isEmpty {
            let noAppsItem = NSMenuItem(title: "没有可用的应用", action: nil, keyEquivalent: "")
            noAppsItem.isEnabled = false
            menu.addItem(noAppsItem)
            return
        }
        
        // 添加前 9 个应用的快速访问
        for (index, app) in applications.prefix(9).enumerated() {
            let keyEquivalent = String(index + 1)
            let menuItem = NSMenuItem(title: app.displayName, action: #selector(switchToApplication(_:)), keyEquivalent: keyEquivalent)
            menuItem.target = self
            menuItem.representedObject = app
            menuItem.image = app.icon
            menu.addItem(menuItem)
        }
        
        // 如果应用超过 9 个，添加"更多"菜单
        if applications.count > 9 {
            let moreItem = NSMenuItem(title: "更多应用...", action: #selector(showMoreApplications), keyEquivalent: "")
            moreItem.target = self
            menu.addItem(moreItem)
        }
    }
    
    private func addSettingsMenuItems(to menu: NSMenu) {
        // 设置菜单
        let settingsItem = NSMenuItem(title: "设置...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        // 快捷键设置
        let shortcutsItem = NSMenuItem(title: "快捷键设置...", action: #selector(openShortcutSettings), keyEquivalent: "")
        shortcutsItem.target = self
        menu.addItem(shortcutsItem)
        
        // 静默模式设置
        let silentModeItem = NSMenuItem(title: "静默模式设置...", action: #selector(openSilentModeSettings), keyEquivalent: "")
        silentModeItem.target = self
        menu.addItem(silentModeItem)
    }
    
    private func addQuitMenuItem(to menu: NSMenu) {
        let quitItem = NSMenuItem(title: "退出 Quick Switch", action: #selector(quitApplication), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    // MARK: - Actions
    
    @objc private func statusBarButtonClicked() {
        // 状态栏按钮点击事件
        if let menu = statusBarMenu {
            statusItem?.menu = menu
            statusItem?.button?.performClick(nil)
        }
    }
    
    @objc private func switchToDockMode() {
        applicationManager?.switchMode(.dock)
        updateStatusBarMenu()
    }
    
    @objc private func switchToRunningMode() {
        applicationManager?.switchMode(.running)
        updateStatusBarMenu()
    }
    
    @objc private func switchToCustomMode() {
        applicationManager?.switchMode(.custom)
        updateStatusBarMenu()
    }
    
    @objc private func switchToApplication(_ sender: NSMenuItem) {
        guard let app = sender.representedObject as? ApplicationInfo else { return }
        applicationManager?.switchToApplication(app)
    }
    
    @objc private func showMoreApplications() {
        // 显示更多应用的窗口
        // 这里可以打开一个应用选择窗口
    }
    
    @objc private func openSettings() {
        // 打开设置窗口
        // 这里可以打开主设置窗口
    }
    
    @objc private func openShortcutSettings() {
        // 打开快捷键设置窗口
        // 这里可以打开快捷键设置窗口
    }
    
    @objc private func openSilentModeSettings() {
        // 打开静默模式设置窗口
        // 这里可以打开静默模式设置窗口
    }
    
    @objc private func quitApplication() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - 状态栏菜单更新

extension StatusBarManager {
    /// 刷新状态栏菜单
    func refreshMenu() {
        updateStatusBarMenu()
    }
    
    /// 更新应用菜单项
    func updateApplicationMenuItems() {
        // 重新创建菜单以更新应用列表
        updateStatusBarMenu()
    }
}

// MARK: - 状态栏图标管理

extension StatusBarManager {
    /// 设置状态栏图标
    func setStatusBarIcon(_ image: NSImage?) {
        statusItem?.button?.image = image
    }
    
    /// 设置状态栏图标标题
    func setStatusBarTitle(_ title: String?) {
        statusItem?.button?.title = title ?? ""
    }
    
    /// 设置状态栏图标工具提示
    func setStatusBarToolTip(_ toolTip: String?) {
        statusItem?.button?.toolTip = toolTip
    }
}

// MARK: - 状态栏可见性

extension StatusBarManager {
    /// 显示状态栏
    func showStatusBar() {
        if statusItem == nil {
            createStatusBarItem()
        }
    }
    
    /// 隐藏状态栏
    func hideStatusBar() {
        removeStatusBarItem()
    }
    
    /// 切换状态栏可见性
    func toggleStatusBarVisibility() {
        if statusItem == nil {
            showStatusBar()
        } else {
            hideStatusBar()
        }
    }
}
