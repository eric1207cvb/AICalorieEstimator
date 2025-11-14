// --- SkeletonView.swift ---
// 這就是 "LoadingView" 的 v5 升級版
// 它模仿 "ResultView" 的排版，但顯示 "灰色骨架"

import SwiftUI

struct SkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            
            // 1. 模仿 "總熱量" 的標題
            SkeletonElement(width: 100, height: 16) // (灰條)
            SkeletonElement(width: 200, height: 32) // (灰條)
            
            Divider()
            
            // 2. 模仿 "辨識項目" 的標題
            SkeletonElement(width: 120, height: 20)
            
            // 模仿 2-3 個項目
            SkeletonElement(width: .infinity, height: 18)
            SkeletonElement(width: .infinity, height: 18)
            SkeletonElement(width: 150, height: 18)
            
            Divider()
            
            // 3. 模仿 "估算過程" 的標題
            SkeletonElement(width: 120, height: 20)
            
            // 模仿 2-3 行的估算過程
            SkeletonElement(width: .infinity, height: 18)
            SkeletonElement(width: 200, height: 18)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // 【關鍵】讓 "所有" 的灰色骨架都套上 "微光" 動畫！
        .shimmer()
    }
}

// 這是單一一個 "灰色骨架" 的 helper
struct SkeletonElement: View {
    let width: CGFloat?
    let height: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(skeletonGray) // (使用我們在 Shimmer.swift 中定義的顏色)
            .frame(width: width)
            .frame(height: height)
    }
}

// 讓 Preview 更好看
#Preview("骨架屏預覽") {
    VStack {
        Text("分析結果：").font(.headline)
        SkeletonView()
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .cornerRadius(10)
    .padding()
}
