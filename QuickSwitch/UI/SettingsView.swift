import SwiftUI
import UniformTypeIdentifiers

/// 设置视图 - 纯 SwiftUI 实现
struct SettingsView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var preferences = UserPreferencesManager.shared.load()
    
    var body: some View {
        TabView {
            GeneralSettingsView(preferences: $preferences)
                .tabItem {
                    Label("通用", systemImage: "gear")
                }
            
            AppBindingsView(preferences: $preferences)
                .tabItem {
                    Label("应用绑定", systemImage: "app.badge")
                }
        }
        .frame(width: 600, height: 400)
        .onChange(of: preferences) { _, newValue in
            UserPreferencesManager.shared.save(newValue)
        }
    }
}

/// 通用设置视图
struct GeneralSettingsView: View {
    
    @Binding var preferences: UserPreferences
    
    var body: some View {
        Form {
            Section {
                Picker("触发修饰键:", selection: $preferences.triggerModifier) {
                    Text("Option").tag(NSEvent.ModifierFlags.option)
                    Text("Control").tag(NSEvent.ModifierFlags.control)
                    Text("Command").tag(NSEvent.ModifierFlags.command)
                    Text("Shift").tag(NSEvent.ModifierFlags.shift)
                }
                .pickerStyle(.menu)
                
                Toggle("显示窗口数量", isOn: $preferences.showWindowCount)
            } header: {
                Text("启动条设置")
                    .font(.headline)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("数据管理")
                                .font(.headline)
                            
                            Text("如果遇到数据过大错误，可以清理存储数据")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("清理数据") {
                            UserPreferencesManager.shared.cleanupUserDefaults()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                    
                    Button("检查数据大小") {
                        UserPreferencesManager.shared.diagnoseDataSize()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 8)
            } header: {
                Text("数据管理")
                    .font(.headline)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("使用说明")
                        .font(.headline)
                    
                    Text("• 按住触发键显示启动条")
                        .font(.caption)
                    
                    Text("• 按住触发键 + Tab 切换视图")
                        .font(.caption)
                    
                    Text("• 按住触发键 + 数字/字母键切换应用")
                        .font(.caption)
                    
                    Text("• 松开触发键隐藏启动条")
                        .font(.caption)
                }
                .padding(.vertical, 8)
            } header: {
                Text("帮助")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

/// 应用绑定视图
struct AppBindingsView: View {
    
    @Binding var preferences: UserPreferences
    @State private var selectedBinding: AppBinding?
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            HStack {
                Text("应用绑定列表")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showingAddSheet = true }) {
                    Label("添加绑定", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                
                Menu {
                    Button("添加常用应用") {
                        addCommonApplications()
                    }
                } label: {
                    Label("快速添加", systemImage: "bolt")
                }
                
                Button(action: editSelectedBinding) {
                    Label("编辑", systemImage: "pencil")
                }
                .disabled(selectedBinding == nil)
                
                Button(action: removeSelectedBinding) {
                    Label("删除", systemImage: "trash")
                }
                .disabled(selectedBinding == nil)
                .foregroundColor(.red)
            }
            .padding()
            
            Divider()
            
            // 绑定列表
            if preferences.appBindings.isEmpty {
                VStack(spacing: 16) {
                    ContentUnavailableView(
                        "没有应用绑定",
                        systemImage: "app.badge",
                        description: Text("点击「添加绑定」按钮开始添加应用")
                    )
                    
                    Button("添加第一个绑定") {
                        showingAddSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List(selection: $selectedBinding) {
                    ForEach(preferences.appBindings.sorted(by: { $0.key.displayName < $1.key.displayName })) { binding in
                        AppBindingRow(binding: binding)
                            .tag(binding)
                            .contextMenu {
                                Button("编辑") {
                                    selectedBinding = binding
                                    editSelectedBinding()
                                }
                                
                                Button("删除", role: .destructive) {
                                    selectedBinding = binding
                                    removeSelectedBinding()
                                }
                            }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddAppBindingView(usedKeys: Set(preferences.appBindings.map { $0.key })) { newBinding in
                addBinding(newBinding)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let binding = selectedBinding {
                EditAppBindingView(binding: binding) { updatedBinding in
                    updateBinding(updatedBinding)
                }
            }
        }
    }
    
    private func addBinding(_ newBinding: AppBinding) {
        // 检查快捷键是否已被使用
        if preferences.appBindings.contains(where: { $0.key == newBinding.key }) {
            // 显示警告
            let alert = NSAlert()
            alert.messageText = "快捷键冲突"
            alert.informativeText = "快捷键 \(newBinding.key.displayName) 已被使用，请选择其他快捷键。"
            alert.addButton(withTitle: "确定")
            alert.runModal()
            return
        }
        
        preferences.appBindings.append(newBinding)
        showingAddSheet = false
    }
    
    private func editSelectedBinding() {
        guard selectedBinding != nil else { return }
        showingEditSheet = true
    }
    
    private func updateBinding(_ updatedBinding: AppBinding) {
        guard let index = preferences.appBindings.firstIndex(where: { $0.id == updatedBinding.id }) else { return }
        preferences.appBindings[index] = updatedBinding
        showingEditSheet = false
    }
    
    private func removeSelectedBinding() {
        guard let binding = selectedBinding else { return }
        
        // 确认删除
        let alert = NSAlert()
        alert.messageText = "确认删除"
        alert.informativeText = "确定要删除应用「\(binding.application.displayName)」的绑定吗？"
        alert.addButton(withTitle: "删除")
        alert.addButton(withTitle: "取消")
        alert.alertStyle = .warning
        
        if alert.runModal() == .alertFirstButtonReturn {
            preferences.appBindings.removeAll { $0.id == binding.id }
            selectedBinding = nil
        }
    }
    
    private func addCommonApplications() {
        let commonApps = [
            ("Safari", "/Applications/Safari.app"),
            ("Chrome", "/Applications/Google Chrome.app"),
            ("Finder", "/System/Library/CoreServices/Finder.app"),
            ("Terminal", "/System/Applications/Utilities/Terminal.app"),
            ("Xcode", "/Applications/Xcode.app"),
            ("Visual Studio Code", "/Applications/Visual Studio Code.app"),
            ("Mail", "/System/Applications/Mail.app"),
            ("Notes", "/System/Applications/Notes.app"),
            ("Calendar", "/System/Applications/Calendar.app")
        ]
        
        var addedCount = 0
        let availableKeys = ShortcutKey.allCases.filter { key in
            !preferences.appBindings.contains { $0.key == key }
        }
        
        for (index, (appName, appPath)) in commonApps.enumerated() {
            guard index < availableKeys.count else { break }
            guard FileManager.default.fileExists(atPath: appPath) else { continue }
            
            let app = ApplicationInfo(
                bundleIdentifier: Bundle(url: URL(fileURLWithPath: appPath))?.bundleIdentifier ?? "",
                name: appName,
                path: appPath,
                icon: NSWorkspace.shared.icon(forFile: appPath),
                isRunning: false
            )
            
            let binding = AppBinding(
                key: availableKeys[index],
                application: app,
                order: preferences.appBindings.count
            )
            
            preferences.appBindings.append(binding)
            addedCount += 1
        }
        
        // 显示结果
        let alert = NSAlert()
        alert.messageText = "快速添加完成"
        alert.informativeText = "已添加 \(addedCount) 个常用应用的绑定"
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
}

/// 应用绑定行视图
struct AppBindingRow: View {
    
    let binding: AppBinding
    
    var body: some View {
        HStack(spacing: 12) {
            // 应用图标
            if let icon = binding.application.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "app.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.secondary)
            }
            
            // 应用信息
            VStack(alignment: .leading, spacing: 2) {
                Text(binding.application.displayName)
                    .font(.body)
                
                Text(binding.application.bundleIdentifier)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 快捷键标签
            Text(binding.key.displayName)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor)
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
}

/// 添加应用绑定视图
struct AddAppBindingView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAppURL: URL?
    @State private var selectedKey: ShortcutKey = .number(1)
    
    let usedKeys: Set<ShortcutKey>
    let onAdd: (AppBinding) -> Void
    
    init(usedKeys: Set<ShortcutKey> = [], onAdd: @escaping (AppBinding) -> Void) {
        self.usedKeys = usedKeys
        self.onAdd = onAdd
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("添加应用绑定")
                .font(.title2)
                .fontWeight(.bold)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("选择应用:")
                    .font(.headline)
                
                Button("选择应用...") {
                    selectApplication()
                }
                .buttonStyle(.bordered)
                
                if let url = selectedAppURL {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(url.lastPathComponent.replacingOccurrences(of: ".app", with: ""))
                            .font(.body)
                        Spacer()
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("选择快捷键:")
                    .font(.headline)
                
                Picker("快捷键", selection: $selectedKey) {
                    ForEach(availableKeys, id: \.self) { key in
                        HStack {
                            Text(key.displayName)
                            if usedKeys.contains(key) {
                                Text("(已使用)")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                        .tag(key)
                    }
                }
                .pickerStyle(.menu)
                
                if usedKeys.contains(selectedKey) {
                    Text("⚠️ 此快捷键已被使用")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            HStack {
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("添加") {
                    addBinding()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedAppURL == nil || usedKeys.contains(selectedKey))
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 350)
    }
    
    private var availableKeys: [ShortcutKey] {
        return ShortcutKey.allCases
    }
    
    private func selectApplication() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.application]
        panel.prompt = "选择"
        
        panel.begin { response in
            if response == .OK {
                selectedAppURL = panel.url
            }
        }
    }
    
    private func addBinding() {
        guard let url = selectedAppURL else { return }
        
        let bundle = Bundle(url: url)
        let bundleIdentifier = bundle?.bundleIdentifier ?? ""
        let displayName = bundle?.localizedInfoDictionary?["CFBundleDisplayName"] as? String ??
                         bundle?.infoDictionary?["CFBundleName"] as? String ??
                         url.lastPathComponent.replacingOccurrences(of: ".app", with: "")
        
        let app = ApplicationInfo(
            bundleIdentifier: bundleIdentifier,
            name: displayName,
            path: url.path,
            icon: NSWorkspace.shared.icon(forFile: url.path),
            isRunning: false
        )
        
        let binding = AppBinding(
            key: selectedKey,
            application: app,
            order: 0
        )
        
        onAdd(binding)
    }
}

/// 编辑应用绑定视图
struct EditAppBindingView: View {
    
    @Environment(\.dismiss) private var dismiss
    let binding: AppBinding
    let onUpdate: (AppBinding) -> Void
    
    @State private var selectedKey: ShortcutKey
    
    init(binding: AppBinding, onUpdate: @escaping (AppBinding) -> Void) {
        self.binding = binding
        self.onUpdate = onUpdate
        self._selectedKey = State(initialValue: binding.key)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("编辑应用绑定")
                .font(.title2)
                .fontWeight(.bold)
            
            Divider()
            
            // 应用信息
            HStack(spacing: 12) {
                if let icon = binding.application.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 48, height: 48)
                } else {
                    Image(systemName: "app.fill")
                        .resizable()
                        .frame(width: 48, height: 48)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(binding.application.displayName)
                        .font(.headline)
                    
                    Text(binding.application.bundleIdentifier)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            // 快捷键选择
            VStack(alignment: .leading, spacing: 12) {
                Text("选择快捷键:")
                    .font(.headline)
                
                Picker("快捷键", selection: $selectedKey) {
                    ForEach(ShortcutKey.allCases, id: \.self) { key in
                        Text(key.displayName).tag(key)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Spacer()
            
            HStack {
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("保存") {
                    saveChanges()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
    
    private func saveChanges() {
        let updatedBinding = AppBinding(
            key: selectedKey,
            application: binding.application,
            order: binding.order
        )
        
        onUpdate(updatedBinding)
    }
}

// MARK: - ShortcutKey Extension
// ShortcutKey 扩展已在 AppBinding.swift 中定义

// MARK: - Preview

#Preview("Settings") {
    SettingsView()
}

#Preview("General Settings") {
    GeneralSettingsView(preferences: .constant(UserPreferences(
        triggerModifier: .option,
        appBindings: [],
        showWindowCount: true
    )))
}

#Preview("App Bindings") {
    AppBindingsView(preferences: .constant(UserPreferences(
        triggerModifier: .option,
        appBindings: [
            AppBinding(
                key: .number(1),
                application: ApplicationInfo(
                    bundleIdentifier: "com.apple.Safari",
                    name: "Safari",
                    path: "/Applications/Safari.app",
                    icon: nil,
                    isRunning: true
                ),
                order: 0
            )
        ],
        showWindowCount: true
    )))
}

