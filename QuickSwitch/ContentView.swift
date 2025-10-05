//
//  ContentView.swift
//  QuickSwitch
//
//  Created by nicky on 2025/10/2.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "command")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Quick Switch")
                .font(.title)
            Text("状态栏应用已启动")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
