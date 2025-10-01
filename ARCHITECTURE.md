# Quick Switch - 系统架构设计文档

## 架构概述

Quick Switch 采用模块化架构设计，基于 macOS 原生框架构建，确保高性能和系统集成度。整体架构分为六个核心层次，从底层到顶层依次为：系统接口层、核心服务层、业务逻辑层、数据管理层、用户界面层和配置管理层。

## 系统架构图

```
┌─────────────────────────────────────────────────────────────┐
│                    用户界面层 (UI Layer)                      │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────┐ │
│  │ 状态栏菜单   │ │ 设置窗口     │ │ 启动条显示   │ │ 统计界面 │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────┘ │
├─────────────────────────────────────────────────────────────┤
│                    配置管理层 (Config Layer)                  │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────┐ │
│  │ 快捷键配置   │ │ 应用配置     │ │ 界面配置     │ │ 用户偏好 │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────┘ │
├─────────────────────────────────────────────────────────────┤
│                    数据管理层 (Data Layer)                    │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────┐ │
│  │ 应用数据库   │ │ 使用统计     │ │ 配置存储     │ │ 缓存管理 │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────┘ │
├─────────────────────────────────────────────────────────────┤
│                    业务逻辑层 (Business Layer)                │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────┐ │
│  │ 应用管理器   │ │ 快捷键引擎   │ │ 模式切换器   │ │ 静默管理 │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────┘ │
├─────────────────────────────────────────────────────────────┤
│                    核心服务层 (Service Layer)                 │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────┐ │
│  │ 事件监听     │ │ 应用检测     │ │ 窗口管理     │ │ 通知服务 │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────┘ │
├─────────────────────────────────────────────────────────────┤
│                    系统接口层 (System Layer)                  │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────┐ │
│  │ Accessibility│ │ NSWorkspace │ │ NSRunningApp│ │ CoreData│ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 核心模块设计

### 1. 系统接口层 (System Layer)

#### 1.1 权限管理模块
- **AccessibilityManager**: 管理辅助功能权限
- **权限检测**: 自动检测和请求必要权限
- **权限状态监控**: 实时监控权限状态变化

#### 1.2 系统集成模块
- **NSWorkspace**: 应用启动和切换
- **NSRunningApplication**: 运行应用监控
- **NSNotificationCenter**: 系统事件监听

#### 1.3 数据持久化模块
- **CoreData**: 核心数据存储
- **UserDefaults**: 用户配置存储
- **FileManager**: 文件系统操作

### 2. 核心服务层 (Service Layer)

#### 2.1 事件监听服务
```swift
class EventListenerService {
    // 全局快捷键监听
    func startGlobalKeyListener()
    func stopGlobalKeyListener()
    
    // 应用状态变化监听
    func monitorApplicationChanges()
    
    // 系统事件处理
    func handleSystemEvents()
}
```

#### 2.2 应用检测服务
```swift
class ApplicationDetectionService {
    // 获取运行中的应用
    func getRunningApplications() -> [NSRunningApplication]
    
    // 获取 Dock 应用
    func getDockApplications() -> [ApplicationInfo]
    
    // 应用信息解析
    func parseApplicationInfo(_ app: NSRunningApplication) -> ApplicationInfo
}
```

#### 2.3 窗口管理服务
```swift
class WindowManagementService {
    // 窗口状态检测
    func isApplicationFullscreen(_ app: NSRunningApplication) -> Bool
    
    // 窗口激活
    func activateApplication(_ app: NSRunningApplication)
    
    // 窗口最小化检测
    func isApplicationMinimized(_ app: NSRunningApplication) -> Bool
}
```

### 3. 业务逻辑层 (Business Layer)

#### 3.1 应用管理器
```swift
class ApplicationManager {
    // 应用列表管理
    var dockApplications: [ApplicationInfo]
    var runningApplications: [ApplicationInfo]
    var customApplications: [ApplicationInfo]
    
    // 应用操作
    func launchApplication(_ app: ApplicationInfo)
    func switchToApplication(_ app: ApplicationInfo)
    func refreshApplicationList()
}
```

#### 3.2 快捷键引擎
```swift
class ShortcutEngine {
    // 快捷键注册
    func registerShortcut(_ shortcut: Shortcut, action: @escaping () -> Void)
    func unregisterShortcut(_ shortcut: Shortcut)
    
    // 快捷键冲突检测
    func detectConflicts() -> [ShortcutConflict]
    
    // 快捷键执行
    func executeShortcut(_ shortcut: Shortcut)
}
```

#### 3.3 模式切换器
```swift
class ModeSwitcher {
    enum SwitchMode {
        case dock
        case running
        case custom
    }
    
    var currentMode: SwitchMode
    func switchMode(_ mode: SwitchMode)
    func getApplicationsForCurrentMode() -> [ApplicationInfo]
}
```

#### 3.4 静默管理器
```swift
class SilentModeManager {
    // 静默应用列表
    var silentApplications: Set<String>
    
    // 静默状态检测
    func isInSilentMode() -> Bool
    func shouldIgnoreShortcut() -> Bool
    
    // 静默模式控制
    func addToSilentMode(_ app: ApplicationInfo)
    func removeFromSilentMode(_ app: ApplicationInfo)
}
```

### 4. 数据管理层 (Data Layer)

#### 4.1 应用数据库
```swift
class ApplicationDatabase {
    // 应用信息存储
    func saveApplication(_ app: ApplicationInfo)
    func loadApplications() -> [ApplicationInfo]
    func deleteApplication(_ app: ApplicationInfo)
    
    // 应用分组
    func createGroup(_ name: String) -> ApplicationGroup
    func addApplicationToGroup(_ app: ApplicationInfo, group: ApplicationGroup)
}
```

#### 4.2 使用统计模块
```swift
class UsageStatistics {
    // 使用记录
    func recordApplicationUsage(_ app: ApplicationInfo)
    func getUsageStatistics(for period: TimePeriod) -> UsageData
    
    // 数据分析
    func getMostUsedApplications() -> [ApplicationInfo]
    func getUsagePatterns() -> UsagePattern
}
```

#### 4.3 配置存储模块
```swift
class ConfigurationStorage {
    // 用户配置
    func saveUserPreferences(_ preferences: UserPreferences)
    func loadUserPreferences() -> UserPreferences
    
    // 快捷键配置
    func saveShortcutConfiguration(_ config: ShortcutConfiguration)
    func loadShortcutConfiguration() -> ShortcutConfiguration
}
```

### 5. 用户界面层 (UI Layer)

#### 5.1 状态栏管理器
```swift
class StatusBarManager {
    var statusItem: NSStatusItem
    
    func createStatusBarMenu()
    func updateStatusBarIcon()
    func showStatusBarMenu()
    func hideStatusBarMenu()
}
```

#### 5.2 设置窗口控制器
```swift
class SettingsWindowController: NSWindowController {
    // 设置界面管理
    func showSettingsWindow()
    func hideSettingsWindow()
    
    // 配置界面
    func setupShortcutConfigurationView()
    func setupApplicationManagementView()
    func setupAppearanceSettingsView()
}
```

#### 5.3 启动条显示器
```swift
class LaunchBarDisplay {
    var launchBarWindow: NSWindow
    
    func showLaunchBar()
    func hideLaunchBar()
    func updateLaunchBarPosition()
    func updateLaunchBarAppearance()
}
```

## 数据模型设计

### 1. 核心数据模型

```swift
// 应用信息模型
struct ApplicationInfo {
    let bundleIdentifier: String
    let name: String
    let icon: NSImage?
    let path: String
    let isRunning: Bool
    let launchDate: Date?
    let usageCount: Int
}

// 快捷键模型
struct Shortcut {
    let keyCode: UInt16
    let modifiers: NSEvent.ModifierFlags
    let identifier: String
}

// 用户配置模型
struct UserPreferences {
    var switchMode: SwitchMode
    var modifierKey: NSEvent.ModifierFlags
    var showStatusBarIcon: Bool
    var launchBarEnabled: Bool
    var launchBarPosition: LaunchBarPosition
    var silentApplications: Set<String>
}

// 使用统计模型
struct UsageData {
    let application: ApplicationInfo
    let launchCount: Int
    let totalUsageTime: TimeInterval
    let lastUsed: Date
    let averageSessionTime: TimeInterval
}
```

### 2. 数据流设计

```
用户操作 → 事件监听 → 业务逻辑处理 → 数据更新 → UI 刷新
    ↓
快捷键触发 → 应用切换 → 统计记录 → 配置保存
```

## 性能优化策略

### 1. 内存管理
- **应用信息缓存**: 缓存常用应用信息，减少系统调用
- **图片资源管理**: 应用图标懒加载和缓存
- **对象池模式**: 重用频繁创建的对象

### 2. 响应性能
- **异步处理**: 耗时操作异步执行
- **事件队列**: 使用队列管理事件处理
- **预加载**: 预加载常用应用信息

### 3. 系统资源
- **最小权限**: 只请求必要的系统权限
- **后台优化**: 最小化后台资源占用
- **事件过滤**: 过滤不必要的事件监听

## 安全考虑

### 1. 权限管理
- **最小权限原则**: 只请求必要的系统权限
- **权限验证**: 定期验证权限状态
- **权限恢复**: 权限丢失时的恢复机制

### 2. 数据安全
- **本地存储**: 所有数据本地存储，不上传云端
- **数据加密**: 敏感配置数据加密存储
- **访问控制**: 限制应用数据访问权限

### 3. 系统集成
- **沙盒兼容**: 支持 macOS 沙盒机制
- **代码签名**: 应用代码签名验证
- **系统兼容**: 确保与系统更新兼容

## 扩展性设计

### 1. 插件架构
- **插件接口**: 定义标准插件接口
- **动态加载**: 支持插件动态加载
- **插件管理**: 插件安装、卸载、更新

### 2. 主题系统
- **主题接口**: 标准主题接口定义
- **主题切换**: 运行时主题切换
- **自定义主题**: 支持用户自定义主题

### 3. 国际化支持
- **多语言**: 支持多语言界面
- **本地化**: 系统语言自动适配
- **时区支持**: 支持不同时区设置


