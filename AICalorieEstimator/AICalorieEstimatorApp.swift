import SwiftUI
import RevenueCat

@main
struct AICalorieEstimatorApp: App {
    // 1. 嘗試從 UserDefaults 讀取使用者上次「手動切換」的語言
    @AppStorage("user_selected_language_v2") private var savedLanguageCode: String = ""
    @AppStorage("user_has_selected_language_v2") private var hasUserSelectedLanguage: Bool = false

    // 2. App 運行時的語言狀態
    @State private var selectedLanguage: AppLanguage = .unitedStates
    
    init() {
        // 設定 RevenueCat API Key
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        
        Purchases.configure(withAPIKey: "appl_jOygYGBHCEIfADYbuaAaxYQNdgE")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                selectedLanguage: Binding(
                    get: { selectedLanguage },
                    set: { newValue in
                        selectedLanguage = newValue
                        savedLanguageCode = newValue.rawValue
                        hasUserSelectedLanguage = true
                    }
                )
            )
                .onAppear {
                    let resolved = AppLanguage.initialSelection(
                        savedRawValue: savedLanguageCode,
                        hasUserSelectedPreference: hasUserSelectedLanguage,
                        systemPreferred: AppLanguage.systemPreferred
                    )
                    selectedLanguage = resolved.language
                    hasUserSelectedLanguage = resolved.shouldPersistAsUserPreference
                    savedLanguageCode = resolved.shouldPersistAsUserPreference ? resolved.language.rawValue : ""
                }
        }
    }
}
