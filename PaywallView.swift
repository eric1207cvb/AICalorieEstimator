import SwiftUI
import RevenueCat

// 這就是我們的付款介面，它會接收到 App 傳來的訂閱方案
struct PaywallView: View {

    // 接收從 ContentView 傳來的 Offering 狀態
    let offering: Offering
    let language: AppLanguage
    let onCustomerInfoUpdated: (CustomerInfo) -> Void
    let onDebugSimulatorUnlock: () -> Void

    // 關閉按鈕，讓用戶可以返回
    @Environment(\.dismiss) var dismiss

    @State private var isPurchasing: Bool = false
    @State private var isRestoring: Bool = false
    @State private var purchaseErrorMessage: String?

    init(
        offering: Offering,
        language: AppLanguage = .unitedStates,
        onCustomerInfoUpdated: @escaping (CustomerInfo) -> Void = { _ in },
        onDebugSimulatorUnlock: @escaping () -> Void = {}
    ) {
        self.offering = offering
        self.language = language
        self.onCustomerInfoUpdated = onCustomerInfoUpdated
        self.onDebugSimulatorUnlock = onDebugSimulatorUnlock
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                // 1. 標題與說明
                Text(TranslationManager.get("paywall.title", lang: language))
                    .font(.largeTitle)
                    .bold()

                Text(TranslationManager.get("paywall.subtitle", lang: language))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text(TranslationManager.get("paywall.choose_plan", lang: language))
                        .font(.title3).bold()
                    Text(TranslationManager.get("paywall.choose_plan_desc", lang: language))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 2. 顯示 Packages / 價格清單
                VStack(alignment: .leading, spacing: 15) {
                    ForEach(offering.availablePackages) { package in
                        PackageCell(
                            package: package,
                            language: language,
                            isPurchasing: $isPurchasing,
                            purchaseErrorMessage: $purchaseErrorMessage,
                            onCustomerInfoUpdated: onCustomerInfoUpdated,
                            onPurchaseUnlocked: { dismiss() }
                        )
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 30)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)

                VStack(alignment: .leading, spacing: 6) {
                    Text(TranslationManager.get("paywall.terms_title", lang: language))
                        .font(.headline)
                    Group {
                        Label(TranslationManager.get("paywall.term.auto_renew", lang: language), systemImage: "checkmark.circle")
                        Label(TranslationManager.get("paywall.term.manage", lang: language), systemImage: "checkmark.circle")
                        Label(TranslationManager.get("paywall.term.payment", lang: language), systemImage: "checkmark.circle")
                        Label(TranslationManager.get("paywall.term.renewal", lang: language), systemImage: "checkmark.circle")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 3. 恢復購買按鈕
                Button(action: {
                    Task { @MainActor in
                        isRestoring = true
                        defer { isRestoring = false }
                        do {
                            Purchases.shared.invalidateCustomerInfoCache()
                            let info = try await Purchases.shared.restorePurchases()
                            onCustomerInfoUpdated(info)
                            if SubscriptionAccessPolicy.hasActiveProEntitlement(info.entitlements.active.keys) {
                                dismiss()
                            } else {
                                purchaseErrorMessage = TranslationManager.get("paywall.restore.no_active", lang: language)
                            }
                        } catch {
                            purchaseErrorMessage = error.localizedDescription
                        }
                    }
                }) {
                    if isRestoring {
                        ProgressView().progressViewStyle(.circular)
                    } else {
                        Text(TranslationManager.get("paywall.restore", lang: language))
                    }
                }
                .disabled(isPurchasing || isRestoring)
                .font(.callout)

                #if DEBUG && targetEnvironment(simulator)
                Button {
                    onDebugSimulatorUnlock()
                    dismiss()
                } label: {
                    Label(TranslationManager.get("paywall.simulator_unlock", lang: language), systemImage: "testtube.2")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isPurchasing || isRestoring)

                Text(TranslationManager.get("paywall.simulator_unlock_note", lang: language))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                #endif

                // 法遵連結（可點擊）
                VStack(spacing: 8) {
                    HStack(spacing: 16) {
                        Link(TranslationManager.get("footer.terms_eula", lang: language), destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        Link(TranslationManager.get("footer.privacy_policy", lang: language), destination: URL(string: "https://eric1207cvb.github.io/hsuehyian-pages/")!)
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                Text(TranslationManager.get("paywall.agreement", lang: language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding()
            .toolbar {
                // 5. 關閉按鈕
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(TranslationManager.get("paywall.done", lang: language)) {
                        dismiss()
                    }
                }
            }
            .alert(TranslationManager.get("paywall.error_title", lang: language), isPresented: Binding(get: { purchaseErrorMessage != nil }, set: { if !$0 { purchaseErrorMessage = nil } })) {
                Button(TranslationManager.get("alert.ok", lang: language), role: .cancel) { purchaseErrorMessage = nil }
            } message: {
                Text(purchaseErrorMessage ?? TranslationManager.get("paywall.unknown_error", lang: language))
            }
        }
    }
}

// 輔助結構：顯示單個訂閱 Package 的資訊
struct PackageCell: View {
    let package: Package
    let language: AppLanguage
    @Binding var isPurchasing: Bool
    @Binding var purchaseErrorMessage: String?
    let onCustomerInfoUpdated: (CustomerInfo) -> Void
    let onPurchaseUnlocked: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(SubscriptionDisplayText.planName(for: package, language: language))
                    .font(.headline)
                Text(SubscriptionDisplayText.periodText(for: package, language: language) ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Button(action: {
                    Task { @MainActor in
                        isPurchasing = true
                        defer { isPurchasing = false }
                        do {
                            let result = try await Purchases.shared.purchase(package: package)
                            if !result.userCancelled {
                                let info = result.customerInfo
                                onCustomerInfoUpdated(info)
                                if SubscriptionAccessPolicy.hasActiveProEntitlement(info.entitlements.active.keys) {
                                    onPurchaseUnlocked()
                                    return
                                }

                                Purchases.shared.invalidateCustomerInfoCache()
                                let refreshedInfo = try await Purchases.shared.customerInfo()
                                onCustomerInfoUpdated(refreshedInfo)
                                if SubscriptionAccessPolicy.hasActiveProEntitlement(refreshedInfo.entitlements.active.keys) {
                                    onPurchaseUnlocked()
                                } else {
                                    purchaseErrorMessage = TranslationManager.get("paywall.purchase.not_active", lang: language)
                                }
                            }
                        } catch {
                            purchaseErrorMessage = error.localizedDescription
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

                if let period = SubscriptionDisplayText.periodText(for: package, language: language) {
                    Text(period)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }

}

struct SubscriptionDisplayText {
    static func planName(for package: Package?, language: AppLanguage) -> String {
        guard let package else {
            return TranslationManager.get("subscription.pro_fallback", lang: language)
        }

        switch package.packageType {
        case .weekly:
            return TranslationManager.get("paywall.plan.weekly", lang: language)
        case .monthly:
            return TranslationManager.get("paywall.plan.monthly", lang: language)
        case .twoMonth:
            return TranslationManager.get("paywall.plan.two_month", lang: language)
        case .threeMonth:
            return TranslationManager.get("paywall.plan.three_month", lang: language)
        case .sixMonth:
            return TranslationManager.get("paywall.plan.six_month", lang: language)
        case .annual:
            return TranslationManager.get("paywall.plan.annual", lang: language)
        case .lifetime:
            return TranslationManager.get("paywall.plan.lifetime", lang: language)
        case .custom, .unknown:
            return TranslationManager.get("paywall.plan.standard", lang: language)
        @unknown default:
            return TranslationManager.get("paywall.plan.standard", lang: language)
        }
    }

    static func periodText(for package: Package, language: AppLanguage) -> String? {
        if let period = package.storeProduct.subscriptionPeriod {
            switch (period.unit, period.value) {
            case (.day, 1): return TranslationManager.get("paywall.period.day", lang: language)
            case (.week, 1): return TranslationManager.get("paywall.period.week", lang: language)
            case (.month, 1): return TranslationManager.get("paywall.period.month", lang: language)
            case (.year, 1): return TranslationManager.get("paywall.period.year", lang: language)
            default:
                // Fallback for multi-periods, e.g., every 3 months
                let unit: String
                switch period.unit {
                case .day: unit = TranslationManager.get("paywall.period.days", lang: language)
                case .week: unit = TranslationManager.get("paywall.period.weeks", lang: language)
                case .month: unit = TranslationManager.get("paywall.period.months", lang: language)
                case .year: unit = TranslationManager.get("paywall.period.years", lang: language)
                @unknown default: unit = TranslationManager.get("paywall.period.periods", lang: language)
                }
                return TranslationManager.get("paywall.period.every", lang: language, args: [period.value, unit])
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
