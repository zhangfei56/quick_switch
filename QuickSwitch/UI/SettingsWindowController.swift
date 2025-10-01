import Cocoa
import SwiftUI

/// 设置窗口控制器
class SettingsWindowController: NSWindowController {
    
    // MARK: - Properties
    
    private var settingsWindow: NSWindow?
    private let preferencesManager = UserPreferencesManager.shared
    
    // MARK: - Initialization
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Quick Switch 设置"
        window.center()
        window.isReleasedWhenClosed = false
        
        self.init(window: window)
        self.settingsWindow = window
        
        setupWindowContent()
    }
    
    // MARK: - Public Methods
    
    /// 显示设置窗口
    func showSettingsWindow() {
        guard let window = window else { return }
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /// 隐藏设置窗口
    func hideSettingsWindow() {
        window?.orderOut(nil)
    }
    
    /// 切换窗口显示状态
    func toggleSettingsWindow() {
        guard let window = window else { return }
        
        if window.isVisible {
            hideSettingsWindow()
        } else {
            showSettingsWindow()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupWindowContent() {
        guard let window = window else { return }
        
        // 创建标签页视图控制器
        let tabViewController = createTabViewController()
        
        window.contentViewController = tabViewController
        window.toolbar = createToolbar()
    }
    
    private func createTabViewController() -> NSTabViewController {
        let tabViewController = NSTabViewController()
        tabViewController.tabStyle = .toolbar
        
        // 通用设置标签
        let generalTab = createGeneralTab()
        tabViewController.addTabViewItem(generalTab)
        
        // 快捷键设置标签
        let shortcutsTab = createShortcutsTab()
        tabViewController.addTabViewItem(shortcutsTab)
        
        // 应用管理标签
        let applicationsTab = createApplicationsTab()
        tabViewController.addTabViewItem(applicationsTab)
        
        // 静默模式标签
        let silentModeTab = createSilentModeTab()
        tabViewController.addTabViewItem(silentModeTab)
        
        // 外观设置标签
        let appearanceTab = createAppearanceTab()
        tabViewController.addTabViewItem(appearanceTab)
        
        // 高级设置标签
        let advancedTab = createAdvancedTab()
        tabViewController.addTabViewItem(advancedTab)
        
        return tabViewController
    }
    
    // MARK: - Tab Creation
    
    private func createGeneralTab() -> NSTabViewItem {
        let viewController = GeneralSettingsViewController()
        let tabItem = NSTabViewItem(viewController: viewController)
        tabItem.label = "通用"
        tabItem.image = NSImage(systemSymbolName: "gear", accessibilityDescription: "通用设置")
        return tabItem
    }
    
    private func createShortcutsTab() -> NSTabViewItem {
        let viewController = ShortcutsSettingsViewController()
        let tabItem = NSTabViewItem(viewController: viewController)
        tabItem.label = "快捷键"
        tabItem.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "快捷键设置")
        return tabItem
    }
    
    private func createApplicationsTab() -> NSTabViewItem {
        let viewController = ApplicationsSettingsViewController()
        let tabItem = NSTabViewItem(viewController: viewController)
        tabItem.label = "应用"
        tabItem.image = NSImage(systemSymbolName: "square.grid.2x2", accessibilityDescription: "应用管理")
        return tabItem
    }
    
    private func createSilentModeTab() -> NSTabViewItem {
        let viewController = SilentModeSettingsViewController()
        let tabItem = NSTabViewItem(viewController: viewController)
        tabItem.label = "静默模式"
        tabItem.image = NSImage(systemSymbolName: "speaker.slash", accessibilityDescription: "静默模式")
        return tabItem
    }
    
    private func createAppearanceTab() -> NSTabViewItem {
        let viewController = AppearanceSettingsViewController()
        let tabItem = NSTabViewItem(viewController: viewController)
        tabItem.label = "外观"
        tabItem.image = NSImage(systemSymbolName: "paintbrush", accessibilityDescription: "外观设置")
        return tabItem
    }
    
    private func createAdvancedTab() -> NSTabViewItem {
        let viewController = AdvancedSettingsViewController()
        let tabItem = NSTabViewItem(viewController: viewController)
        tabItem.label = "高级"
        tabItem.image = NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: "高级设置")
        return tabItem
    }
    
    // MARK: - Toolbar
    
    private func createToolbar() -> NSToolbar {
        let toolbar = NSToolbar(identifier: "SettingsToolbar")
        toolbar.displayMode = .iconOnly
        toolbar.showsBaselineSeparator = true
        return toolbar
    }
}

// MARK: - 通用设置视图控制器

class GeneralSettingsViewController: NSViewController {
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
    }
    
    private let preferencesManager = UserPreferencesManager.shared
    private let applicationManager = ApplicationManager()
    private let shortcutEngine = ShortcutEngine()
    
    private var modePopUp: NSPopUpButton!
    private var modifierPopUp: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        let titleLabel = NSTextField(labelWithString: "通用设置")
        titleLabel.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.frame = NSRect(x: 20, y: view.bounds.height - 50, width: 200, height: 30)
        view.addSubview(titleLabel)
        
        // 模式选择
        let modeLabel = NSTextField(labelWithString: "切换模式:")
        modeLabel.frame = NSRect(x: 20, y: view.bounds.height - 100, width: 100, height: 20)
        view.addSubview(modeLabel)
        
        modePopUp = NSPopUpButton(frame: NSRect(x: 130, y: view.bounds.height - 105, width: 200, height: 25))
        modePopUp.addItems(withTitles: ["Dock 模式", "切换器模式", "自定义模式"])
        modePopUp.target = self
        modePopUp.action = #selector(modeChanged)
        view.addSubview(modePopUp)
        
        // 修饰键选择
        let modifierLabel = NSTextField(labelWithString: "修饰键:")
        modifierLabel.frame = NSRect(x: 20, y: view.bounds.height - 140, width: 100, height: 20)
        view.addSubview(modifierLabel)
        
        modifierPopUp = NSPopUpButton(frame: NSRect(x: 130, y: view.bounds.height - 145, width: 200, height: 25))
        modifierPopUp.addItems(withTitles: ["Option", "Control", "Command", "Shift"])
        modifierPopUp.target = self
        modifierPopUp.action = #selector(modifierChanged)
        view.addSubview(modifierPopUp)
        
        // 状态栏图标
        let statusBarCheckbox = NSButton(checkboxWithTitle: "显示状态栏图标", target: nil, action: nil)
        statusBarCheckbox.frame = NSRect(x: 20, y: view.bounds.height - 180, width: 200, height: 20)
        statusBarCheckbox.state = .on
        view.addSubview(statusBarCheckbox)
        
        // 启动时运行
        let launchCheckbox = NSButton(checkboxWithTitle: "登录时自动启动", target: nil, action: nil)
        launchCheckbox.frame = NSRect(x: 20, y: view.bounds.height - 210, width: 200, height: 20)
        view.addSubview(launchCheckbox)
    }

    // MARK: - Actions
    
    @objc private func modeChanged() {
        let selectedIndex = modePopUp.indexOfSelectedItem
        let mode: SwitchMode = {
            switch selectedIndex {
            case 0: return .dock
            case 1: return .running
            default: return .custom
            }
        }()
        preferencesManager.updateSwitchMode(mode)
        NotificationCenter.default.post(name: .preferencesChanged, object: nil)
    }
    
    @objc private func modifierChanged() {
        let selectedIndex = modifierPopUp.indexOfSelectedItem
        let modifier: NSEvent.ModifierFlags = {
            switch selectedIndex {
            case 1: return .control
            case 2: return .command
            case 3: return .shift
            default: return .option
            }
        }()
        preferencesManager.updateModifierKey(modifier)
        NotificationCenter.default.post(name: .preferencesChanged, object: nil)
    }
}

// MARK: - 快捷键设置视图控制器

class ShortcutsSettingsViewController: NSViewController {
    private let shortcutEngine = ShortcutEngine()
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        let titleLabel = NSTextField(labelWithString: "快捷键设置")
        titleLabel.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.frame = NSRect(x: 20, y: view.bounds.height - 50, width: 200, height: 30)
        view.addSubview(titleLabel)
        
        let descLabel = NSTextField(labelWithString: "为应用配置快捷键 (1-9 数字键)")
        descLabel.frame = NSRect(x: 20, y: view.bounds.height - 80, width: 400, height: 20)
        view.addSubview(descLabel)
        
        // 快捷键列表
        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 50, width: view.bounds.width - 40, height: view.bounds.height - 150))
        scrollView.hasVerticalScroller = true
        view.addSubview(scrollView)
        
        // 冲突检测开关
        let conflictCheckbox = NSButton(checkboxWithTitle: "启用快捷键冲突检测", target: nil, action: nil)
        conflictCheckbox.frame = NSRect(x: 20, y: 20, width: 200, height: 20)
        conflictCheckbox.state = .on
        view.addSubview(conflictCheckbox)

        // 导入导出按钮
        let exportButton = NSButton(title: "导出快捷键", target: self, action: #selector(exportShortcuts))
        exportButton.frame = NSRect(x: view.bounds.width - 230, y: 15, width: 100, height: 28)
        view.addSubview(exportButton)
        
        let importButton = NSButton(title: "导入快捷键", target: self, action: #selector(importShortcuts))
        importButton.frame = NSRect(x: view.bounds.width - 120, y: 15, width: 100, height: 28)
        view.addSubview(importButton)
    }

    // MARK: - Actions
    
    @objc private func exportShortcuts() {
        guard let data = shortcutEngine.exportShortcuts() else { return }
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["json"]
        savePanel.nameFieldStringValue = "QuickSwitchShortcuts.json"
        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                try? data.write(to: url)
            }
        }
    }
    
    @objc private func importShortcuts() {
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = ["json"]
        openPanel.allowsMultipleSelection = false
        openPanel.begin { [weak self] result in
            guard result == .OK, let url = openPanel.url, let data = try? Data(contentsOf: url) else { return }
            do {
                try self?.shortcutEngine.importShortcuts(from: data)
            } catch {
                let alert = NSAlert()
                alert.messageText = "导入失败"
                alert.informativeText = "无法解析快捷键配置。"
                alert.alertStyle = .warning
                alert.runModal()
            }
        }
    }
}

// MARK: - 应用管理视图控制器

class ApplicationsSettingsViewController: NSViewController {
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private let preferencesManager = UserPreferencesManager.shared
    private let systemIntegration = SystemIntegrationManager.shared
    private var apps: [ApplicationInfo] = []
    
    private func setupUI() {
        let titleLabel = NSTextField(labelWithString: "应用管理")
        titleLabel.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.frame = NSRect(x: 20, y: view.bounds.height - 50, width: 200, height: 30)
        view.addSubview(titleLabel)
        
        // 应用列表
        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 50, width: view.bounds.width - 40, height: view.bounds.height - 120))
        scrollView.hasVerticalScroller = true
        view.addSubview(scrollView)
        
        // 添加/移除按钮
        let addButton = NSButton(title: "添加应用", target: self, action: #selector(addApplication))
        addButton.frame = NSRect(x: 20, y: 20, width: 100, height: 25)
        view.addSubview(addButton)
        
        let removeButton = NSButton(title: "移除应用", target: self, action: #selector(removeApplication))
        removeButton.frame = NSRect(x: 130, y: 20, width: 100, height: 25)
        view.addSubview(removeButton)
    }

    // MARK: - Actions
    
    @objc private func addApplication() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["app"]
        
        openPanel.begin { [weak self] response in
            guard response == .OK, let self = self else { return }
            var current = self.preferencesManager.loadCustomApplications()
            for url in openPanel.urls {
                if let info = self.systemIntegration.getApplicationInfo(at: url),
                   !current.contains(info) {
                    current.append(info)
                }
            }
            self.preferencesManager.saveCustomApplications(current)
            NotificationCenter.default.post(name: .preferencesChanged, object: nil)
        }
    }
    
    @objc private func removeApplication() {
        // 简化实现：清空自定义列表
        self.preferencesManager.saveCustomApplications([])
        NotificationCenter.default.post(name: .preferencesChanged, object: nil)
    }
}

// MARK: - 静默模式设置视图控制器

class SilentModeSettingsViewController: NSViewController {
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private let preferencesManager = UserPreferencesManager.shared
    private let silentModeManager = SilentModeManager()
    private var fullscreenCheckbox: NSButton!
    private var gameCheckbox: NSButton!
    
    private func setupUI() {
        let titleLabel = NSTextField(labelWithString: "静默模式设置")
        titleLabel.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.frame = NSRect(x: 20, y: view.bounds.height - 50, width: 200, height: 30)
        view.addSubview(titleLabel)
        
        // 自动检测选项
        fullscreenCheckbox = NSButton(checkboxWithTitle: "自动检测全屏应用", target: self, action: #selector(toggleFullscreenDetect))
        fullscreenCheckbox.frame = NSRect(x: 20, y: view.bounds.height - 90, width: 200, height: 20)
        fullscreenCheckbox.state = preferencesManager.load().autoDetectFullscreen ? .on : .off
        view.addSubview(fullscreenCheckbox)
        
        gameCheckbox = NSButton(checkboxWithTitle: "自动检测游戏应用", target: self, action: #selector(toggleGameDetect))
        gameCheckbox.frame = NSRect(x: 20, y: view.bounds.height - 120, width: 200, height: 20)
        gameCheckbox.state = preferencesManager.load().autoDetectGames ? .on : .off
        view.addSubview(gameCheckbox)
        
        // 静默应用列表
        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 50, width: view.bounds.width - 40, height: view.bounds.height - 200))
        scrollView.hasVerticalScroller = true
        view.addSubview(scrollView)
        
        // 预设按钮
        let presetButton = NSButton(title: "应用常用预设", target: self, action: #selector(applyPresets))
        presetButton.frame = NSRect(x: 20, y: 20, width: 120, height: 25)
        view.addSubview(presetButton)
    }

    // MARK: - Actions
    
    @objc private func toggleFullscreenDetect() {
        let enabled = fullscreenCheckbox.state == .on
        silentModeManager.setAutoDetectFullscreen(enabled)
        NotificationCenter.default.post(name: .preferencesChanged, object: nil)
    }
    
    @objc private func toggleGameDetect() {
        let enabled = gameCheckbox.state == .on
        silentModeManager.setAutoDetectGames(enabled)
        NotificationCenter.default.post(name: .preferencesChanged, object: nil)
    }
    
    @objc private func applyPresets() {
        silentModeManager.applyCommonSilentApplications()
        NotificationCenter.default.post(name: .preferencesChanged, object: nil)
    }
}

// MARK: - 外观设置视图控制器

class AppearanceSettingsViewController: NSViewController {
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        let titleLabel = NSTextField(labelWithString: "外观设置")
        titleLabel.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.frame = NSRect(x: 20, y: view.bounds.height - 50, width: 200, height: 30)
        view.addSubview(titleLabel)
        
        // 启动条设置
        let launchBarCheckbox = NSButton(checkboxWithTitle: "启用启动条", target: nil, action: nil)
        launchBarCheckbox.frame = NSRect(x: 20, y: view.bounds.height - 90, width: 200, height: 20)
        view.addSubview(launchBarCheckbox)
        
        // 位置选择
        let positionLabel = NSTextField(labelWithString: "启动条位置:")
        positionLabel.frame = NSRect(x: 20, y: view.bounds.height - 130, width: 100, height: 20)
        view.addSubview(positionLabel)
        
        let positionPopUp = NSPopUpButton(frame: NSRect(x: 130, y: view.bounds.height - 135, width: 200, height: 25))
        positionPopUp.addItems(withTitles: ["顶部", "底部", "左侧", "右侧"])
        view.addSubview(positionPopUp)
        
        // 透明度滑块
        let opacityLabel = NSTextField(labelWithString: "透明度:")
        opacityLabel.frame = NSRect(x: 20, y: view.bounds.height - 170, width: 100, height: 20)
        view.addSubview(opacityLabel)
        
        let opacitySlider = NSSlider(frame: NSRect(x: 130, y: view.bounds.height - 170, width: 200, height: 20))
        opacitySlider.minValue = 0.0
        opacitySlider.maxValue = 1.0
        opacitySlider.doubleValue = 0.8
        view.addSubview(opacitySlider)
    }
}

// MARK: - 高级设置视图控制器

class AdvancedSettingsViewController: NSViewController {
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        let titleLabel = NSTextField(labelWithString: "高级设置")
        titleLabel.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.frame = NSRect(x: 20, y: view.bounds.height - 50, width: 200, height: 30)
        view.addSubview(titleLabel)
        
        // 使用统计
        let statsCheckbox = NSButton(checkboxWithTitle: "启用使用统计", target: nil, action: nil)
        statsCheckbox.frame = NSRect(x: 20, y: view.bounds.height - 90, width: 200, height: 20)
        statsCheckbox.state = .on
        view.addSubview(statsCheckbox)
        
        // 应用分组
        let groupCheckbox = NSButton(checkboxWithTitle: "启用应用分组", target: nil, action: nil)
        groupCheckbox.frame = NSRect(x: 20, y: view.bounds.height - 120, width: 200, height: 20)
        view.addSubview(groupCheckbox)
        
        // 工作空间
        let workspaceCheckbox = NSButton(checkboxWithTitle: "启用工作空间", target: nil, action: nil)
        workspaceCheckbox.frame = NSRect(x: 20, y: view.bounds.height - 150, width: 200, height: 20)
        view.addSubview(workspaceCheckbox)
        
        // 重置按钮
        let resetButton = NSButton(title: "重置所有设置", target: nil, action: nil)
        resetButton.frame = NSRect(x: 20, y: 20, width: 120, height: 25)
        view.addSubview(resetButton)
    }
}
