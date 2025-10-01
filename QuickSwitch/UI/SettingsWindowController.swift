import Cocoa

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
        
        let modePopUp = NSPopUpButton(frame: NSRect(x: 130, y: view.bounds.height - 105, width: 200, height: 25))
        modePopUp.addItems(withTitles: ["Dock 模式", "切换器模式", "自定义模式"])
        view.addSubview(modePopUp)
        
        // 修饰键选择
        let modifierLabel = NSTextField(labelWithString: "修饰键:")
        modifierLabel.frame = NSRect(x: 20, y: view.bounds.height - 140, width: 100, height: 20)
        view.addSubview(modifierLabel)
        
        let modifierPopUp = NSPopUpButton(frame: NSRect(x: 130, y: view.bounds.height - 145, width: 200, height: 25))
        modifierPopUp.addItems(withTitles: ["Option", "Control", "Command", "Shift"])
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
}

// MARK: - 快捷键设置视图控制器

class ShortcutsSettingsViewController: NSViewController {
    
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
        let addButton = NSButton(title: "添加应用", target: nil, action: nil)
        addButton.frame = NSRect(x: 20, y: 20, width: 100, height: 25)
        view.addSubview(addButton)
        
        let removeButton = NSButton(title: "移除应用", target: nil, action: nil)
        removeButton.frame = NSRect(x: 130, y: 20, width: 100, height: 25)
        view.addSubview(removeButton)
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
    
    private func setupUI() {
        let titleLabel = NSTextField(labelWithString: "静默模式设置")
        titleLabel.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.frame = NSRect(x: 20, y: view.bounds.height - 50, width: 200, height: 30)
        view.addSubview(titleLabel)
        
        // 自动检测选项
        let fullscreenCheckbox = NSButton(checkboxWithTitle: "自动检测全屏应用", target: nil, action: nil)
        fullscreenCheckbox.frame = NSRect(x: 20, y: view.bounds.height - 90, width: 200, height: 20)
        fullscreenCheckbox.state = .on
        view.addSubview(fullscreenCheckbox)
        
        let gameCheckbox = NSButton(checkboxWithTitle: "自动检测游戏应用", target: nil, action: nil)
        gameCheckbox.frame = NSRect(x: 20, y: view.bounds.height - 120, width: 200, height: 20)
        gameCheckbox.state = .on
        view.addSubview(gameCheckbox)
        
        // 静默应用列表
        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 50, width: view.bounds.width - 40, height: view.bounds.height - 200))
        scrollView.hasVerticalScroller = true
        view.addSubview(scrollView)
        
        // 预设按钮
        let presetButton = NSButton(title: "应用常用预设", target: nil, action: nil)
        presetButton.frame = NSRect(x: 20, y: 20, width: 120, height: 25)
        view.addSubview(presetButton)
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
