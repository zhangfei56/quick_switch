# Quick Switch 开发指南

## 开发环境设置

### 系统要求
- macOS 10.15 (Catalina) 或更高版本
- Xcode 14.0 或更高版本
- Swift 5.7 或更高版本
- Git

### 安装步骤

1. **克隆项目**
```bash
git clone https://github.com/your-username/quick-switch.git
cd quick-switch
```

2. **打开项目**
```bash
open QuickSwitch.xcodeproj
```

3. **配置代码签名**
- 在 Xcode 中选择项目
- 选择 Quick Switch target
- 在 Signing & Capabilities 标签中配置团队

4. **授予权限**
- 运行应用后，需要授予辅助功能权限
- 系统偏好设置 > 安全性与隐私 > 隐私 > 辅助功能
- 添加 Quick Switch 应用

## 项目结构

```
QuickSwitch/
├── Models/                     # 数据模型
│   ├── ApplicationInfo.swift   # 应用信息
│   ├── Shortcut.swift         # 快捷键
│   └── UserPreferences.swift  # 用户偏好
│
├── Services/                   # 服务层
│   ├── System/                # 系统接口层
│   │   ├── AccessibilityManager.swift
│   │   └── SystemIntegrationManager.swift
│   │
│   ├── Core/                  # 核心服务层
│   │   ├── EventListenerService.swift
│   │   ├── ApplicationManager.swift
│   │   └── ShortcutEngine.swift
│   │
│   └── Business/              # 业务逻辑层
│       ├── SilentModeManager.swift
│       └── ModeSwitcher.swift
│
├── UI/                        # 用户界面层
│   ├── StatusBarManager.swift
│   ├── SettingsWindowController.swift
│   └── LaunchBarDisplay.swift
│
├── Assets.xcassets/           # 资源文件
├── AppDelegate.swift          # 应用入口
├── Info.plist                # 应用配置
└── Main.storyboard           # 主界面
```

## 架构说明

### 六层架构

1. **系统接口层 (System Layer)**
   - 处理系统级 API 调用
   - 权限管理
   - 系统事件监听

2. **核心服务层 (Service Layer)**
   - 提供核心功能服务
   - 事件监听和分发
   - 应用和快捷键管理

3. **业务逻辑层 (Business Layer)**
   - 实现业务逻辑
   - 模式切换
   - 静默模式管理

4. **数据管理层 (Data Layer)**
   - 数据持久化
   - 缓存管理
   - 配置存储

5. **用户界面层 (UI Layer)**
   - UI 组件和窗口
   - 用户交互处理
   - 界面更新

6. **配置管理层 (Config Layer)**
   - 用户偏好设置
   - 应用配置
   - 数据序列化

### 设计原则

- **单一职责**: 每个类只负责一个功能
- **依赖注入**: 通过构造函数注入依赖
- **协议导向**: 使用协议定义接口
- **响应式编程**: 使用 Combine 框架

## 核心模块开发

### 添加新的切换模式

1. 在 `UserPreferences.swift` 中添加新的 `SwitchMode` 枚举值
2. 在 `ModeSwitcher.swift` 中实现模式逻辑
3. 在 `ApplicationManager.swift` 中添加应用获取逻辑
4. 更新 UI 以支持新模式

### 添加新的快捷键

1. 在 `ShortcutEngine.swift` 中注册快捷键
```swift
let shortcut = Shortcut(
    keyCode: keyCode,
    modifiers: .option,
    identifier: "custom_action"
)

shortcutEngine.registerShortcut(shortcut) {
    // 执行自定义操作
}
```

2. 在设置界面中添加配置选项

### 添加新的服务

1. 在相应的层级创建新的 Swift 文件
2. 实现服务类和必要的协议
3. 在 `AppDelegate.swift` 中初始化和启动服务
4. 设置服务依赖关系

## 调试技巧

### 日志输出

使用 `print()` 函数输出调试信息：
```swift
print("应用切换: \(app.name)")
```

### 断点调试

1. 在 Xcode 中设置断点
2. 运行应用 (Cmd+R)
3. 在断点处检查变量值

### 权限问题

如果遇到权限问题：
1. 检查 `AccessibilityManager.isAccessibilityEnabled`
2. 手动打开系统偏好设置授予权限
3. 重启应用

### 内存泄漏检测

1. 使用 Instruments 的 Leaks 工具
2. 检查循环引用（使用 `weak` 和 `unowned`）
3. 定期运行内存分析

## 测试

### 单元测试

（待实现）

### 集成测试

手动测试流程：
1. 启动应用
2. 检查状态栏图标
3. 测试快捷键功能
4. 验证应用切换
5. 测试静默模式
6. 检查设置窗口

## 构建和发布

### 调试构建

```bash
./build.sh build
```

### 发布构建

```bash
xcodebuild archive \
  -project QuickSwitch.xcodeproj \
  -scheme QuickSwitch \
  -archivePath build/QuickSwitch.xcarchive
```

### 代码签名

1. 在 Xcode 中配置开发者账号
2. 选择正确的签名证书
3. 配置 Provisioning Profile

### 应用公证

（待实现）

## 代码规范

### Swift 代码风格

- 使用 4 个空格缩进
- 行长度限制 120 字符
- 类名大写开头（PascalCase）
- 变量和函数名小写开头（camelCase）
- 使用 MARK 注释组织代码

### 注释规范

```swift
/// 简短描述
///
/// 详细描述（可选）
///
/// - Parameters:
///   - param1: 参数1描述
///   - param2: 参数2描述
/// - Returns: 返回值描述
/// - Throws: 可能抛出的错误
func exampleFunction(param1: String, param2: Int) throws -> Bool {
    // 实现
    return true
}
```

### 命名约定

- 使用描述性名称
- 避免缩写（除非是通用缩写）
- 布尔值使用 `is`、`has`、`should` 前缀
- 回调使用 `handle`、`on`、`did` 前缀

## 性能优化

### 内存管理

- 使用 `weak` 避免循环引用
- 及时释放不需要的资源
- 使用对象池重用对象

### 响应速度

- 异步执行耗时操作
- 使用 GCD 或 async/await
- 避免主线程阻塞

### 启动时间

- 延迟加载非必要资源
- 优化初始化顺序
- 使用懒加载

## 常见问题

### Q: 快捷键不工作？
A: 检查辅助功能权限是否已授予。

### Q: 应用列表为空？
A: 检查是否有运行中的应用，或切换到其他模式。

### Q: 状态栏图标不显示？
A: 检查 `UserPreferences.showStatusBarIcon` 设置。

### Q: 编译错误？
A: 确保 Xcode 版本正确，清理构建目录后重新编译。

## 贡献指南

1. Fork 项目
2. 创建功能分支
3. 遵循代码规范
4. 编写测试（如适用）
5. 提交 Pull Request

## 获取帮助

- 查看文档：`docs/` 目录
- 提交 Issue：GitHub Issues
- 联系开发者：通过 GitHub

## 许可证

本项目采用 MIT 许可证。详见 LICENSE 文件。
