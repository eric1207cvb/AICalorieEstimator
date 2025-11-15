import SwiftUI
import RevenueCat

// 【!!! 關鍵：AppLanguage 必須在這裡定義!!!】
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case traditionalChinese = "zh-Hant"
    case japanese = "ja"
    var id: String { self.rawValue }
    var displayName: String {
        switch self {
        case .english: return "English"
        case .traditionalChinese: return "繁體中文"
        case .japanese: return "日本語"
        }
    }
}

@main
struct AICalorieEstimatorApp: App {
    // 1. 將 AppStorage 提升到 App 結構的根目錄
    @AppStorage("selectedLanguage") private var selectedLanguage: AppLanguage = .traditionalChinese
    
    // 2. 在這裡貼上你的「公開 API 金鑰」
    let REVENUECAT_API_KEY = "appl_jOygYGBHCEIfADYbuaAaxYQNdgE" // 請用你自己的金鑰替換

    init() {
        // [Init only required for Purchases config]
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: REVENUECAT_API_KEY)
    }

    var body: some Scene {
        WindowGroup {
            // 將 selectedLanguage 透過 Binding 傳遞給 ContentView
            ContentView(selectedLanguage: $selectedLanguage)
                // 3. 【關鍵修正】在最頂層注入環境變數，解決多語言切換 Bug
                .environment(\.locale, .init(identifier: selectedLanguage.rawValue))
        }
    }
}
