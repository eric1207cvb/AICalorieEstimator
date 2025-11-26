# フードカロリーアナライザー（Pro）

食品のカロリーを推定し、Pro サブスクリプションで無制限のAI解析を提供する SwiftUI アプリです。サブスクリプションは RevenueCat により実装されています。

[English README](./README.md)
[繁體中文 README](./README-zh-Hant.md)

## 機能
- 食品をスキャンまたは入力して推定カロリーを表示
- Pro にアップグレードして、無制限のAI解析と精度向上をアンロック
- RevenueCat の Offering / Package を用いたペイウォール
- 購入の復元に対応

## 技術スタック
- SwiftUI
- RevenueCat（サブスクリプション / エンタイトルメント）
- Swift Concurrency（async/await）

## プロジェクト構成（主要部分）
- `PaywallView.swift`: RevenueCat の `Offering` と `Package` を使ってペイウォールUIを表示。購入と復元のフローを含みます。

## セットアップ
1. Xcode 15 以上でプロジェクトを開きます。
2. RevenueCat をインストール（Swift Package Manager 推奨）:
   - File > Add Packages…
   - URL: https://github.com/RevenueCat/purchases-ios
   - アプリターゲットに追加
3. アプリのエントリポイント（`App` など）で RevenueCat SDK を初期化:
   ```swift
   import RevenueCat

   // 初期化例
   Purchases.configure(withAPIKey: "YOUR_REVENUECAT_API_KEY")
