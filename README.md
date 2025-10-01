# Quick Switch

一个用于替换 Mac 应用 Manico 的快速应用切换工具。

## 项目状态

### ✅ 已完成 (第一阶段)

- [x] 项目基础架构搭建
- [x] 系统接口层实现
  - [x] AccessibilityManager - 辅助功能权限管理
  - [x] SystemIntegrationManager - 系统集成管理
- [x] 核心服务层实现
  - [x] EventListenerService - 全局事件监听
  - [x] ApplicationManager - 应用管理
  - [x] ShortcutEngine - 快捷键引擎
- [x] 数据模型定义
  - [x] ApplicationInfo - 应用信息模型
  - [x] Shortcut - 快捷键模型
  - [x] UserPreferences - 用户偏好设置
- [x] 基础 UI 框架
  - [x] StatusBarManager - 状态栏管理
  - [x] AppDelegate - 应用入口

### 🚧 进行中 (第二阶段)

- [ ] 快捷键系统完善
- [ ] 三种切换模式实现
- [ ] 静默模式功能
- [ ] 设置界面开发

### 📋 待开发 (后续阶段)

- [ ] 启动条功能
- [ ] 用量统计
- [ ] 应用分组
- [ ] 工作空间
- [ ] 智能推荐

## 技术架构

### 六层架构设计

1. **系统接口层** - 权限管理、系统集成、数据持久化
2. **核心服务层** - 事件监听、应用检测、窗口管理
3. **业务逻辑层** - 应用管理、快捷键引擎、模式切换
4. **数据管理层** - 应用数据库、使用统计、配置存储
5. **用户界面层** - 状态栏、设置窗口、启动条
6. **配置管理层** - 快捷键配置、应用配置、用户偏好

### 核心技术

- **Swift 5.7+** - 主要开发语言
- **macOS 10.15+** - 最低系统要求
- **Accessibility API** - 全局快捷键监听
- **NSWorkspace** - 应用管理
- **Combine** - 响应式编程
- **CoreData** - 数据持久化

## 功能特性

### 核心功能

- **三种切换模式**
  - Dock 模式：映射 macOS Dock 应用
  - 切换器模式：映射运行中的应用
  - 自定义模式：用户自定义应用列表

- **全局快捷键**
  - 默认：Option + 1-9 数字键
  - 支持自定义修饰键和触发键
  - 智能冲突检测

- **静默模式**
  - 应用排除列表
  - 全屏应用自动检测
  - 游戏模式识别

### 高级功能

- **状态栏集成** - 快速访问和设置
- **使用统计** - 应用使用频率分析
- **应用分组** - 相关应用分组管理
- **工作空间** - 不同场景的应用配置
- **智能推荐** - 基于使用习惯的应用推荐

## 开发环境

### 系统要求

- macOS 10.15 或更高版本
- Xcode 14.0 或更高版本
- Swift 5.7 或更高版本

### 构建和运行

1. 克隆项目
```bash
git clone https://github.com/your-username/quick-switch.git
cd quick-switch
```

2. 使用 Xcode 打开项目
```bash
open QuickSwitch.xcodeproj
```

3. 构建并运行项目
- 选择目标设备
- 按 Cmd+R 运行

### 权限设置

首次运行时需要授予以下权限：

1. **辅助功能权限**
   - 系统偏好设置 > 安全性与隐私 > 隐私 > 辅助功能
   - 添加 Quick Switch 应用

2. **自动化权限**
   - 系统偏好设置 > 安全性与隐私 > 隐私 > 自动化
   - 允许 Quick Switch 控制其他应用

## 项目结构

```
QuickSwitch/
├── Models/                 # 数据模型
│   ├── ApplicationInfo.swift
│   ├── Shortcut.swift
│   └── UserPreferences.swift
├── Services/               # 服务层
│   ├── System/            # 系统接口层
│   │   ├── AccessibilityManager.swift
│   │   └── SystemIntegrationManager.swift
│   └── Core/              # 核心服务层
│       ├── EventListenerService.swift
│       ├── ApplicationManager.swift
│       └── ShortcutEngine.swift
├── UI/                    # 用户界面
│   └── StatusBarManager.swift
├── Assets.xcassets/       # 资源文件
├── AppDelegate.swift      # 应用入口
├── Info.plist            # 应用配置
└── Main.storyboard       # 主界面
```

## 开发计划

### 第一阶段：基础框架 (已完成)
- [x] 项目初始化和架构搭建
- [x] 核心服务层实现
- [x] 基础数据模型
- [x] 状态栏集成

### 第二阶段：核心功能 (进行中)
- [ ] 快捷键系统完善
- [ ] 三种切换模式实现
- [ ] 静默模式功能
- [ ] 基础设置界面

### 第三阶段：用户界面 (计划中)
- [ ] 完整设置界面
- [ ] 启动条功能
- [ ] 界面优化和动画

### 第四阶段：高级功能 (计划中)
- [ ] 使用统计
- [ ] 应用分组
- [ ] 工作空间
- [ ] 智能推荐

### 第五阶段：优化发布 (计划中)
- [ ] 性能优化
- [ ] 稳定性测试
- [ ] 用户文档
- [ ] 应用商店发布

## 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 联系方式

- 项目链接：[https://github.com/your-username/quick-switch](https://github.com/your-username/quick-switch)
- 问题反馈：[Issues](https://github.com/your-username/quick-switch/issues)

## 致谢

- 感谢 Manico 应用提供的灵感
- 感谢所有贡献者的支持
