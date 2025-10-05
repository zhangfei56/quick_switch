import SwiftUI
import Cocoa

/// 启动条内容视图 - 纯 SwiftUI 实现
struct LaunchBarContentView: View {
    
    // MARK: - Properties
    
    let applications: [ApplicationInfo]
    let selectedIndex: Int
    let showWindowCount: Bool
    let onSelectApplication: (ApplicationInfo) -> Void
    		
    // MARK: - Constants
    
    private let itemWidth: CGFloat = 70
    private let itemHeight: CGFloat = 70  // 减小高度，因为移除了应用名称
    private let itemSpacing: CGFloat = 10
    private let cornerRadius: CGFloat = 12
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: itemSpacing) {	
            ForEach(Array(applications.enumerated()), id: \.element.id) { index, app in
                ApplicationItemView(
                    application: app,
                    index: index,
                    isSelected: index == selectedIndex,
                    showWindowCount: showWindowCount
                )
                .frame(width: itemWidth, height: itemHeight)
                .onTapGesture {
                    onSelectApplication(app)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

/// 单个应用项目视图
struct ApplicationItemView: View {
    
    let application: ApplicationInfo
    let index: Int
    let isSelected: Bool
    let showWindowCount: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // 应用图标和快捷键标签
            ZStack(alignment: .topTrailing) {
                if let icon = application.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 50, height: 50)
                } else {
                    Image(systemName: "app.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.secondary)
                }
                
                // 快捷键标签
                Text(shortcutKeyText)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .offset(x: 5, y: -5)
            }
            .frame(width: 50, height: 50)
            
            // 窗口数量小点点（显示在应用下方）
            if showWindowCount {
                WindowDotsView(windowCount: getWindowCount())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
    
    private var shortcutKeyText: String {
        // 数字键 1-9
        if index < 9 {
            let displayNumber = index + 1
            print("🏷️ 索引 \(index) 显示数字: \(displayNumber)")
            return "\(displayNumber)"
        }
        // 字母键 A-Z (从第10个开始，即index 9开始对应A)
        else if index < 35 {
            let letterIndex = index - 9
            let letter = Character(UnicodeScalar(65 + letterIndex)!) // A=65
            return String(letter)
        }
        // 功能键 F1-F12 (从第36个开始，即index 35开始对应F1)
        else if index < 47 {
            let functionIndex = index - 35
            return "F\(functionIndex + 1)"
        }
        return ""
    }
    
    private func getWindowCount() -> Int {
        // 返回应用的实际窗口数量
        return application.windowCount
    }
}

/// 窗口数量小点点视图
struct WindowDotsView: View {
    let windowCount: Int
    private let maxDots = 5  // 最多显示5个点
    private let dotSize: CGFloat = 5
    private let dotSpacing: CGFloat = 3
    
    var body: some View {
        if windowCount > 0 {
            HStack(spacing: dotSpacing) {
                ForEach(0..<min(windowCount, maxDots), id: \.self) { _ in
                    Circle()
                        .fill(Color.orange)
                        .frame(width: dotSize, height: dotSize)
                }
                
                // 如果窗口数量超过5个，显示 +N
                if windowCount > maxDots {
                    Text("+\(windowCount - maxDots)")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.orange)
                }
            }
            .frame(height: 8)
        } else {
            // 占位空间，保持布局一致
            Color.clear
                .frame(height: 8)
        }
    }
}

// MARK: - Preview

#Preview {
    LaunchBarContentView(
        applications: [
            ApplicationInfo(
                bundleIdentifier: "com.apple.Safari",
                name: "Safari",
                path: "/Applications/Safari.app",
                icon: NSImage(systemSymbolName: "safari", accessibilityDescription: nil),
                isRunning: true
            ),
            ApplicationInfo(
                bundleIdentifier: "com.apple.Mail",
                name: "Mail",
                path: "/Applications/Mail.app",
                icon: NSImage(systemSymbolName: "envelope", accessibilityDescription: nil),
                isRunning: true
            ),
            ApplicationInfo(
                bundleIdentifier: "com.apple.Notes",
                name: "Notes",
                path: "/Applications/Notes.app",
                icon: NSImage(systemSymbolName: "note.text", accessibilityDescription: nil),
                isRunning: false
            )
        ],
        selectedIndex: 0,
        showWindowCount: true,
        onSelectApplication: { _ in }
    )
    .frame(width: 300, height: 120)
}

