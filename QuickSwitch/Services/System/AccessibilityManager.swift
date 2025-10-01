import Cocoa
import ApplicationServices

/// 辅助功能权限管理器
class AccessibilityManager {
    static let shared = AccessibilityManager()
    
    private init() {}
    
    // MARK: - 权限检查
    
    /// 检查是否已授予辅助功能权限
    var isAccessibilityEnabled: Bool {
        return AXIsProcessTrusted()
    }
    
    /// 检查权限状态并返回详细信息
    func checkAccessibilityStatus() -> AccessibilityStatus {
        let isEnabled = isAccessibilityEnabled
        let canPrompt = AXIsProcessTrustedWithOptions(nil)
        
        return AccessibilityStatus(
            isEnabled: isEnabled,
            canPrompt: canPrompt,
            needsPermission: !isEnabled
        )
    }
    
    // MARK: - 权限请求
    
    /// 请求辅助功能权限
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    /// 打开系统偏好设置中的辅助功能页面
    func openAccessibilityPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    // MARK: - 权限监控
    
    /// 开始监控权限状态变化
    func startMonitoringPermissionChanges(completion: @escaping (Bool) -> Void) {
        // 使用定时器检查权限状态变化
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            let currentStatus = self.isAccessibilityEnabled
            completion(currentStatus)
            
            // 如果权限已授予，停止监控
            if currentStatus {
                timer.invalidate()
            }
        }
    }
    
    // MARK: - 权限验证
    
    /// 验证权限并执行操作
    func withAccessibilityPermission<T>(_ operation: () throws -> T) throws -> T {
        guard isAccessibilityEnabled else {
            throw AccessibilityError.permissionDenied
        }
        
        return try operation()
    }
    
    /// 异步验证权限并执行操作
    func withAccessibilityPermissionAsync<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        guard isAccessibilityEnabled else {
            throw AccessibilityError.permissionDenied
        }
        
        return try await operation()
    }
}

// MARK: - 辅助类型

/// 辅助功能状态
struct AccessibilityStatus {
    let isEnabled: Bool
    let canPrompt: Bool
    let needsPermission: Bool
}

/// 辅助功能错误
enum AccessibilityError: Error, LocalizedError {
    case permissionDenied
    case operationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "需要辅助功能权限才能使用此功能"
        case .operationFailed(let message):
            return "操作失败: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "请在系统偏好设置 > 安全性与隐私 > 隐私 > 辅助功能中授予权限"
        case .operationFailed:
            return "请重试或联系技术支持"
        }
    }
}

// MARK: - 权限状态通知

extension Notification.Name {
    static let accessibilityPermissionChanged = Notification.Name("AccessibilityPermissionChanged")
}

// MARK: - 权限状态发布者

import Combine

extension AccessibilityManager {
    /// 权限状态发布者
    var permissionStatusPublisher: AnyPublisher<Bool, Never> {
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .map { [weak self] _ in
                self?.isAccessibilityEnabled ?? false
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
