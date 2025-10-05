		import Foundation

/// UserDefaults 管理器 - 用于管理数据大小和清理
class UserDefaultsManager {
    
    static let shared = UserDefaultsManager()
    
    private let userDefaults = UserDefaults.standard
    private let preferencesKey = "QuickSwitchUserPreferences"
    
    // NSUserDefaults 的最大数据限制（4MB）
    private let maxDataSize = 4 * 1024 * 1024 // 4MB
    
    private init() {}
    
    // MARK: - 数据大小检查
    
    /// 检查当前 UserDefaults 数据大小
    func checkDataSize() -> (size: Int, isOverLimit: Bool) {
        guard let data = userDefaults.data(forKey: preferencesKey) else {
            return (0, false)
        }
        
        let size = data.count
        let isOverLimit = size >= maxDataSize
        
        print("📊 UserDefaults 数据大小: \(formatBytes(size)) (限制: \(formatBytes(maxDataSize)))")
        
        if isOverLimit {
            print("⚠️ 数据大小超过限制！")
        }
        
        return (size, isOverLimit)
    }
    
    /// 格式化字节数为可读格式
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    // MARK: - 数据清理œ
    
    /// 清理 UserDefaults 中的旧数据
    func cleanupOldData() {
        print("🧹 开始清理 UserDefaults 数据...")
        
        // 移除旧的偏好设置数据
        userDefaults.removeObject(forKey: preferencesKey)
        
        // 同步到磁盘
        userDefaults.synchronize()
        
        print("✅ UserDefaults 数据清理完成")
    }
    
    /// 安全保存数据，如果数据过大则先清理
    func safeSave<T: Codable>(_ object: T, forKey key: String) -> Bool {
        do {
            let data = try JSONEncoder().encode(object)
            
            // 检查数据大小
            if data.count >= maxDataSize {
                print("⚠️ 数据过大 (\(formatBytes(data.count)))，拒绝保存并清理旧数据")
                cleanupOldData()
                return false
            }
            
            userDefaults.set(data, forKey: key)
            print("✅ 数据保存成功: \(formatBytes(data.count))")
            return true
            
        } catch {
            print("❌ 数据保存失败: \(error)")
            return false
        }
    }
    
    /// 安全加载数据
    func safeLoad<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil				
        }
        
        // 检查数据大小
        if data.count >= maxDataSize {
            print("⚠️ 数据过大 (\(formatBytes(data.count)))，清理损坏数据")
            userDefaults.removeObject(forKey: key)
            return nil
        }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("❌ 数据加载失败: \(error)")
            print("🔧 清理损坏的数据...")
            // 如果加载失败，清理损坏的数据
            userDefaults.removeObject(forKey: key)
            userDefaults.synchronize()
            return nil
        }
    }
    
    // MARK: - 诊断工具
    
    /// 诊断 UserDefaults 状态
    func diagnose() {
        print("🔍 UserDefaults 诊断报告:")
        print("================================")
        
        let (size, isOverLimit) = checkDataSize()
        
        if isOverLimit {
            print("❌ 状态: 数据过大")
            print("💡 建议: 运行 cleanupOldData() 清理数据")
        } else {
            print("✅ 状态: 正常")
        }
        
        // 检查是否有其他可能过大的键
        let allKeys = userDefaults.dictionaryRepresentation().keys
        for key in allKeys {
            if let data = userDefaults.data(forKey: key) {
                let keySize = data.count
                if keySize > 1024 * 1024 { // 大于 1MB
                    print("⚠️ 键 '\(key)' 数据较大: \(formatBytes(keySize))")
                }
            }
        }
        
        print("================================")
    }
}
