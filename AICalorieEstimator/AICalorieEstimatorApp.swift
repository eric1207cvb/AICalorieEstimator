import SwiftUI
import RevenueCat

@main
struct AICalorieEstimatorApp: App {
    // 1. 嘗試從 UserDefaults 讀取使用者上次「手動切換」的語言
    @AppStorage("user_selected_language_v2") private var savedLanguageCode: String = ""
    
    // 2. App 運行時的語言狀態
    @State private var selectedLanguage: AppLanguage = .english
    
    init() {
        // 設定 RevenueCat API Key
        Purchases.logLevel = .debug
        
        // [Fix] 已填入您提供的正確 API Key，這將解決 401 錯誤
        Purchases.configure(withAPIKey: "appl_jOygYGBHCEIfADYbuaAaxYQNdgE")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(selectedLanguage: $selectedLanguage)
                .onAppear {
                    // 🚀 App 啟動時的語言決定邏輯
                    if let saved = AppLanguage(rawValue: savedLanguageCode) {
                        // A. 如果使用者之前有手動選過，就用他選的
                        selectedLanguage = saved
                    } else {
                        // B. 如果是第一次打開 (或沒選過)，就自動偵測系統語言
                        selectedLanguage = AppLanguage.systemPreferred
                    }
                }
                .onChange(of: selectedLanguage) { _, newValue in
                    // 當使用者在 App 內切換語言時，立刻存檔
                    savedLanguageCode = newValue.rawValue
                }
        }
    }
}
