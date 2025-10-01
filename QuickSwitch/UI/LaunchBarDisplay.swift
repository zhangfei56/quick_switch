import Cocoa
import Combine

/// 启动条显示器
class LaunchBarDisplay: NSObject {
    
    // MARK: - Properties
    
    private var launchBarWindow: NSWindow?
    private var contentView: LaunchBarView?
    private var applications: [ApplicationInfo] = []
    private var isVisible = false
    
    private let preferencesManager = UserPreferencesManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupLaunchBar()
    }
    
    // MARK: - Public Methods
    
    /// 显示启动条
    func showLaunchBar(with applications: [ApplicationInfo]) {
        self.applications = applications
        updateContent()
        
        guard let window = launchBarWindow else { return }
        
        window.orderFrontRegardless()
        window.makeKey()
        isVisible = true
        
        // 自动隐藏定时器
        scheduleAutoHide()
    }
    
    /// 隐藏启动条
    func hideLaunchBar() {
        guard let window = launchBarWindow else { return }
        
        window.orderOut(nil)
        isVisible = false
    }
    
    /// 切换启动条显示状态
    func toggleLaunchBar(with applications: [ApplicationInfo]) {
        if isVisible {
            hideLaunchBar()
        } else {
            showLaunchBar(with: applications)
        }
    }
    
    /// 更新启动条位置
    func updateLaunchBarPosition() {
        guard let window = launchBarWindow,
              let screen = NSScreen.main else { return }
        
        let preferences = preferencesManager.load()
        let position = preferences.launchBarPosition
        let windowSize = window.frame.size
        let screenFrame = screen.visibleFrame
        
        var newOrigin: NSPoint
        
        switch position {
        case .top:
            newOrigin = NSPoint(
                x: (screenFrame.width - windowSize.width) / 2 + screenFrame.origin.x,
                y: screenFrame.maxY - windowSize.height - 20
            )
        case .bottom:
            newOrigin = NSPoint(
                x: (screenFrame.width - windowSize.width) / 2 + screenFrame.origin.x,
                y: screenFrame.origin.y + 20
            )
        case .left:
            newOrigin = NSPoint(
                x: screenFrame.origin.x + 20,
                y: (screenFrame.height - windowSize.height) / 2 + screenFrame.origin.y
            )
        case .right:
            newOrigin = NSPoint(
                x: screenFrame.maxX - windowSize.width - 20,
                y: (screenFrame.height - windowSize.height) / 2 + screenFrame.origin.y
            )
        case .topLeft:
            newOrigin = NSPoint(
                x: screenFrame.origin.x + 20,
                y: screenFrame.maxY - windowSize.height - 20
            )
        case .topRight:
            newOrigin = NSPoint(
                x: screenFrame.maxX - windowSize.width - 20,
                y: screenFrame.maxY - windowSize.height - 20
            )
        case .bottomLeft:
            newOrigin = NSPoint(
                x: screenFrame.origin.x + 20,
                y: screenFrame.origin.y + 20
            )
        case .bottomRight:
            newOrigin = NSPoint(
                x: screenFrame.maxX - windowSize.width - 20,
                y: screenFrame.origin.y + 20
            )
        }
        
        window.setFrameOrigin(newOrigin)
    }
    
    /// 更新启动条外观
    func updateLaunchBarAppearance() {
        let preferences = preferencesManager.load()
        launchBarWindow?.alphaValue = preferences.launchBarOpacity
        contentView?.updateAppearance()
    }
    
    // MARK: - Private Methods
    
    private func setupLaunchBar() {
        let preferences = preferencesManager.load()
        
        // 创建窗口
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 80),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.alphaValue = preferences.launchBarOpacity
        window.isMovableByWindowBackground = false
        
        // 创建内容视图
        let contentView = LaunchBarView(frame: window.contentView!.bounds)
        window.contentView = contentView
        
        self.launchBarWindow = window
        self.contentView = contentView
        
        updateLaunchBarPosition()
    }
    
    private func updateContent() {
        contentView?.setApplications(applications)
    }
    
    private func scheduleAutoHide() {
        // 3秒后自动隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.hideLaunchBar()
        }
    }
}

// MARK: - 启动条视图

class LaunchBarView: NSView {
    
    // MARK: - Properties
    
    private var applications: [ApplicationInfo] = []
    private var appButtons: [NSButton] = []
    private let stackView = NSStackView()
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Public Methods
    
    func setApplications(_ applications: [ApplicationInfo]) {
        self.applications = applications
        updateButtons()
    }
    
    func updateAppearance() {
        // 更新视觉效果
        setupBlurEffect()
    }
    
    // MARK: - Private Methods
    
    private func setupView() {
        wantsLayer = true
        layer?.cornerRadius = 12
        
        // 添加模糊效果
        setupBlurEffect()
        
        // 设置堆叠视图
        stackView.orientation = .horizontal
        stackView.spacing = 12
        stackView.alignment = .centerY
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    private func setupBlurEffect() {
        // 使用 NSVisualEffectView 实现模糊效果
        let blurView = NSVisualEffectView(frame: bounds)
        blurView.material = .hudWindow
        blurView.state = .active
        blurView.blendingMode = .behindWindow
        blurView.wantsLayer = true
        blurView.layer?.cornerRadius = 12
        blurView.autoresizingMask = [.width, .height]
        
        addSubview(blurView, positioned: .below, relativeTo: stackView)
    }
    
    private func updateButtons() {
        // 移除现有按钮
        appButtons.forEach { $0.removeFromSuperview() }
        appButtons.removeAll()
        
        // 创建新按钮
        for (index, app) in applications.prefix(9).enumerated() {
            let button = createAppButton(for: app, index: index)
            stackView.addArrangedSubview(button)
            appButtons.append(button)
        }
    }
    
    private func createAppButton(for app: ApplicationInfo, index: Int) -> NSButton {
        let button = NSButton(frame: NSRect(x: 0, y: 0, width: 60, height: 60))
        button.bezelStyle = .regularSquare
        button.isBordered = false
        button.image = app.icon
        button.imageScaling = .scaleProportionallyDown
        button.toolTip = "\(index + 1). \(app.displayName)"
        button.tag = index
        
        // 添加数字标签
        let numberLabel = NSTextField(labelWithString: "\(index + 1)")
        numberLabel.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        numberLabel.textColor = .white
        numberLabel.backgroundColor = NSColor.black.withAlphaComponent(0.6)
        numberLabel.alignment = .center
        numberLabel.frame = NSRect(x: 0, y: 0, width: 20, height: 16)
        numberLabel.wantsLayer = true
        numberLabel.layer?.cornerRadius = 8
        
        button.addSubview(numberLabel)
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            numberLabel.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -4),
            numberLabel.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            numberLabel.widthAnchor.constraint(equalToConstant: 20),
            numberLabel.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        return button
    }
}

// MARK: - 启动条动画

extension LaunchBarDisplay {
    
    /// 显示动画
    func showWithAnimation() {
        guard let window = launchBarWindow else { return }
        
        window.alphaValue = 0.0
        window.orderFrontRegardless()
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = preferencesManager.load().launchBarOpacity
        }
        
        isVisible = true
        scheduleAutoHide()
    }
    
    /// 隐藏动画
    func hideWithAnimation() {
        guard let window = launchBarWindow else { return }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0.0
        }, completionHandler: {
            window.orderOut(nil)
            self.isVisible = false
        })
    }
}

// MARK: - 启动条交互

extension LaunchBarDisplay {
    
    /// 处理鼠标进入事件
    func handleMouseEntered() {
        // 取消自动隐藏
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    /// 处理鼠标离开事件
    func handleMouseExited() {
        // 重新启动自动隐藏
        scheduleAutoHide()
    }
}

// MARK: - 启动条配置

extension LaunchBarDisplay {
    
    /// 配置启动条
    struct LaunchBarConfiguration {
        var position: LaunchBarPosition
        var opacity: Double
        var autoHideDelay: TimeInterval
        var showNumbers: Bool
        var iconSize: CGFloat
        
        static var `default`: LaunchBarConfiguration {
            return LaunchBarConfiguration(
                position: .bottom,
                opacity: 0.8,
                autoHideDelay: 3.0,
                showNumbers: true,
                iconSize: 48.0
            )
        }
    }
    
    /// 应用配置
    func applyConfiguration(_ configuration: LaunchBarConfiguration) {
        guard let window = launchBarWindow else { return }
        
        window.alphaValue = configuration.opacity
        updateLaunchBarPosition()
    }
}
