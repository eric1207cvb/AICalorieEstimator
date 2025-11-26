import SwiftUI
import RevenueCat

// 這就是我們的付款介面，它會接收到 App 傳來的訂閱方案
struct PaywallView: View {
    
    // 接收從 ContentView 傳來的 Offering 狀態
    let offering: Offering
    
    // 關閉按鈕，讓用戶可以返回
    @Environment(\.dismiss) var dismiss

    @State private var isPurchasing: Bool = false
    @State private var isRestoring: Bool = false
    @State private var purchaseErrorMessage: String?

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
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose a plan")
                        .font(.title3).bold()
                    Text("Select a subscription to unlock Pro features.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 2. 顯示 Packages / 價格清單
                VStack(alignment: .leading, spacing: 15) {
                    ForEach(offering.availablePackages) { package in
                        PackageCell(package: package, isPurchasing: $isPurchasing)
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 30)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Subscription terms")
                        .font(.headline)
                    Group {
                        Label("Subscription auto-renews unless canceled at least 24 hours before the end of the current period.", systemImage: "checkmark.circle")
                        Label("Manage or cancel your subscription in your App Store account settings.", systemImage: "checkmark.circle")
                        Label("Payment is charged to your Apple ID at confirmation of purchase.", systemImage: "checkmark.circle")
                        Label("Your account will be charged for renewal within 24 hours prior to the end of the current period.", systemImage: "checkmark.circle")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 3. 恢復購買按鈕
                Button(action: {
                    Task {
                        isRestoring = true
                        defer { isRestoring = false }
                        do {
                            let info = try await Purchases.shared.restorePurchases()
                            let isPro = info.entitlements.active.keys.contains("pro")
                            NotificationCenter.default.post(name: Notification.Name("proStatusUpdated"), object: isPro)
                            _ = info.activeSubscriptions
                        } catch {
                            purchaseErrorMessage = error.localizedDescription
                        }
                    }
                }) {
                    if isRestoring {
                        ProgressView().progressViewStyle(.circular)
                    } else {
                        Text("Restore Purchases")
                    }
                }
                .disabled(isPurchasing || isRestoring)
                .font(.callout)
                
                // 法遵連結（可點擊）
                VStack(spacing: 8) {
                    HStack(spacing: 16) {
                        Link("Terms of Use (EULA)", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        Link("Privacy Policy", destination: URL(string: "https://eric1207cvb.github.io/hsuehyian-pages/")!)
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                
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
            .alert("Purchase Error", isPresented: Binding(get: { purchaseErrorMessage != nil }, set: { if !$0 { purchaseErrorMessage = nil } })) {
                Button("OK", role: .cancel) { purchaseErrorMessage = nil }
            } message: {
                Text(purchaseErrorMessage ?? "Unknown error")
            }
        }
    }
}

// 輔助結構：顯示單個訂閱 Package 的資訊
struct PackageCell: View {
    let package: Package
    @Binding var isPurchasing: Bool

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName(for: package))
                    .font(.headline)
                Text(periodText(for: package) ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Button(action: {
                    Task {
                        isPurchasing = true
                        defer { isPurchasing = false }
                        do {
                            let result = try await Purchases.shared.purchase(package: package)
                            if !result.userCancelled {
                                // Immediately refresh customer info and notify UI
                                do {
                                    let info = try await Purchases.shared.customerInfo()
                                    let isPro = info.entitlements.active.keys.contains("pro")
                                    NotificationCenter.default.post(name: Notification.Name("proStatusUpdated"), object: isPro)
                                } catch {
                                    // fallback: still post a generic update to trigger refresh elsewhere
                                    NotificationCenter.default.post(name: Notification.Name("proStatusUpdated"), object: nil)
                                }
                            }
                        } catch {
                            // bubble up via notification by setting an environment binding would be ideal; omitted here
                        }
                    }
                }) {
                    if isPurchasing {
                        ProgressView()
                    } else {
                        Text(package.localizedPriceString)
                            .bold()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isPurchasing)

                if let period = periodText(for: package) {
                    Text(period)
                        .font(.caption2)
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
    
    private func displayName(for package: Package) -> String {
        // Prefer the store product's localizedTitle; fall back to package identifier
        let title = package.storeProduct.localizedTitle
        if !title.isEmpty { return title }
        return package.identifier
    }
}

// 預覽結構
#Preview {
    // 警告：這個預覽會因為沒有真實的 RevenueCat Package 資料而失敗
    // 我們需要模擬一個 Package 來預覽，但現在我們略過預覽
    // PaywallView(offering: <#T##Offering#>) 
    Text("Paywall Preview requires live data.")
}
