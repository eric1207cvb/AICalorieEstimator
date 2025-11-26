# 食物熱量分析器（Pro）

這是一款以 SwiftUI 開發的應用程式，可估算食物的熱量；升級為 Pro 後可享有無限制的 AI 分析。訂閱功能由 RevenueCat 提供。

[English README](./README.md) | [日本語 README](./README-ja.md)

## 功能特色
- 掃描或輸入食物項目，顯示估算熱量
- 升級 Pro，解鎖無限制 AI 分析與更高準確度
- 使用 RevenueCat 的 Offering / Package 實作付費牆
- 支援恢復購買

## 技術堆疊
- SwiftUI
- RevenueCat（訂閱 / 權益）
- Swift Concurrency（async/await）

## 專案結構重點
- `PaywallView.swift`：使用 RevenueCat 的 `Offering` 與 `Package` 顯示付費牆 UI，包含購買與恢復流程。

## 設定步驟
1. 使用 Xcode 15 以上版本開啟專案。
2. 安裝 RevenueCat（建議使用 Swift Package Manager）：
   - File > Add Packages…
   - URL: https://github.com/RevenueCat/purchases-ios
   - 加入至你的 App target
3. 在 App 進入點（例如 `App`）初始化 RevenueCat SDK：
   ```swift
   import RevenueCat

   // 初始化範例
   Purchases.configure(withAPIKey: "YOUR_REVENUECAT_API_KEY")
