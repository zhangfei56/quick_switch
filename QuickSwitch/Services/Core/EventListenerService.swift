import Cocoa
import Carbon
import CoreGraphics

/// 事件监听服务
class EventListenerService {
    
    // MARK: - Properties
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isRunning = false
    
    weak var shortcutEngine: ShortcutEngine?
    
    // MARK: - Initialization
    
    init() {
        setupEventTap()
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Public Methods
    
    /// 启动事件监听
    func start() {
        guard !isRunning else { return }
        
        // 检查辅助功能权限
        guard AccessibilityManager.shared.isAccessibilityEnabled else {
            print("Accessibility permission not granted")
            return
        }
        
        // 创建事件监听
        setupEventTap()
        
        if let eventTap = eventTap {
            runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            if let runLoopSource = runLoopSource {
                CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
                isRunning = true
                print("Event listener service started")
            }
        }
    }
    
    /// 停止事件监听
    func stop() {
        guard isRunning else { return }
        
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }
        
        if let eventTap = eventTap {
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }
        
        isRunning = false
        print("Event listener service stopped")
    }
    
    // MARK: - Private Methods
    
    private func setupEventTap() {
        // 创建事件监听
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                return EventListenerService.eventTapCallback(proxy: proxy, type: type, event: event, refcon: refcon)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
    }
    
    // MARK: - Event Callback
    
    private static let eventTapCallback: CGEventTapCallBack = { (proxy, type, event, refcon) in
        guard let refcon = refcon else {
            return Unmanaged.passUnretained(event)
        }
        
        let service = Unmanaged<EventListenerService>.fromOpaque(refcon).takeUnretainedValue()
        
        // 处理键盘事件
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let modifiers = event.flags
            
            // 检查是否是快捷键
            if service.isShortcutEvent(keyCode: keyCode, modifiers: modifiers) {
                // 阻止事件继续传播
                return nil
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    private func isShortcutEvent(keyCode: Int64, modifiers: CGEventFlags) -> Bool {
        // 检查是否匹配已注册的快捷键
        guard let shortcutEngine = shortcutEngine else { return false }
        
        let eventModifiers = NSEvent.ModifierFlags(rawValue: UInt(modifiers.rawValue))
        
        // 检查是否匹配任何已注册的快捷键
        if shortcutEngine.isShortcutRegistered(keyCode: UInt16(keyCode), modifiers: eventModifiers) {
            // 执行快捷键操作
            DispatchQueue.main.async {
                shortcutEngine.executeShortcut(keyCode: UInt16(keyCode), modifiers: eventModifiers)
            }
            return true
        }
        
        return false
    }
}

// MARK: - 快捷键引擎协议

protocol ShortcutEngineProtocol: AnyObject {
    func isShortcutRegistered(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> Bool
    func executeShortcut(keyCode: UInt16, modifiers: NSEvent.ModifierFlags)
}

// MARK: - 事件监听状态

extension EventListenerService {
    var status: EventListenerStatus {
        return EventListenerStatus(
            isRunning: isRunning,
            hasPermission: AccessibilityManager.shared.isAccessibilityEnabled,
            eventTapActive: eventTap != nil
        )
    }
}

// MARK: - 事件监听状态结构

struct EventListenerStatus {
    let isRunning: Bool
    let hasPermission: Bool
    let eventTapActive: Bool
    
    var isFullyOperational: Bool {
        return isRunning && hasPermission && eventTapActive
    }
}

// MARK: - 错误处理

extension EventListenerService {
    private func handleEventTapError() {
        print("Event tap error occurred")
        
        // 重新创建事件监听
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.setupEventTap()
        }
    }
}

// MARK: - 调试支持

extension EventListenerService {
    func debugInfo() -> [String: Any] {
        return [
            "isRunning": isRunning,
            "hasPermission": AccessibilityManager.shared.isAccessibilityEnabled,
            "eventTapActive": eventTap != nil,
            "runLoopSourceActive": runLoopSource != nil
        ]
    }
}
