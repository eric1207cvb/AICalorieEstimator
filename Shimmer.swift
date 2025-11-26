//// --- Shimmer.swift ---
// 這是一個 "ViewModifier" (視圖修飾器)，用來建立「微光掃過」的動畫

import SwiftUI

// 1. 骨架屏的灰色
let skeletonGray = Color.gray.opacity(0.3)

// 2. 微光動畫的修飾器
struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -1.0 // 動畫階段
    
    func body(content: Content) -> some View {
        content
            .overlay(
                // 3. 我們疊加一個 "漸層" (從透明 -> 亮灰 -> 透明)
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        skeletonGray.opacity(0.8), // 微光
                        .clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                // 4. 讓這個漸層 "動" 起來
                .offset(x: phase * 300) // (300 是漸層的寬度)
                .animation(
                    .linear(duration: 1.5) // (動畫持續 1.5 秒)
                    .repeatForever(autoreverses: false), // (無限重複)
                    value: phase
                )
            )
            .onAppear {
                phase = 1.0 // (當 View 出現時，開始動畫)
            }
    }
}

// 5. 讓我們可以更簡單地使用它
extension View {
    func shimmer() -> some View {
        self.modifier(Shimmer())
    }
}
//  Shimmer.swift
//  AICalorieEstimator
//
//  Created by 薛宜安 on 2025/11/14.
//

