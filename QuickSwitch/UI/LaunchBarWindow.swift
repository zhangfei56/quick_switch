import Cocoa
import SwiftUI

// MARK: - Custom Window Class

class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return false
    }
}

/// 启动条窗口管理器 - AppKit 桥接层
/// 
/// 职责：管理浮动窗口的创建、显示、隐藏
/// 使用 NSHostingController 桥接 SwiftUI 视图
class LaunchBarWindowManager {
    
    // MARK: - Properties
    
    private var window: NSWindow?
    private var hostingController: NSHostingController<LaunchBarContentView>?
    
    private let applicationManager: ApplicationManager
    private let preferencesManager = UserPreferencesManager.shared
    
    // 跟踪当前视图模式
    private var currentViewMode: ViewMode = .bound
    
    var isVisible: Bool {
        return window?.isVisible ?? false
    }
    
    // MARK: - Initialization
    
    init(preferencesManager: UserPreferencesManager, applicationManager: ApplicationManager) {
        self.applicationManager = applicationManager
        // preferencesManager 已经在类中定义为 shared 实例
    }
    
    // MARK: - Public Methods
    
    /// 显示启动条（绑定视图）
    func showBoundView(selectedIndex: Int = 0, onSelectApplication: @escaping (ApplicationInfo) -> Void) {
        currentViewMode = .bound
        let boundApplications = applicationManager.getBoundApplications()
        
        // 如果没有绑定的应用，显示运行中的应用
        if boundApplications.isEmpty {
            print("📱 没有绑定的应用，显示运行中的应用")
            showRunningView(selectedIndex: selectedIndex, onSelectApplication: onSelectApplication)
        } else {
            show(applications: boundApplications, selectedIndex: selectedIndex, onSelectApplication: onSelectApplication)
        }
    }
    
    /// 显示启动条（运行视图）
    func showRunningView(selectedIndex: Int = 0, onSelectApplication: @escaping (ApplicationInfo) -> Void) {
        currentViewMode = .running
        let applications = applicationManager.runningApplications
        show(applications: applications, selectedIndex: selectedIndex, onSelectApplication: onSelectApplication)
    }
    
    /// 隐藏启动条
    func hide() {
        window?.orderOut(nil)
        window = nil
        hostingController = nil
    }
    
    /// 更新选中的索引（轻量级更新，不重新创建窗口）
    func updateSelectedIndex(_ index: Int, onSelectApplication: @escaping (ApplicationInfo) -> Void) {
        // 如果窗口已存在，只更新内容而不重新创建窗口
        if let hostingController = hostingController {
            let currentApplications = getCurrentApplications()
            guard !currentApplications.isEmpty else { 
                print("⚠️ 没有应用可显示")
                return 
            }
            
            // 检查索引是否有效
            guard index >= 0 && index < currentApplications.count else {
                print("⚠️ 索引超出范围: \(index), 应用数量: \(currentApplications.count)")
                return
            }
            
            let contentView = LaunchBarContentView(
                applications: currentApplications,
                selectedIndex: index,
                showWindowCount: preferencesManager.showWindowCount,
                onSelectApplication: onSelectApplication
            )
            
            hostingController.rootView = contentView
            print("🔄 更新选中索引: \(index), 应用: \(currentApplications[index].displayName)")
        }
    }
    
    private func getCurrentApplications() -> [ApplicationInfo] {
        switch currentViewMode {
        case .bound:
            let boundApplications = applicationManager.getBoundApplications()
            // 如果没有绑定的应用，返回运行中的应用
            return boundApplications.isEmpty ? applicationManager.runningApplications : boundApplications
        case .running:
            return applicationManager.runningApplications
        }
    }
    
    // MARK: - Private Methods
    
    private func show(applications: [ApplicationInfo], selectedIndex: Int, onSelectApplication: @escaping (ApplicationInfo) -> Void) {
        guard !applications.isEmpty else {
            print("⚠️ 没有可显示的应用")
            return
        }
        
        // 如果窗口已存在，直接更新内容而不是重新创建
        if let existingWindow = window, let existingController = hostingController {
            // 创建新的 SwiftUI 视图
            let contentView = LaunchBarContentView(
                applications: applications,
                selectedIndex: selectedIndex,
                showWindowCount: preferencesManager.showWindowCount,
                onSelectApplication: onSelectApplication
            )
            
            // 更新现有控制器的根视图
            existingController.rootView = contentView
            
            // 重新计算窗口大小和位置
            let newFrame = calculateWindowFrame(for: applications.count)
            existingWindow.setFrame(newFrame, display: true, animate: true)
            
            // 确保窗口重新获得焦点
            NSApp.activate(ignoringOtherApps: true)
            existingWindow.makeKeyAndOrderFront(nil)
            existingWindow.makeFirstResponder(existingWindow.contentView)
            
            print("✅ 启动条已更新，共 \(applications.count) 个应用")
            print("🔑 窗口是否为关键窗口: \(existingWindow.isKeyWindow)")
            print("🎯 应用是否已激活: \(NSApp.isActive)")
            return
        }
        
        // 如果窗口不存在，创建新窗口
        // 创建 SwiftUI 视图
        let contentView = LaunchBarContentView(
            applications: applications,
            selectedIndex: selectedIndex,
            showWindowCount: preferencesManager.showWindowCount,
            onSelectApplication: onSelectApplication
        )
        
        // 创建 Hosting Controller
        hostingController = NSHostingController(rootView: contentView)
        
        // 计算窗口大小和位置
        let windowFrame = calculateWindowFrame(for: applications.count)
        
        // 创建自定义窗口
        let newWindow = KeyableWindow(
            contentRect: windowFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // 配置窗口
        newWindow.contentViewController = hostingController
        newWindow.backgroundColor = .clear
        newWindow.isOpaque = false
        newWindow.hasShadow = true
        newWindow.level = .floating
        newWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        newWindow.isMovableByWindowBackground = false
        newWindow.acceptsMouseMovedEvents = false  // 不接收鼠标移动事件
        
        // 激活应用以确保能接收键盘事件
        NSApp.activate(ignoringOtherApps: true)
        
        // 显示窗口并使其成为关键窗口
        newWindow.makeKeyAndOrderFront(nil)
        
        // 确保窗口成为第一响应者
        newWindow.makeFirstResponder(newWindow.contentView)
        
        // 添加动画效果
        newWindow.animator().alphaValue = 1.0
        
        window = newWindow
        
        print("✅ 启动条已显示，共 \(applications.count) 个应用")
        print("🔑 窗口是否为关键窗口: \(newWindow.isKeyWindow)")
        print("🎯 应用是否已激活: \(NSApp.isActive)")
    }
    
    private func calculateWindowFrame(for applicationCount: Int) -> NSRect {
        let itemWidth: CGFloat = 80
        let itemSpacing: CGFloat = 10
        let padding: CGFloat = 20
        let itemHeight: CGFloat = 100
        
        let width = CGFloat(applicationCount) * itemWidth + CGFloat(max(0, applicationCount - 1)) * itemSpacing + padding
        let height = itemHeight + padding
        
        // 获取屏幕尺寸
        guard let screen = NSScreen.main else {
            return NSRect(x: 0, y: 0, width: width, height: height)
        }
        
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - width / 2
        let y = screenFrame.midY - height / 2
        
        return NSRect(x: x, y: y, width: width, height: height)
    }
}

// MARK: - 全局事件监听器

/// 全局键盘事件监听器 - 封装 NSEvent API
class GlobalEventMonitor {
    
    // MARK: - Properties
    
    private var globalFlagsChangedMonitor: Any?
    private var globalKeyDownMonitor: Any?
    private var localFlagsChangedMonitor: Any?
    private var localKeyDownMonitor: Any?
    
    private let triggerModifier: NSEvent.ModifierFlags
    private var isTriggerKeyPressed = false
    
    var onTriggerKeyPressed: (() -> Void)?
    var onTriggerKeyReleased: (() -> Void)?
    var onTabKeyPressed: (() -> Void)?
    var onShortcutKeyPressed: ((UInt16) -> Void)?
    var onLeftArrowPressed: (() -> Void)?
    var onRightArrowPressed: (() -> Void)?
    var onEscapeKeyPressed: (() -> Void)?
    var onSettingsKeyPressed: (() -> Void)?
    var onQuitKeyPressed: (() -> Void)?
    
    // MARK: - Initialization
    
    init(triggerModifier: NSEvent.ModifierFlags = .option) {
        self.triggerModifier = triggerModifier
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Public Methods
    
    /// 开始监听（只监听修饰键用于检测触发键）
    func start() {
        print("🔧 正在启动修饰键监听器...")
        
        // 只监听修饰键变化（用于检测 Option 键按下和松开）
        globalFlagsChangedMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            print("🌍 全局 flagsChanged 事件: \(event.modifierFlags)")
            self?.handleFlagsChanged(event)
        }
        
        localFlagsChangedMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            print("🏠 本地 flagsChanged 事件: \(event.modifierFlags)")
            self?.handleFlagsChanged(event)
            return event
        }
        
        print("✅ 修饰键监听已启动")
    }
    
    /// 启动键盘事件监听（只在启动条显示时调用）
    func startKeyboardMonitoring() {
        guard globalKeyDownMonitor == nil && localKeyDownMonitor == nil else {
            print("⚠️ 键盘监听已经在运行")
            return
        }
        
        print("🔧 正在启动键盘事件监听...")
        
        // 监听键盘按键事件
        globalKeyDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            print("🌍 全局 keyDown 事件: keyCode=\(event.keyCode)")
            self?.handleKeyDown(event)
        }
        
        localKeyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            print("🏠 本地 keyDown 事件: keyCode=\(event.keyCode)")
            self?.handleKeyDown(event)
            return event
        }
        
        print("✅ 键盘事件监听已启动")
    }
    
    /// 停止键盘事件监听（在启动条隐藏时调用）
    func stopKeyboardMonitoring() {
        print("🔧 正在停止键盘事件监听...")
        
        if let monitor = globalKeyDownMonitor {
            NSEvent.removeMonitor(monitor)
            globalKeyDownMonitor = nil
        }
        
        if let monitor = localKeyDownMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyDownMonitor = nil
        }
        
        print("✅ 键盘事件监听已停止")
    }
    
    /// 停止监听
    func stop() {
        // 清理全局监听器
        if let monitor = globalFlagsChangedMonitor {
            NSEvent.removeMonitor(monitor)
            globalFlagsChangedMonitor = nil
        }
        
        if let monitor = globalKeyDownMonitor {
            NSEvent.removeMonitor(monitor)
            globalKeyDownMonitor = nil
        }
        
        // 清理本地监听器
        if let monitor = localFlagsChangedMonitor {
            NSEvent.removeMonitor(monitor)
            localFlagsChangedMonitor = nil
        }
        
        if let monitor = localKeyDownMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyDownMonitor = nil
        }
        
        print("⏹️ 全局事件监听已停止")
    }
    
    // MARK: - Private Methods
    
    private func handleFlagsChanged(_ event: NSEvent) {
        let wasPressedBefore = isTriggerKeyPressed
        isTriggerKeyPressed = event.modifierFlags.contains(triggerModifier)
        
        if isTriggerKeyPressed && !wasPressedBefore {
            // 触发键被按下
            onTriggerKeyPressed?()
        } else if !isTriggerKeyPressed && wasPressedBefore {
            // 触发键被松开
            onTriggerKeyReleased?()
        }
    }
    
    private func handleKeyDown(_ event: NSEvent) {
        print("🔍 键盘事件: keyCode=\(event.keyCode), modifiers=\(event.modifierFlags)")
        
        // 检查 Command+逗号 (设置快捷键)
        if event.modifierFlags.contains(.command) && event.keyCode == 43 { // 逗号键
            print("⚙️ 检测到设置快捷键")
            onSettingsKeyPressed?()
            return
        }
        
        // 检查 Command+Q (退出快捷键)
        if event.modifierFlags.contains(.command) && event.keyCode == 12 { // Q键
            print("🚪 检测到退出快捷键")
            onQuitKeyPressed?()
            return
        }
        
        // ESC 键 - 取消启动条
        if event.keyCode == 53 { // ESC 键
            print("❌ 检测到 ESC 键，取消启动条")
            onEscapeKeyPressed?()
            return
        }
        
        // Tab 键 - 在启动条显示时始终可用
        if event.keyCode == 48 {
            print("🔄 检测到 Tab 键")
            onTabKeyPressed?()
            return
        }
        
        // 左右箭头键 - 在启动条显示时始终可用
        if event.keyCode == 123 { // 左箭头
            print("⬅️ 检测到左箭头键")
            onLeftArrowPressed?()
            return
        }
        
        if event.keyCode == 124 { // 右箭头
            print("➡️ 检测到右箭头键")
            onRightArrowPressed?()
            return
        }
        
        // 只有在触发键按下时才处理其他快捷键
        guard isTriggerKeyPressed else { 
            print("⚠️ 触发键未按下，忽略其他快捷键")
            return 
        }
        
        // 其他快捷键
        print("🎯 检测到其他快捷键: keyCode=\(event.keyCode)")
        onShortcutKeyPressed?(event.keyCode)
    }
}

