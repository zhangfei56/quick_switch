import Cocoa

/// 快捷键模型
struct Shortcut: Codable, Identifiable, Hashable {
    let id: String
    let keyCode: UInt16
    let modifiers: NSEvent.ModifierFlags
    let identifier: String
    let displayName: String
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case id, keyCode, identifier, displayName
        case modifiersRawValue
    }
    
    init(keyCode: UInt16, modifiers: NSEvent.ModifierFlags, identifier: String) {
        self.id = identifier
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.identifier = identifier
        self.displayName = Shortcut.displayString(keyCode: keyCode, modifiers: modifiers)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        keyCode = try container.decode(UInt16.self, forKey: .keyCode)
        identifier = try container.decode(String.self, forKey: .identifier)
        displayName = try container.decode(String.self, forKey: .displayName)
        let modifiersRawValue = try container.decode(UInt.self, forKey: .modifiersRawValue)
        modifiers = NSEvent.ModifierFlags(rawValue: modifiersRawValue)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(keyCode, forKey: .keyCode)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(modifiers.rawValue, forKey: .modifiersRawValue)
    }
    
    
    // MARK: - Static Methods
    
    static func displayString(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> String {
        var components: [String] = []
        
        // 添加修饰键
        if modifiers.contains(.command) {
            components.append("⌘")
        }
        if modifiers.contains(.option) {
            components.append("⌥")
        }
        if modifiers.contains(.control) {
            components.append("⌃")
        }
        if modifiers.contains(.shift) {
            components.append("⇧")
        }
        
        // 添加主键
        let keyString = keyString(for: keyCode)
        components.append(keyString)
        
        return components.joined(separator: "")
    }
    
    private static func keyString(for keyCode: UInt16) -> String {
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "I"
        case 35: return "P"
        case 36: return "Return"
        case 37: return "L"
        case 38: return "J"
        case 39: return "'"
        case 40: return "K"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        case 48: return "Tab"
        case 49: return "Space"
        case 50: return "`"
        case 51: return "Delete"
        case 52: return "Enter"
        case 53: return "Escape"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 99: return "F3"
        case 100: return "F8"
        case 101: return "F9"
        case 103: return "F11"
        case 105: return "F13"
        case 106: return "F16"
        case 107: return "F14"
        case 109: return "F10"
        case 111: return "F12"
        case 113: return "F15"
        case 114: return "Help"
        case 115: return "Home"
        case 116: return "Page Up"
        case 117: return "Forward Delete"
        case 118: return "F4"
        case 119: return "End"
        case 120: return "F2"
        case 121: return "Page Down"
        case 122: return "F1"
        case 123: return "Left Arrow"
        case 124: return "Right Arrow"
        case 125: return "Down Arrow"
        case 126: return "Up Arrow"
        default: return "Key \(keyCode)"
        }
    }
}

// MARK: - Equatable

extension Shortcut: Equatable {
    static func == (lhs: Shortcut, rhs: Shortcut) -> Bool {
        return lhs.keyCode == rhs.keyCode && lhs.modifiers == rhs.modifiers
    }
}

// MARK: - Hashable

extension Shortcut {
    func hash(into hasher: inout Hasher) {
        hasher.combine(keyCode)
        hasher.combine(modifiers.rawValue)
    }
}
