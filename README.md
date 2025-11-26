[日本語 (Japanese)](./README-ja.md) | [繁體中文 (Traditional Chinese)](./README-zh-Hant.md)

# Food Calorie Analyzer (Pro)

A SwiftUI app that estimates calories for food items and offers a Pro subscription to unlock unlimited AI analysis. Subscriptions are powered by RevenueCat.

## Features
- Scan or enter food items to get estimated calories.
- Upgrade to Pro to unlock unlimited AI analysis and improved accuracy.
- Paywall implemented with RevenueCat Offerings and Packages.
- Restore purchases and handle subscription terms.

## Tech Stack
- SwiftUI
- RevenueCat (Subscriptions / Entitlements)
- Swift Concurrency (async/await)

## Project Structure Highlights
- `PaywallView.swift`: Displays the paywall UI using `Offering` and `Package` from RevenueCat. Includes purchase and restore flows.
- Other views and models handle food analysis and app logic (not shown here).

## Setup
1. Open the project in Xcode 15+.
2. Install RevenueCat (Swift Package Manager recommended):
   - File > Add Packages…
   - Enter: https://github.com/RevenueCat/purchases-ios
   - Add to your app target.
3. Configure RevenueCat SDK in your app entry point (usually `App` or early in app launch):
   ```swift
   import RevenueCat

   // Example initialization
   Purchases.configure(withAPIKey: "YOUR_REVENUECAT_API_KEY")


