import SwiftUI
import RevenueCat

// 這就是我們的付款介面，它會接收到 App 傳來的訂閱方案
struct PaywallView: View {
    
    // 接收從 ContentView 傳來的 Offering 狀態
    let offering: Offering
    
    // 關閉按鈕，讓用戶可以返回
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                // 1. 標題與說明
                Text("Upgrade to Pro!")
                    .font(.largeTitle)
                    .bold()
                
                Text("Unlock unlimited AI analysis and get accurate calorie counts for any food item.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // 2. 顯示 Packages / 價格清單
                VStack(alignment: .leading, spacing: 15) {
                    ForEach(offering.availablePackages) { package in
                        PackageCell(package: package)
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 30)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                
                // 3. 恢復購買按鈕
                Button("Restore Purchases") {
                    Task {
                        do {
                            let info = try await Purchases.shared.restorePurchases()
                            // 可在此依權益判斷是否關閉付費牆
                            _ = info.activeSubscriptions
                        } catch {
                            // 這裡可以顯示錯誤給使用者
                            print("Restore failed: \(error)")
                        }
                    }
                }
                .font(.callout)
                
                // 法遵連結（可點擊）
                HStack(spacing: 16) {
                    Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    Link("Privacy Policy", destination: URL(string: "https://eric1207cvb.github.io/hsuehyian-pages/")!)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
                
                Text("By subscribing, you agree to our Terms of Use and Privacy Policy. Subscription auto-renews unless canceled at least 24 hours before the end of the current period. Manage or cancel in your App Store account settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding()
            .toolbar {
                // 5. 關閉按鈕
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 輔助結構：顯示單個訂閱 Package 的資訊
struct PackageCell: View {
    let package: Package
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(package.storeProduct.localizedTitle)
                    .font(.headline)
                Text(package.storeProduct.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            
            // 價格按鈕與期間
            VStack(alignment: .trailing, spacing: 4) {
                Button(package.localizedPriceString) {
                    Task {
                        do {
                            let result = try await Purchases.shared.purchase(package: package)
                            if !result.userCancelled {
                                // 成功購買，這裡可透過通知或環境關閉付費牆
                                print("Purchase success: \(String(describing: result.customerInfo.activeSubscriptions))")
                            }
                        } catch {
                            print("Purchase failed: \(error)")
                        }
                    }
                }
                .buttonStyle(.borderedProminent)

                if let period = periodText(for: package) {
                    Text(period)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }
    
    private func periodText(for package: Package) -> String? {
        if let period = package.storeProduct.subscriptionPeriod {
            switch (period.unit, period.value) {
            case (.day, 1): return "per day"
            case (.week, 1): return "per week"
            case (.month, 1): return "per month"
            case (.year, 1): return "per year"
            default:
                // Fallback for multi-periods, e.g., every 3 months
                let unit: String
                switch period.unit {
                case .day: unit = "days"
                case .week: unit = "weeks"
                case .month: unit = "months"
                case .year: unit = "years"
                @unknown default: unit = "periods"
                }
                return "every \(period.value) \(unit)"
            }
        }
        return nil
    }
}

// 預覽結構
#Preview {
    // 警告：這個預覽會因為沒有真實的 RevenueCat Package 資料而失敗
    // 我們需要模擬一個 Package 來預覽，但現在我們略過預覽
    // PaywallView(offering: <#T##Offering#>) 
    Text("Paywall Preview requires live data.")
}
