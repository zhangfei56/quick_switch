# 更新日志

本文档记录 Quick Switch 项目的所有重要更改。

## [未发布] - 2025-10-01

### 第二阶段完成

#### 新增功能
- ✨ **静默模式管理器** (`SilentModeManager`)
  - 完整的静默应用列表管理
  - 自动检测全屏应用和游戏
  - 预设的常用静默应用列表
  - 静默模式统计和导入导出功能

- ✨ **模式切换器优化** (`ModeSwitcher`)
  - 三种切换模式的完整实现
  - 模式验证和推荐功能
  - 应用排序和快捷访问
  - 模式切换历史记录

- ✨ **设置窗口** (`SettingsWindowController`)
  - 完整的设置界面框架
  - 六个设置标签页：通用、快捷键、应用、静默模式、外观、高级
  - 每个标签页的基础 UI 实现

- ✨ **启动条显示** (`LaunchBarDisplay`)
  - 浮动启动条窗口
  - 模糊效果和动画
  - 位置和外观自定义
  - 自动隐藏功能

#### 改进
- 🔄 **AppDelegate 增强**
  - 集成所有新服务
  - 辅助功能权限检查和提示
  - 静默模式自动集成
  - 服务依赖关系优化

- 🔄 **权限管理优化**
  - 启动时自动检查权限
  - 用户友好的权限提示对话框
  - 一键打开系统偏好设置

### 技术改进
- 使用 Combine 框架实现响应式绑定
- 完善的错误处理和状态管理
- 更好的代码组织和模块化

---

## [0.1.0] - 第一阶段完成

### 基础框架搭建

#### 新增功能
- ✨ **项目初始化**
  - Xcode 项目配置
  - 基础目录结构
  - 构建脚本 (`build.sh`)
  - Git 配置 (`.gitignore`)

- ✨ **系统接口层**
  - `AccessibilityManager` - 辅助功能权限管理
  - `SystemIntegrationManager` - 系统集成和应用管理

- ✨ **核心服务层**
  - `EventListenerService` - 全局事件监听
  - `ApplicationManager` - 应用管理
  - `ShortcutEngine` - 快捷键引擎

- ✨ **数据模型**
  - `ApplicationInfo` - 应用信息模型
  - `Shortcut` - 快捷键模型
  - `UserPreferences` - 用户偏好设置

- ✨ **用户界面**
  - `StatusBarManager` - 状态栏管理
  - `AppDelegate` - 应用入口

#### 文档
- 📝 产品需求文档 (`PRD.md`)
- 📝 系统架构文档 (`ARCHITECTURE.md`)
- 📝 实现步骤规划 (`IMPLEMENTATION_PLAN.md`)
- 📝 项目说明文档 (`README.md`)
- 📝 Cursor 规则配置

---

## 下一步计划

### 第三阶段：用户界面完善
- [ ] 完善设置界面功能
- [ ] 实现快捷键可视化配置
- [ ] 优化启动条交互
- [ ] 添加界面动画效果

### 第四阶段：数据统计功能
- [ ] 实现使用统计模块
- [ ] 创建统计数据展示界面
- [ ] 添加数据导出功能

### 第五阶段：高级功能
- [ ] 应用分组管理
- [ ] 工作空间功能
- [ ] 智能推荐系统

### 第六阶段：优化和测试
- [ ] 性能优化
- [ ] 稳定性测试
- [ ] 用户体验优化

### 第七阶段：发布准备
- [ ] 应用签名和公证
- [ ] 安装包制作
- [ ] 用户文档完善
- [ ] 发布到应用商店

---

## 版本说明

版本号格式：`MAJOR.MINOR.PATCH`

- **MAJOR**: 重大功能更新或不兼容的 API 更改
- **MINOR**: 向后兼容的功能性新增
- **PATCH**: 向后兼容的问题修复

---

## 贡献指南

如果您想为 Quick Switch 做出贡献，请：

1. Fork 本仓库
2. 创建您的功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启一个 Pull Request

---

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。
