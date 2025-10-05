import SwiftUI
import Cocoa
import ApplicationServices

/// QuickSwitch 应用入口 - 使用 SwiftUI MenuBarExtra
@main
struct QuickSwitchApp: App {
    
    // MARK: - App Delegate
    
    @NSApplicationDelegateAdaptor(AppCoordinator.self) var appDelegate
    
    // MARK: - Body
    
    var body: some Scene {
        // 菜单栏图标
        MenuBarExtra("QuickSwitch", systemImage: "app.dashed") {
            MenuBarContentView(
                applicationManager: appDelegate.applicationManager,
                onShowSettings: {
                    appDelegate.showSettings()
                },
                onQuit: {
                    appDelegate.quitApplication()
                }
            )
        }
        .menuBarExtraStyle(.window)
        
        // 设置窗口（通过快捷键打开）
        Window("设置", id: "settings") {
            SettingsView()
                .environment(appDelegate.preferencesManager)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .commandsRemoved()
    }
}

// MARK: - App Coordinator (Application Delegate)

class AppCoordinator: NSObject, NSApplicationDelegate {
    
    // MARK: - Properties
    
    let applicationManager = ApplicationManager()
    let preferencesManager = UserPreferencesManager.shared
    
    private var launchBarManager: LaunchBarWindowManager?
    private var eventMonitor: GlobalEventMonitor?
    
    private var currentViewMode: ViewMode = .bound
    private var selectedIndex: Int = 0
    private var isLaunchBarVisible: Bool = false
    private var lastTabPressTime: TimeInterval = 0
    private var lastTriggerPressTime: TimeInterval = 0
    
    // MARK: - Application Lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupApplication()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        eventMonitor?.stop()
        applicationManager.stop()
        print("⏹️ QuickSwitch 已停止")
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - Setup
    
    /// 清理可能损坏的数据
    private func cleanupCorruptedData() {
        print("🧹 启动时清理可能损坏的数据...")
        
        let userDefaults = UserDefaults.standard
        let preferencesKey = "QuickSwitchUserPreferences"
        
        // 检查数据是否存在且可能损坏
        if let data = userDefaults.data(forKey: preferencesKey) {
            // 尝试解码数据，如果失败则清理
            do {
                let _ = try JSONDecoder().decode(UserPreferences.self, from: data)
                print("✅ 用户偏好数据正常")
            } catch {
                print("⚠️ 检测到损坏的用户偏好数据，正在清理...")
                userDefaults.removeObject(forKey: preferencesKey)
                userDefaults.synchronize()
                print("✅ 损坏数据已清理")
            }
        }
        
        // 清理其他可能的问题数据
        let allKeys = userDefaults.dictionaryRepresentation().keys
        for key in allKeys {
            if key.lowercased().contains("quickswitch") {
                if let data = userDefaults.data(forKey: key) {
                    // 检查数据大小
                    if data.count > 1024 * 1024 { // 大于 1MB
                        print("⚠️ 发现过大的数据键: \(key) (\(data.count) bytes)，正在清理...")
                        userDefaults.removeObject(forKey: key)
                    }
                }
            }
        }
        
        userDefaults.synchronize()
        print("✅ 数据清理完成")
    }
    
    /// 检查辅助功能权限
    private func checkAccessibilityPermissions() {
        let trusted = AXIsProcessTrusted()
        if trusted {
            print("✅ 辅助功能权限已授予")
        } else {
            print("⚠️ 需要辅助功能权限才能使用全局快捷键和获取窗口数量")
            print("💡 请在系统偏好设置 > 安全性与隐私 > 隐私 > 辅助功能中启用 QuickSwitch")
            print("💡 或者点击菜单栏图标 > 设置 > 权限设置")
            
            // 请求权限
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
            AXIsProcessTrustedWithOptions(options as CFDictionary)
            
            // 延迟检查权限状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let newTrusted = AXIsProcessTrusted()
                if newTrusted {
                    print("✅ 辅助功能权限已授予，功能已启用")
                } else {
                    print("⚠️ 辅助功能权限未授予，部分功能可能受限")
                    print("💡 窗口数量显示将使用简化模式")
                }
            }
        }
    }
    
    private func setupApplication() {
        // 设置为辅助应用（不显示在 Dock），但保持全局事件监听能力
        NSApp.setActivationPolicy(.accessory)
        
        // 启动时清理可能损坏的数据
        cleanupCorruptedData()
        
        // 检查辅助功能权限
        checkAccessibilityPermissions()
        
        // 检查并诊断 UserDefaults 数据大小
        preferencesManager.diagnoseDataSize()
        
        // 启动应用管理器
        applicationManager.start()
        
        // 初始化启动条管理器
        launchBarManager = LaunchBarWindowManager(preferencesManager: preferencesManager, applicationManager: applicationManager)
        
        // 初始化全局事件监听器
        let monitor = GlobalEventMonitor(triggerModifier: preferencesManager.triggerModifier)
        
        monitor.onTriggerKeyPressed = { [weak self] in
            self?.showLaunchBar()
        }
        
        monitor.onTriggerKeyReleased = { [weak self] in
            self?.hideLaunchBar()
        }
        
        monitor.onTabKeyPressed = { [weak self] in
            self?.switchView()
        }
        
        monitor.onShortcutKeyPressed = { [weak self] keyCode in
            self?.handleShortcutKey(keyCode)
        }
        
        monitor.onLeftArrowPressed = { [weak self] in
            self?.moveSelectionLeft()
        }
        
        monitor.onRightArrowPressed = { [weak self] in
            self?.moveSelectionRight()
        }
        
        monitor.onEscapeKeyPressed = { [weak self] in
            self?.cancelLaunchBar()
        }
        
        monitor.onSettingsKeyPressed = { [weak self] in
            self?.showSettings()
        }
        
        monitor.onQuitKeyPressed = { [weak self] in
            self?.quitApplication()
        }
        
        monitor.start()
        eventMonitor = monitor
        
        print("✅ QuickSwitch 已启动")
        print("💡 按住 \(preferencesManager.triggerModifier.displayName) 键显示启动条")
        print("💡 按 Tab 键在绑定应用和运行应用之间切换")
        print("💡 按左右箭头键导航应用")
        print("💡 按 ESC 键取消启动条")
        print("💡 点击应用图标选择应用")
        print("💡 按 Command+逗号 打开设置")
        print("💡 按 Command+Q 退出应用")
    }
    
    // MARK: - Launch Bar Management
    
    private func showLaunchBar() {
        guard let manager = launchBarManager else { return }
        
        // 防抖机制：避免快速重复显示启动条
        let currentTime = Date().timeIntervalSince1970
        if currentTime - lastTriggerPressTime < 0.1 { // 100ms 防抖
            return
        }
        lastTriggerPressTime = currentTime
        
        isLaunchBarVisible = true
        
        // 启动键盘事件监听
        eventMonitor?.startKeyboardMonitoring()
        
        switch currentViewMode {
        case .bound:
            manager.showBoundView(selectedIndex: selectedIndex) { [weak self] app in
                self?.selectApplication(app)
            }
        case .running:
            manager.showRunningView(selectedIndex: selectedIndex) { [weak self] app in
                self?.selectApplication(app)
            }
        }
    }
    
    private func hideLaunchBar() {
        // 停止键盘事件监听
        eventMonitor?.stopKeyboardMonitoring()
        
        // 先隐藏启动条，避免在应用切换过程中触发新事件
        launchBarManager?.hide()
        
        // 如果启动条可见，自动选择当前选中的应用
        if isLaunchBarVisible {
            selectCurrentApplication()
        }
        
        selectedIndex = 0
        currentViewMode = .bound
        isLaunchBarVisible = false
    }
    
    private func cancelLaunchBar() {
        print("❌ 取消启动条")
        // 停止键盘事件监听
        eventMonitor?.stopKeyboardMonitoring()
        
        // 隐藏启动条，不执行任何操作
        launchBarManager?.hide()
        
        selectedIndex = 0
        currentViewMode = .bound
        isLaunchBarVisible = false
    }
    
    private func switchView() {
        print("🔄 switchView() 被调用")
        
        // 防抖机制：避免快速连续按 Tab 键
        let currentTime = Date().timeIntervalSince1970
        if currentTime - lastTabPressTime < 0.2 { // 200ms 防抖
            print("⚠️ Tab 键防抖，忽略此次调用")
            return
        }
        lastTabPressTime = currentTime
        
        let oldMode = currentViewMode
        currentViewMode = currentViewMode == .bound ? .running : .bound
        print("🔄 视图切换: \(oldMode) -> \(currentViewMode)")
        
        // 重置选中索引，避免索引超出范围
        selectedIndex = 0
        
        // 使用轻量级更新，保持窗口位置不变
        if currentViewMode == .bound {
            launchBarManager?.showBoundView(selectedIndex: selectedIndex) { [weak self] app in
                self?.selectApplication(app)
            }
        } else {
            launchBarManager?.showRunningView(selectedIndex: selectedIndex) { [weak self] app in
                self?.selectApplication(app)
            }
        }
    }
    
    private func selectApplication(_ app: ApplicationInfo) {
        applicationManager.switchToApplication(app)
        // 停止键盘事件监听
        eventMonitor?.stopKeyboardMonitoring()
        // 直接清理状态，不调用 hideLaunchBar() 避免循环
        launchBarManager?.hide()
        selectedIndex = 0
        currentViewMode = .bound
        isLaunchBarVisible = false
    }
    
    private func handleShortcutKey(_ keyCode: UInt16) {
        // 数字键 1-9 对应 keyCode 18-26
        if keyCode >= 18 && keyCode <= 26 {
            let index = Int(keyCode - 18)  // 数字键1对应索引0，数字键2对应索引1，以此类推
            let keyNumber = index + 1  // 显示的数字
            print("🔢 按数字键 \(keyNumber) (keyCode: \(keyCode)) -> 选中索引: \(index)")
            print("🔍 调试信息: keyCode=\(keyCode), index=\(index), keyNumber=\(keyNumber)")
            selectedIndex = index
            if isLaunchBarVisible {
                // 使用轻量级更新，避免重新创建窗口
                launchBarManager?.updateSelectedIndex(selectedIndex) { [weak self] app in
                    self?.selectApplication(app)
                }
            }
        }
        // 处理其他可能的数字键 keyCode
        else if keyCode == 7 {  // 数字键 6 的 keyCode 可能是 7
            let index = 5  // 数字键6对应索引5
            print("🔢 按数字键 6 (keyCode: \(keyCode)) -> 选中索引: \(index)")
            selectedIndex = index
            if isLaunchBarVisible {
                launchBarManager?.updateSelectedIndex(selectedIndex) { [weak self] app in
                    self?.selectApplication(app)
                }
            }
        }
        // 字母键 A-Z 对应 keyCode 0-25 (A=0, B=1, ..., Z=25)
        // 但我们需要将它们映射到索引 9-34 (因为前9个是数字键)
        else if keyCode >= 0 && keyCode <= 25 {
            let index = Int(keyCode) + 9 // 字母键从索引9开始
            let letter = Character(UnicodeScalar(65 + Int(keyCode))!) // A=65
            print("🔤 按字母键 \(letter) (keyCode: \(keyCode)) -> 选中索引: \(index)")
            selectedIndex = index
            if isLaunchBarVisible {
                // 使用轻量级更新，避免重新创建窗口
                launchBarManager?.updateSelectedIndex(selectedIndex) { [weak self] app in
                    self?.selectApplication(app)
                }
            }
        }
        // 功能键 F1-F12 对应 keyCode 96-107
        // 但我们需要将它们映射到索引 35-46 (因为前35个是数字键和字母键)
        else if keyCode >= 96 && keyCode <= 107 {
            let index = Int(keyCode - 96) + 35 // 功能键从索引35开始
            let functionNumber = Int(keyCode - 96) + 1
            print("⚙️ 按功能键 F\(functionNumber) (keyCode: \(keyCode)) -> 选中索引: \(index)")
            selectedIndex = index
            if isLaunchBarVisible {
                // 使用轻量级更新，避免重新创建窗口
                launchBarManager?.updateSelectedIndex(selectedIndex) { [weak self] app in
                    self?.selectApplication(app)
                }
            }
        }
        // 调试：捕获所有未处理的 keyCode
        else {
            print("❓ 未处理的 keyCode: \(keyCode)")
        }
    }
    
    private func moveSelectionLeft() {
        print("⬅️ moveSelectionLeft() 被调用")
        guard isLaunchBarVisible else { 
            print("⚠️ 启动条未显示，忽略左箭头")
            return 
        }
        
        let currentApplications = getCurrentApplications()
        guard !currentApplications.isEmpty else { 
            print("⚠️ 没有应用可导航")
            return 
        }
        
        let oldIndex = selectedIndex
        selectedIndex = (selectedIndex - 1 + currentApplications.count) % currentApplications.count
        print("⬅️ 选中索引: \(oldIndex) -> \(selectedIndex)")
        
        // 使用轻量级更新，避免重新创建窗口
        launchBarManager?.updateSelectedIndex(selectedIndex) { [weak self] app in
            self?.selectApplication(app)
        }
    }
    
    private func moveSelectionRight() {
        print("➡️ moveSelectionRight() 被调用")
        guard isLaunchBarVisible else { 
            print("⚠️ 启动条未显示，忽略右箭头")
            return 
        }
        
        let currentApplications = getCurrentApplications()
        guard !currentApplications.isEmpty else { 
            print("⚠️ 没有应用可导航")
            return 
        }
        
        let oldIndex = selectedIndex
        selectedIndex = (selectedIndex + 1) % currentApplications.count
        print("➡️ 选中索引: \(oldIndex) -> \(selectedIndex)")
        
        // 使用轻量级更新，避免重新创建窗口
        launchBarManager?.updateSelectedIndex(selectedIndex) { [weak self] app in
            self?.selectApplication(app)
        }
    }
    
    private func selectCurrentApplication() {
        let currentApplications = getCurrentApplications()
        guard selectedIndex >= 0 && selectedIndex < currentApplications.count else { return }
        
        let selectedApp = currentApplications[selectedIndex]
        selectApplication(selectedApp)
    }
    
    private func getCurrentApplications() -> [ApplicationInfo] {
        switch currentViewMode {
        case .bound:
            return applicationManager.getBoundApplications()
        case .running:
            return applicationManager.runningApplications
        }
    }
    
    // MARK: - Public Actions
    
    func showSettings() {
        print("🔧 显示设置窗口")
        
        // 激活应用
        NSApp.activate(ignoringOtherApps: true)
        
        // 尝试激活已存在的设置窗口
        for window in NSApp.windows {
            if window.title == "设置" {
                print("🔧 找到现有设置窗口，激活它")
                window.makeKeyAndOrderFront(nil)
                return
            }
        }
        
        print("🔧 创建新的设置窗口")
        
        // 如果没有找到设置窗口，创建一个新的
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        settingsWindow.title = "设置"
        settingsWindow.center()
        settingsWindow.setFrameAutosaveName("SettingsWindow")
        
        // 创建 SwiftUI 视图
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        settingsWindow.contentViewController = hostingController
        
        // 显示窗口
        settingsWindow.makeKeyAndOrderFront(nil)
        
        print("🔧 设置窗口已显示")
    }
    
    func quitApplication() {
        NSApp.terminate(nil)
    }
}

// MARK: - View Mode

enum ViewMode {
    case bound      // 绑定视图
    case running    // 运行视图
}

// MARK: - Menu Bar Content View

struct MenuBarContentView: View {
    
    let applicationManager: ApplicationManager
    let onShowSettings: () -> Void
    let onQuit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题
            VStack(alignment: .leading, spacing: 4) {
                Text("QuickSwitch")
                    .font(.headline)
                
                Text("快速应用切换工具")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            // 运行中的应用
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    Text("运行中的应用 (\(applicationManager.runningApplications.count))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                    
                    ForEach(applicationManager.runningApplications.prefix(5)) { app in
                        Button(action: {
                            applicationManager.switchToApplication(app)
                        }) {
                            HStack(spacing: 8) {
                                if let icon = app.icon {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                } else {
                                    Image(systemName: "app")
                                        .frame(width: 16, height: 16)
                                }
                                
                                Text(app.displayName)
                                    .font(.body)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if applicationManager.runningApplications.count > 5 {
                        Text("还有 \(applicationManager.runningApplications.count - 5) 个应用...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 8)
                    }
                }
            }
            .frame(maxHeight: 200)
            
            Divider()
            
            // 设置和退出
            VStack(spacing: 0) {
                Button(action: onShowSettings) {
                    HStack {
                        Image(systemName: "gear")
                        Text("设置")
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                
                Button(action: onQuit) {
                    HStack {
                        Image(systemName: "power")
                        Text("退出")
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 280)
    }
}

// MARK: - NSEvent.ModifierFlags Extension

extension NSEvent.ModifierFlags: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
    
    var displayName: String {
        switch self {
        case .option:
            return "Option"
        case .control:
            return "Control"
        case .command:
            return "Command"
        case .shift:
            return "Shift"
        default:
            return "Unknown"
        }
    }
}

