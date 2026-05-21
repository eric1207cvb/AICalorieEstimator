import Foundation
import SwiftUI

// MARK: - [Client v9.35] Data Models (Auto Language Detection)

enum API {
    static let baseURL = URL(string: "https://aicalorie-server.onrender.com")!
}

enum MealTime: String, Codable {
    case breakfast, lunch, dinner, snack
    static var current: MealTime {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return .breakfast
        case 11..<14: return .lunch
        case 17..<21: return .dinner
        default: return .snack
        }
    }
}

// 定義性別枚舉
enum UserGender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case notSet = "Not Set"

    var label: String {
        label(lang: .unitedStates)
    }

    func label(lang: AppLanguage) -> String {
        switch self {
        case .male:
            switch lang.translationBase {
            case .traditionalChinese: return "男性"
            case .japanese: return "男性"
            default: return "Male"
            }
        case .female:
            switch lang.translationBase {
            case .traditionalChinese: return "女性"
            case .japanese: return "女性"
            default: return "Female"
            }
        case .notSet:
            switch lang.translationBase {
            case .traditionalChinese: return "未設定"
            case .japanese: return "未設定"
            default: return "Not Set"
            }
        }
    }
}

enum MedicalDietMode: String, Codable, CaseIterable, Identifiable {
    case standard
    case diabetes
    case chronicKidneyDisease

    var id: String { rawValue }

    func label(lang: AppLanguage) -> String {
        switch self {
        case .standard:
            switch lang.translationBase {
            case .traditionalChinese: return "一般模式"
            case .japanese: return "標準モード"
            default: return "Standard"
            }
        case .diabetes:
            switch lang.translationBase {
            case .traditionalChinese: return "糖尿病友"
            case .japanese: return "糖尿病"
            default: return "Diabetes"
            }
        case .chronicKidneyDisease:
            switch lang.translationBase {
            case .traditionalChinese: return "慢性腎病"
            case .japanese: return "慢性腎臓病"
            default: return "CKD"
            }
        }
    }
}

enum CKDStage: String, Codable, CaseIterable, Identifiable {
    case stage1
    case stage2
    case stage3a
    case stage3b
    case stage4
    case stage5

    var id: String { rawValue }

    var isAdvanced: Bool {
        switch self {
        case .stage1, .stage2, .stage3a: return false
        case .stage3b, .stage4, .stage5: return true
        }
    }

    func label(lang: AppLanguage) -> String {
        switch self {
        case .stage1: return stageLabel("1", lang: lang)
        case .stage2: return stageLabel("2", lang: lang)
        case .stage3a: return stageLabel("3a", lang: lang)
        case .stage3b: return stageLabel("3b", lang: lang)
        case .stage4: return stageLabel("4", lang: lang)
        case .stage5: return stageLabel("5", lang: lang)
        }
    }

    private func stageLabel(_ value: String, lang: AppLanguage) -> String {
        switch lang.translationBase {
        case .traditionalChinese: return "第 \(value) 期"
        case .japanese: return "ステージ \(value)"
        default: return "Stage \(value)"
        }
    }
}

enum DiabetesStage: String, Codable, CaseIterable, Identifiable {
    case prediabetes
    case type2NonInsulin
    case insulinOrHypoglycemiaRisk
    case gestational

    var id: String { rawValue }

    func label(lang: AppLanguage) -> String {
        switch self {
        case .prediabetes:
            switch lang.translationBase {
            case .traditionalChinese: return "糖尿病前期"
            case .japanese: return "糖尿病予備群"
            default: return "Prediabetes"
            }
        case .type2NonInsulin:
            switch lang.translationBase {
            case .traditionalChinese: return "第 2 型/非胰島素"
            case .japanese: return "2型/非インスリン"
            default: return "Type 2 / non-insulin"
            }
        case .insulinOrHypoglycemiaRisk:
            switch lang.translationBase {
            case .traditionalChinese: return "胰島素或低血糖風險"
            case .japanese: return "インスリン等/低血糖リスク"
            default: return "Insulin or hypo-risk meds"
            }
        case .gestational:
            switch lang.translationBase {
            case .traditionalChinese: return "妊娠糖尿病"
            case .japanese: return "妊娠糖尿病"
            default: return "Gestational diabetes"
            }
        }
    }
}

enum ActivityScenario: String, Codable, CaseIterable, Identifiable {
    case mostlySitting
    case lightWalking
    case onFeet
    case activeTraining

    var id: String { rawValue }

    var multiplier: Double {
        switch self {
        case .mostlySitting: return 1.2
        case .lightWalking: return 1.35
        case .onFeet: return 1.5
        case .activeTraining: return 1.7
        }
    }

    var estimatedSteps: Int {
        switch self {
        case .mostlySitting: return 3_000
        case .lightWalking: return 6_000
        case .onFeet: return 9_000
        case .activeTraining: return 12_000
        }
    }

    var iconName: String {
        switch self {
        case .mostlySitting: return "chair.fill"
        case .lightWalking: return "figure.walk"
        case .onFeet: return "figure.stand"
        case .activeTraining: return "figure.run"
        }
    }

    func label(lang: AppLanguage) -> String {
        switch self {
        case .mostlySitting:
            switch lang.translationBase {
            case .traditionalChinese: return "久坐為主"
            case .japanese: return "座り仕事中心"
            default: return "Mostly sitting"
            }
        case .lightWalking:
            switch lang.translationBase {
            case .traditionalChinese: return "日常輕量走動"
            case .japanese: return "軽い日常歩行"
            default: return "Light daily walking"
            }
        case .onFeet:
            switch lang.translationBase {
            case .traditionalChinese: return "常站立走動"
            case .japanese: return "立ち仕事・よく歩く"
            default: return "Often on your feet"
            }
        case .activeTraining:
            switch lang.translationBase {
            case .traditionalChinese: return "規律運動"
            case .japanese: return "定期的に運動"
            default: return "Regular training"
            }
        }
    }

    func detail(lang: AppLanguage) -> String {
        switch self {
        case .mostlySitting:
            switch lang.translationBase {
            case .traditionalChinese: return "多數時間坐著，通勤與家務活動較少"
            case .japanese: return "座る時間が長く、通勤や家事の活動は少なめ"
            default: return "Mostly seated with limited commuting or household activity"
            }
        case .lightWalking:
            switch lang.translationBase {
            case .traditionalChinese: return "每天有通勤、家務或短時間散步"
            case .japanese: return "通勤、家事、短い散歩がある"
            default: return "Some commuting, errands, chores, or short walks"
            }
        case .onFeet:
            switch lang.translationBase {
            case .traditionalChinese: return "工作或日常經常站立、走動"
            case .japanese: return "仕事や日常で立つ・歩く時間が多い"
            default: return "Work or daily routine includes frequent standing or walking"
            }
        case .activeTraining:
            switch lang.translationBase {
            case .traditionalChinese: return "每週多次運動或訓練，日常活動量高"
            case .japanese: return "週に複数回運動し、日常活動量も高い"
            default: return "Several workouts per week plus an active routine"
            }
        }
    }
}

enum WeightGoalPreset: String, Codable, CaseIterable, Identifiable {
    case trackFirst
    case gentleLoss
    case steadyLoss
    case focusedLoss

    var id: String { rawValue }

    private var targetRatio: Double {
        switch self {
        case .trackFirst: return 1.0
        case .gentleLoss: return 0.97
        case .steadyLoss: return 0.95
        case .focusedLoss: return 0.90
        }
    }

    func targetWeight(from currentWeight: Double) -> Double {
        guard currentWeight > 0 else { return 0 }
        return (currentWeight * targetRatio * 10).rounded() / 10
    }

    func label(lang: AppLanguage) -> String {
        switch self {
        case .trackFirst:
            switch lang.translationBase {
            case .traditionalChinese: return "先記錄"
            case .japanese: return "まず記録"
            default: return "Track first"
            }
        case .gentleLoss:
            switch lang.translationBase {
            case .traditionalChinese: return "輕量減重"
            case .japanese: return "ゆるやか減量"
            default: return "Gentle loss"
            }
        case .steadyLoss:
            switch lang.translationBase {
            case .traditionalChinese: return "穩定減重"
            case .japanese: return "安定減量"
            default: return "Steady loss"
            }
        case .focusedLoss:
            switch lang.translationBase {
            case .traditionalChinese: return "明確目標"
            case .japanese: return "明確な目標"
            default: return "Focused goal"
            }
        }
    }

    func detail(lang: AppLanguage) -> String {
        switch self {
        case .trackFirst:
            switch lang.translationBase {
            case .traditionalChinese: return "目標先等於目前體重，先建立飲食紀錄"
            case .japanese: return "目標を現在体重にし、記録を先に安定"
            default: return "Set goal equal to current weight and build the record first"
            }
        case .gentleLoss:
            switch lang.translationBase {
            case .traditionalChinese: return "約 3% 目標，適合剛開始"
            case .japanese: return "約3%目標、始めたばかり向け"
            default: return "About 3% target, good for starting out"
            }
        case .steadyLoss:
            switch lang.translationBase {
            case .traditionalChinese: return "約 5% 目標，適合一般減脂"
            case .japanese: return "約5%目標、一般的な減量向け"
            default: return "About 5% target for general fat loss"
            }
        case .focusedLoss:
            switch lang.translationBase {
            case .traditionalChinese: return "約 10% 目標，之後依趨勢調整"
            case .japanese: return "約10%目標、傾向を見て調整"
            default: return "About 10% target, adjust by trend later"
            }
        }
    }
}

enum HealthDataSourceKind: String, Codable, Equatable {
    case none
    case appleWatch
    case healthConnectedDevice
    case phoneOrHealthApp

    static func classify(sourceName: String, hasSignals: Bool) -> HealthDataSourceKind {
        let source = sourceName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else { return hasSignals ? .phoneOrHealthApp : .none }
        if source.localizedCaseInsensitiveContains("watch") {
            return .appleWatch
        }
        if source.localizedCaseInsensitiveContains("iphone") ||
            source.localizedCaseInsensitiveContains("health") ||
            source.localizedCaseInsensitiveContains("健康") {
            return .phoneOrHealthApp
        }
        return .healthConnectedDevice
    }

    func label(lang: AppLanguage) -> String {
        switch self {
        case .appleWatch:
            switch lang.translationBase {
            case .traditionalChinese: return "Apple Watch"
            case .japanese: return "Apple Watch"
            default: return "Apple Watch"
            }
        case .healthConnectedDevice:
            switch lang.translationBase {
            case .traditionalChinese: return "Apple Health 連接裝置"
            case .japanese: return "Appleヘルスケア連携デバイス"
            default: return "Apple Health connected device"
            }
        case .phoneOrHealthApp:
            switch lang.translationBase {
            case .traditionalChinese: return "Apple Health 資料"
            case .japanese: return "Appleヘルスケアデータ"
            default: return "Apple Health data"
            }
        case .none:
            switch lang.translationBase {
            case .traditionalChinese: return "生活型態估算"
            case .japanese: return "生活スタイル推定"
            default: return "Lifestyle estimate"
            }
        }
    }
}

// --- 翻譯管理器 ---
struct TranslationManager {
    static func get(_ key: String, lang: AppLanguage, args: [CVarArg] = []) -> String {
        let table: [String: [AppLanguage: String]] = [
            "app.title": [.traditionalChinese: "AI 熱量估算", .english: "AI Calorie Estimator", .japanese: "AIカロリー推定"],
            "language.menu": [.traditionalChinese: "地區與語言", .english: "Region & Language", .japanese: "地域と言語"],
            "menu.manage_subscription": [.traditionalChinese: "管理訂閱", .english: "Manage Subscription", .japanese: "サブスクリプション管理"],
            "menu.restore_purchases": [.traditionalChinese: "恢復購買", .english: "Restore Purchases", .japanese: "購入を復元"],
            "state.ready_title": [.traditionalChinese: "準備分析", .english: "Ready to Analyze", .japanese: "分析準備完了"],
            "alert.error_title": [.traditionalChinese: "錯誤", .english: "Error", .japanese: "エラー"],
            "alert.ok": [.traditionalChinese: "好", .english: "OK", .japanese: "OK"],
            "alert.camera_required": [.traditionalChinese: "需要相機存取權。", .english: "Camera access required.", .japanese: "カメラへのアクセスが必要です。"],
            "footer.privacy_terms": [.traditionalChinese: "隱私權政策與條款", .english: "Privacy Policy & Terms", .japanese: "プライバシーポリシーと利用規約"],
            "footer.privacy_policy": [.traditionalChinese: "隱私權政策", .english: "Privacy Policy", .japanese: "プライバシーポリシー"],
            "footer.terms_eula": [.traditionalChinese: "使用條款 (EULA)", .english: "Terms of Use (EULA)", .japanese: "利用規約 (EULA)"],
            "data_sources.title": [.traditionalChinese: "資料來源", .english: "Data Sources", .japanese: "データソース"],
            "data_sources.description": [.traditionalChinese: "資料依目前語言在地排序，先列主要權威來源，再列輔助交叉參考。", .english: "Sources are localized by the current language, with primary authorities first and supplemental references after.", .japanese: "現在の言語に合わせ、主要な権威資料を先に、補足資料を後に表示します。"],
            "data_sources.links": [.traditionalChinese: "營養估算資料庫", .english: "Nutrition Estimate Databases", .japanese: "栄養推定データベース"],
            "data_sources.reference": [.traditionalChinese: "引用用途", .english: "Used for", .japanese: "参照した内容"],
            "data_sources.medical_references": [.traditionalChinese: "特殊飲控參考", .english: "Special Diet References", .japanese: "特別食事モードの参考資料"],
            "data_sources.medical_primary": [.traditionalChinese: "台灣優先參考", .english: "U.S./Europe Priority References", .japanese: "日本優先の参考資料"],
            "data_sources.medical_supplemental": [.traditionalChinese: "國際輔助參考", .english: "International Support", .japanese: "国際補足の参考資料"],
            "data_sources.calorie_reference": [.traditionalChinese: "用於食物熱量、份量與三大營養素估算的基礎資料比對。", .english: "Used for food calorie, portion, and macronutrient estimate cross-checks.", .japanese: "食品のカロリー、量、三大栄養素推定の照合に使用。"],
            "data_sources.nutrition_note": [.traditionalChinese: "熱量資料庫會依語言排序：台灣優先 TFND，日本優先 MEXT，英文優先 USDA。", .english: "Nutrition databases are ordered by locale: USDA first for English, TFND first for Taiwan, MEXT first for Japan.", .japanese: "栄養データベースは言語別に並びます。日本語ではMEXT、台湾ではTFND、英語ではUSDAを優先します。"],
            "data_sources.primary_note": [.traditionalChinese: "此區是目前語言的主要參考，特殊飲控建議會優先採用這些原則。", .english: "These are the main references for the current language and are prioritized in special diet guidance.", .japanese: "この区分は現在の言語で優先する主要資料で、特別食事アドバイスで先に参照します。"],
            "data_sources.supplemental_note": [.traditionalChinese: "此區用於補足與交叉檢查，不會取代本地優先來源。", .english: "These references support cross-checking and do not replace the regional priority sources.", .japanese: "この区分は補足と照合に使い、地域優先資料の代わりにはしません。"],
            "disclaimer.title": [.traditionalChinese: "免責聲明", .english: "Disclaimer", .japanese: "免責事項"],
            "disclaimer.message": [.traditionalChinese: "本應用程式提供的估算結果僅供參考，並非醫療建議。在使用任何飲食計畫前，請諮詢專業醫師。數據由 AI 模型估算。", .english: "The estimates provided by this app are for reference only and do not constitute medical advice. Please consult a professional doctor before starting any diet plan. Data is estimated by AI models.", .japanese: "本アプリの推定結果はあくまで参考であり、医療的な助言ではありません。食事計画を始める前に、必ず医師にご相談ください。データはAIモデルによって算出されています。"],
            "disclaimer.copy_all": [.traditionalChinese: "複製全文", .english: "Copy Text", .japanese: "全文をコピー"],
            "disclaimer.close": [.traditionalChinese: "關閉", .english: "Close", .japanese: "閉じる"],
            "loading.preparing": [.traditionalChinese: "AI 正在準備分析...", .english: "AI Preparing Analysis...", .japanese: "AIが分析を準備中..."],
            "hint.loading_prepare": [.traditionalChinese: "準備圖片...", .english: "Preparing image...", .japanese: "画像を準備中..."],
            "hint.loading_upload": [.traditionalChinese: "上傳影像與分析脈絡...", .english: "Uploading image and context...", .japanese: "画像と分析情報をアップロード中..."],
            "hint.loading_ai": [.traditionalChinese: "AI 正在辨識食物並生成建議...", .english: "AI is identifying food and writing guidance...", .japanese: "AIが食品を識別し、提案を作成中..."],
            "hint.loading_finalize": [.traditionalChinese: "整理估算結果...", .english: "Finalizing estimate...", .japanese: "推定結果を整理中..."],
            "hint.loading_ocr": [.traditionalChinese: "辨識圖片文字與標示...", .english: "Reading visible text and labels...", .japanese: "画像内の文字とラベルを読み取り中..."],
            "progress.detail_prepare": [.traditionalChinese: "壓縮圖片並保留可辨識細節", .english: "Compressing the image while preserving visible details", .japanese: "見える細部を保ちながら画像を圧縮しています"],
            "progress.detail_ocr": [.traditionalChinese: "檢查包裝、菜單或營養標示文字", .english: "Checking labels, menus, and visible nutrition text", .japanese: "ラベル、メニュー、栄養表示の文字を確認しています"],
            "progress.detail_upload": [.traditionalChinese: "傳送照片、語言、個人目標與安全限制", .english: "Sending photo, language, goals, and safety limits", .japanese: "写真、言語、目標、安全条件を送信しています"],
            "progress.detail_ai": [.traditionalChinese: "分辨食物、份量線索、熱量範圍與建議文字", .english: "Estimating foods, portion cues, calorie range, and guidance", .japanese: "食品、量の手がかり、カロリー範囲、提案文を推定しています"],
            "progress.detail_finalize": [.traditionalChinese: "檢查文字安全性並準備顯示", .english: "Checking response safety and preparing the result", .japanese: "応答の安全性を確認し、結果を準備しています"],
            "hint.initial": [.traditionalChinese: "準備好分析美食了嗎？", .english: "Ready to Analyze?", .japanese: "分析の準備はいいですか？"],

            "result.items_found": [.traditionalChinese: "辨識結果", .english: "Detected Food", .japanese: "検出された食品"],
            "result.calorie_estimate": [.traditionalChinese: "熱量估算", .english: "Calories", .japanese: "カロリー推定"],
            "result.ai_comment": [.traditionalChinese: "AI 分析觀點", .english: "AI Insight", .japanese: "AI分析"],
            "result.health_advice": [.traditionalChinese: "飲食建議", .english: "Health Tip", .japanese: "食事のアドバイス"],
            "result.itemized_estimate": [.traditionalChinese: "逐項熱量估算", .english: "Itemized Estimate", .japanese: "品目別推定"],
            "result.confidence": [.traditionalChinese: "信心", .english: "Confidence", .japanese: "信頼度"],
            "result.special_diet_advice": [.traditionalChinese: "特殊飲控建議", .english: "Special Diet Advice", .japanese: "特別食事アドバイス"],
            "result.medical_disclaimer": [.traditionalChinese: "此提醒不是診斷、治療或處方；不從照片或感測器測量血糖、eGFR、血鉀、血磷，不計算胰島素或藥物劑量，也不取代抽血數值與醫囑。", .english: "This is not diagnosis, treatment, or a prescription. It does not measure glucose, eGFR, potassium, or phosphorus from photos or sensors, does not calculate insulin or medication doses, and does not replace labs or clinician instructions.", .japanese: "これは診断、治療、処方ではありません。写真やセンサーから血糖、eGFR、カリウム、リンを測定せず、インスリンや薬の用量計算も行わず、検査値や医療者の指示に代わるものではありません。"],
            "result.guidance_scope": [.traditionalChinese: "使用範圍", .english: "Scope", .japanese: "利用範囲"],
            "result.authoritative_sources": [.traditionalChinese: "權威資料來源", .english: "Authoritative Sources", .japanese: "権威ある情報源"],
            "result.source_note": [.traditionalChinese: "來源依目前語言排序：先列本地權威資料，再列國際輔助資料；每個 reference 標註 App 實際引用的原則。", .english: "Sources are ordered by the current language: regional authorities first, then international support. Each reference notes the principle this app actually uses.", .japanese: "情報源は現在の言語に合わせ、地域の権威資料を先に、国際補足資料を後に表示します。各referenceはアプリが実際に参照する原則です。"],
            "result.protein": [.traditionalChinese: "蛋白質", .english: "Protein", .japanese: "タンパク質"],
            "result.carbs": [.traditionalChinese: "碳水", .english: "Carbs", .japanese: "炭水化物"],
            "result.fat": [.traditionalChinese: "脂肪", .english: "Fat", .japanese: "脂質"],

            "ring.target_title": [.traditionalChinese: "今日預算", .english: "Daily Budget", .japanese: "目安摂取量"],
            "ring.intake_title": [.traditionalChinese: "已攝取", .english: "Intake", .japanese: "摂取済み"],
            "ring.status_over": [.traditionalChinese: "超出預算", .english: "Over Budget", .japanese: "目安超過"],
            "ring.status_remain": [.traditionalChinese: "剩餘額度", .english: "Remaining", .japanese: "残り"],
            "ring.advice_over": [.traditionalChinese: "建議多動動", .english: "Move More", .japanese: "運動しましょ"],
            "ring.advice_good": [.traditionalChinese: "控制精準", .english: "On Track", .japanese: "順調です"],

            "dash.edit_title": [.traditionalChinese: "編輯身體數據", .english: "Edit Profile", .japanese: "身体データの編集"],
            "dash.edit_subtitle": [.traditionalChinese: "先設定身體資料，估算會更貼近你", .english: "Set body data first for better estimates", .japanese: "身体データを先に設定すると精度が上がります"],
            "dash.advice_header": [.traditionalChinese: "🎯 本階段指引", .english: "🎯 Stage Guide", .japanese: "🎯 今の指針"],

            "health.steps": [.traditionalChinese: "今日步數", .english: "Steps", .japanese: "歩数"],
            "health.weight_goal": [.traditionalChinese: "目標體重", .english: "Goal Weight", .japanese: "目標体重"],
            "health.coach_title": [.traditionalChinese: "每日健康指引", .english: "Daily Guide", .japanese: "健康ガイド"],
            "health.to_target": [.traditionalChinese: "距離目標還有 %.1f kg", .english: "%.1f kg to go", .japanese: "あと %.1f kg"],
            "health.maintenance_calories": [.traditionalChinese: "維持熱量", .english: "Maintenance", .japanese: "維持目安"],
            "health.daily_target": [.traditionalChinese: "今日目標", .english: "Daily Target", .japanese: "今日目標"],
            "health.goal_progress": [.traditionalChinese: "目標進度", .english: "Goal Progress", .japanese: "目標進捗"],
            "profile.gender": [.traditionalChinese: "生理性別", .english: "Sex", .japanese: "性別"],
            "profile.medical_mode": [.traditionalChinese: "特殊飲控模式", .english: "Special Diet Mode", .japanese: "特別食事モード"],
            "profile.diabetes_stage": [.traditionalChinese: "糖尿病照護階段", .english: "Diabetes Care Stage", .japanese: "糖尿病ケア段階"],
            "profile.ckd_stage": [.traditionalChinese: "慢性腎病分期", .english: "CKD Stage", .japanese: "CKDステージ"],
            "profile.medical_note": [.traditionalChinese: "飲控提醒僅供參考，請依醫師或營養師給您的個人化限制為準。", .english: "Diet reminders are informational. Follow your clinician or dietitian's personal limits.", .japanese: "食事の注意は参考情報です。医師や管理栄養士の個別指示を優先してください。"],

            "watch.title": [.traditionalChinese: "活動資料來源", .english: "Activity Data Source", .japanese: "活動データソース"],
            "watch.subtitle_synced": [.traditionalChinese: "已同步 %@", .english: "Synced %@", .japanese: "%@ 同期済み"],
            "watch.subtitle_syncing": [.traditionalChinese: "正在同步健康資料", .english: "Syncing health data", .japanese: "ヘルスケア同期中"],
            "watch.subtitle_unavailable": [.traditionalChinese: "此裝置無法使用健康資料", .english: "Health data unavailable on this device", .japanese: "このデバイスでは利用できません"],
            "watch.subtitle_failed": [.traditionalChinese: "同步失敗：%@", .english: "Sync failed: %@", .japanese: "同期失敗：%@"],
            "watch.subtitle_idle": [.traditionalChinese: "可同步 Apple Watch 或其他寫入 Apple Health 的裝置", .english: "Sync Apple Watch or other devices connected to Apple Health", .japanese: "Apple Watch またはヘルスケア連携デバイスを同期できます"],
            "watch.no_data": [.traditionalChinese: "尚未同步活動資料，會先使用生活型態估算。", .english: "No activity data synced yet. Lifestyle estimate is being used.", .japanese: "活動データ未同期のため、生活スタイル推定を使用します。"],
            "watch.active_energy": [.traditionalChinese: "活動熱量", .english: "Active Energy", .japanese: "アクティブカロリー"],
            "watch.exercise": [.traditionalChinese: "運動時間", .english: "Exercise", .japanese: "エクササイズ"],
            "watch.sleep": [.traditionalChinese: "睡眠", .english: "Sleep", .japanese: "睡眠"],
            "watch.heart_rate": [.traditionalChinese: "平均心率", .english: "Avg HR", .japanese: "平均心拍"],
            "watch.resting_hr": [.traditionalChinese: "靜息心率", .english: "Resting HR", .japanese: "安静時心拍"],
            "watch.hrv": [.traditionalChinese: "HRV", .english: "HRV", .japanese: "HRV"],
            "watch.oxygen": [.traditionalChinese: "血氧", .english: "Blood O₂", .japanese: "血中酸素"],
            "watch.respiratory": [.traditionalChinese: "呼吸率", .english: "Respiration", .japanese: "呼吸数"],
            "watch.workouts": [.traditionalChinese: "今日運動", .english: "Workouts", .japanese: "今日のワークアウト"],
            "watch.daylight": [.traditionalChinese: "日照時間", .english: "Daylight", .japanese: "日光時間"],
            "watch.effort": [.traditionalChinese: "身體負荷", .english: "Effort", .japanese: "運動負荷"],
            "watch.wrist_temp": [.traditionalChinese: "睡眠腕溫", .english: "Wrist Temp", .japanese: "手首皮膚温"],

            "chart.title": [.traditionalChinese: "近七日攝取趨勢", .english: "7-Day Trend", .japanese: "週間傾向"],
            "chart.unit": [.traditionalChinese: "大卡 (kcal)", .english: "kcal", .japanese: "kcal"],
            "chart.ok": [.traditionalChinese: "正常", .english: "OK", .japanese: "OK"],
            "chart.limit": [.traditionalChinese: "上限：%d kcal", .english: "Limit: %d kcal", .japanese: "上限: %d kcal"],
            "chart.date_axis": [.traditionalChinese: "日期", .english: "Date", .japanese: "日付"],
            "chart.calories_axis": [.traditionalChinese: "熱量", .english: "Calories", .japanese: "カロリー"],
            "chart.limit_axis": [.traditionalChinese: "上限", .english: "Limit", .japanese: "上限"],
            "button.add_to_log": [.traditionalChinese: "🍽️ 紀錄這餐", .english: "Log Meal", .japanese: "記録する"],
            "button.logged": [.traditionalChinese: "✅ 已完成紀錄", .english: "Logged", .japanese: "記録済み"],
            "button.delete_log": [.traditionalChinese: "刪除這筆紀錄", .english: "Delete This Log", .japanese: "この記録を削除"],
            "button.take_photo": [.traditionalChinese: "拍照分析", .english: "Take Photo", .japanese: "写真を撮る"],
            "button.select_album": [.traditionalChinese: "從相簿選取", .english: "Album", .japanese: "アルバム"],
            "photo.section_title": [.traditionalChinese: "餐點照片", .english: "Food Photo", .japanese: "食事写真"],
            "photo.empty_title": [.traditionalChinese: "加入餐點照片", .english: "Add a Food Photo", .japanese: "食事写真を追加"],
            "meal_log.confirm_title": [.traditionalChinese: "確認是否登入", .english: "Confirm Meal Log", .japanese: "記録するか確認"],
            "meal_log.confirm_log": [.traditionalChinese: "仍要登入", .english: "Log Anyway", .japanese: "記録する"],
            "meal_log.cancel": [.traditionalChinese: "先不要", .english: "Not Now", .japanese: "今はしない"],
            "meal_log.confirm_shared": [.traditionalChinese: "這張照片看起來像多人共享或整桌食物，估算熱量可能不是你實際吃下的一餐。要把約 %d kcal 登入今天嗎？", .english: "This looks like a shared table or multi-person spread, so the estimate may not match what you personally ate. Log about %d kcal today?", .japanese: "この写真は複数人で分ける料理や食卓全体に見えるため、あなたが実際に食べた1食分とは限りません。約 %d kcal として記録しますか？"],
            "meal_log.confirm_bulk": [.traditionalChinese: "這比較像整串、整袋、整盒或一堆食物，不一定等於一餐份量。要把約 %d kcal 登入今天嗎？", .english: "This looks like a bunch, bag, box, or pile of food rather than one meal portion. Log about %d kcal today?", .japanese: "房、袋、箱、山盛りなど、1食分とは限らない量に見えます。約 %d kcal として記録しますか？"],
            "meal_log.confirm_broad": [.traditionalChinese: "這次份量不確定性較高，熱量範圍偏寬。若這確實是你這餐吃的份量，可登入約 %d kcal。", .english: "Portion uncertainty is high and the calorie range is wide. If this is what you ate for this meal, log about %d kcal.", .japanese: "量の不確実性が高く、カロリー範囲が広めです。これが実際に食べた1食分なら、約 %d kcal として記録できます。"],
            "meal_log.confirm_ambiguous": [.traditionalChinese: "照片中有多項食物，可能是一餐，也可能是共享份量。確認這是你的食用份量後，再登入約 %d kcal。", .english: "The photo contains several foods and may be one meal or a shared portion. Confirm this is your portion before logging about %d kcal.", .japanese: "複数の食品が写っており、1食分か共有分か判断が分かれます。自分の食べた量なら、約 %d kcal として記録してください。"],
            "meal_log.delete_title": [.traditionalChinese: "刪除這筆餐食紀錄？", .english: "Delete This Meal Log?", .japanese: "この食事記録を削除しますか？"],
            "meal_log.delete_message": [.traditionalChinese: "會從今天已攝取熱量扣回這筆資料。這只刪除剛才登入的餐食，不會影響其他紀錄。", .english: "This subtracts the logged calories from today's intake. Only this meal log is deleted.", .japanese: "今日の摂取カロリーからこの分を差し引きます。削除されるのはこの食事記録だけです。"],
            "meal_log.delete_confirm": [.traditionalChinese: "刪除", .english: "Delete", .japanese: "削除"],

            "profile.title": [.traditionalChinese: "個人檔案", .english: "Profile", .japanese: "プロフィール"],
            "profile.basic_section": [.traditionalChinese: "基本身體資料", .english: "Body Basics", .japanese: "基本身体データ"],
            "profile.basic_hint": [.traditionalChinese: "身高、體重、目標與生理性別會先影響每日熱量預算。", .english: "Height, weight, goal, and sex drive the daily calorie budget.", .japanese: "身長、体重、目標、性別が1日の目安カロリーに反映されます。"],
            "profile.quick_goal": [.traditionalChinese: "快速減重目標", .english: "Quick Weight Goal", .japanese: "減量目標のクイック設定"],
            "profile.quick_goal_hint": [.traditionalChinese: "輸入目前體重後，一鍵帶入目標體重；之後仍可手動微調。", .english: "After entering current weight, apply a goal weight in one tap and adjust it anytime.", .japanese: "現在体重を入力後、目標体重をワンタップで設定し、後で調整できます。"],
            "profile.weight_first_hint": [.traditionalChinese: "先輸入目前體重，就能自動帶入快速目標。", .english: "Enter current weight first to auto-fill a quick goal.", .japanese: "先に現在体重を入力すると、クイック目標を自動入力できます。"],
            "profile.height": [.traditionalChinese: "身高", .english: "Height", .japanese: "身長"],
            "profile.weight": [.traditionalChinese: "體重", .english: "Weight", .japanese: "体重"],
            "profile.sync_health": [.traditionalChinese: "同步健康資料", .english: "Sync Health", .japanese: "ヘルスケア同期"],
            "profile.sync_health_hint": [.traditionalChinese: "從 Apple Health 補上步數、活動熱量、運動與合規裝置資料。", .english: "Use Apple Health for steps, active energy, workouts, and authorized device data.", .japanese: "Appleヘルスケアから歩数、活動カロリー、運動、連携デバイスのデータを反映します。"],

            "status.pro_active": [.traditionalChinese: "👑 專業版會員", .english: "👑 Pro Member", .japanese: "👑 有料プラン有効"],
            "status.free_remaining": [.traditionalChinese: "免費額度剩餘 %d 次", .english: "%d Free Scans Left", .japanese: "残り %d 回"],
            "status.free_exhausted": [.traditionalChinese: "免費額度已用完", .english: "Free Limit Reached", .japanese: "無料枠終了"],
            "status.upgrade_pro": [.traditionalChinese: "升級專業版", .english: "Upgrade", .japanese: "有料プランへ"],
            "status.server.unknown": [.traditionalChinese: "點擊檢查", .english: "Tap to Check", .japanese: "接続を確認"],
            "status.server.checking": [.traditionalChinese: "連線中...", .english: "Connecting...", .japanese: "接続中..."],
            "status.server.online": [.traditionalChinese: "系統正常", .english: "System Normal", .japanese: "正常稼働中"],
            "status.server.offline": [.traditionalChinese: "伺服器離線", .english: "Server Offline", .japanese: "サーバーオフライン"],
            "alert.no_credits": [.traditionalChinese: "次數已用完，請升級專業版以繼續使用。", .english: "No credits left. Please upgrade to continue.", .japanese: "回数制限です。有料プランにアップグレードしてください。"],

            "badge.deficit_title": [.traditionalChinese: "🔥 熱量赤字達成", .english: "🔥 Deficit Hit", .japanese: "🔥 カロリー赤字"],
            "badge.deficit_desc": [.traditionalChinese: "本週少攝取 %d kcal", .english: "-%d kcal this week", .japanese: "-%d kcal"],

            "paywall.title": [.traditionalChinese: "升級專業版", .english: "Upgrade to Pro", .japanese: "有料プランへアップグレード"],
            "paywall.subtitle": [.traditionalChinese: "解鎖無限次智慧分析，取得每份食物更完整的熱量估算。", .english: "Unlock unlimited AI analysis and accurate calorie counts for any food item.", .japanese: "食事分析を無制限に利用し、より詳しいカロリー推定を確認できます。"],
            "paywall.choose_plan": [.traditionalChinese: "選擇方案", .english: "Choose a plan", .japanese: "プランを選択"],
            "paywall.choose_plan_desc": [.traditionalChinese: "訂閱後即可解鎖專業版功能。", .english: "Select a subscription to unlock Pro features.", .japanese: "登録すると有料プランの機能を利用できます。"],
            "paywall.terms_title": [.traditionalChinese: "訂閱條款", .english: "Subscription terms", .japanese: "サブスクリプション条件"],
            "paywall.term.auto_renew": [.traditionalChinese: "訂閱會自動續訂，除非在目前週期結束至少 24 小時前取消。", .english: "Subscription auto-renews unless canceled at least 24 hours before the end of the current period.", .japanese: "現在の期間終了24時間前までに解約しない限り、自動更新されます。"],
            "paywall.term.manage": [.traditionalChinese: "可在 App Store 帳號設定中管理或取消訂閱。", .english: "Manage or cancel your subscription in your App Store account settings.", .japanese: "App Storeアカウント設定で管理または解約できます。"],
            "paywall.term.payment": [.traditionalChinese: "購買確認時會向您的 Apple 帳號收費。", .english: "Payment is charged to your Apple ID at confirmation of purchase.", .japanese: "購入確認時にAppleアカウントへ請求されます。"],
            "paywall.term.renewal": [.traditionalChinese: "目前週期結束前 24 小時內，帳號會被收取續訂費用。", .english: "Your account will be charged for renewal within 24 hours prior to the end of the current period.", .japanese: "現在の期間終了前24時間以内に更新料金が請求されます。"],
            "paywall.restore": [.traditionalChinese: "恢復購買", .english: "Restore Purchases", .japanese: "購入を復元"],
            "paywall.done": [.traditionalChinese: "完成", .english: "Done", .japanese: "完了"],
            "paywall.error_title": [.traditionalChinese: "購買錯誤", .english: "Purchase Error", .japanese: "購入エラー"],
            "paywall.unknown_error": [.traditionalChinese: "未知錯誤", .english: "Unknown error", .japanese: "不明なエラー"],
            "paywall.restore.no_active": [.traditionalChinese: "此 Apple 帳號找不到有效的專業版訂閱。", .english: "No active Pro subscription was found for this Apple ID.", .japanese: "このAppleアカウントに有効な有料プランが見つかりません。"],
            "paywall.purchase.not_active": [.traditionalChinese: "購買已完成，但專業版尚未啟用。請嘗試恢復購買。", .english: "Purchase completed, but Pro is not active yet. Please try Restore Purchases.", .japanese: "購入は完了しましたが、有料プランがまだ有効ではありません。購入の復元をお試しください。"],
            "paywall.simulator_unlock": [.traditionalChinese: "模擬器測試解鎖", .english: "Unlock for Simulator Test", .japanese: "シミュレータテスト解除"],
            "paywall.simulator_unlock_note": [.traditionalChinese: "僅限偵錯版模擬器測試付費後流程，正式版與實機不會出現。", .english: "Debug Simulator only. Use it to test the post-purchase flow; it is not included in release builds or on devices.", .japanese: "デバッグシミュレータ専用です。購入後の流れを確認するためのもので、正式版と実機には表示されません。"],
            "paywall.agreement": [.traditionalChinese: "訂閱即表示您同意使用條款與隱私權政策。訂閱會自動續訂，除非在目前週期結束至少 24 小時前取消。可在 App Store 帳號設定中管理或取消。", .english: "By subscribing, you agree to our Terms of Use and Privacy Policy. Subscription auto-renews unless canceled at least 24 hours before the end of the current period. Manage or cancel in your App Store account settings.", .japanese: "サブスクリプション登録により、利用規約とプライバシーポリシーに同意したものとみなされます。現在の期間終了24時間前までに解約しない限り自動更新されます。App Storeアカウント設定で管理または解約できます。"],
            "paywall.plan.weekly": [.traditionalChinese: "每週方案", .english: "Weekly Plan", .japanese: "週額プラン"],
            "paywall.plan.monthly": [.traditionalChinese: "每月方案", .english: "Monthly Plan", .japanese: "月額プラン"],
            "paywall.plan.two_month": [.traditionalChinese: "雙月方案", .english: "Two-Month Plan", .japanese: "2か月プラン"],
            "paywall.plan.three_month": [.traditionalChinese: "三個月方案", .english: "Three-Month Plan", .japanese: "3か月プラン"],
            "paywall.plan.six_month": [.traditionalChinese: "半年方案", .english: "Six-Month Plan", .japanese: "6か月プラン"],
            "paywall.plan.annual": [.traditionalChinese: "年度方案", .english: "Annual Plan", .japanese: "年額プラン"],
            "paywall.plan.lifetime": [.traditionalChinese: "永久方案", .english: "Lifetime Plan", .japanese: "買い切りプラン"],
            "paywall.plan.standard": [.traditionalChinese: "訂閱方案", .english: "Subscription Plan", .japanese: "サブスクリプションプラン"],
            "paywall.period.day": [.traditionalChinese: "每日", .english: "per day", .japanese: "1日ごと"],
            "paywall.period.week": [.traditionalChinese: "每週", .english: "per week", .japanese: "1週間ごと"],
            "paywall.period.month": [.traditionalChinese: "每月", .english: "per month", .japanese: "1か月ごと"],
            "paywall.period.year": [.traditionalChinese: "每年", .english: "per year", .japanese: "1年ごと"],
            "paywall.period.every": [.traditionalChinese: "每 %d %@", .english: "every %d %@", .japanese: "%d%@ごと"],
            "paywall.period.days": [.traditionalChinese: "天", .english: "days", .japanese: "日"],
            "paywall.period.weeks": [.traditionalChinese: "週", .english: "weeks", .japanese: "週間"],
            "paywall.period.months": [.traditionalChinese: "個月", .english: "months", .japanese: "か月"],
            "paywall.period.years": [.traditionalChinese: "年", .english: "years", .japanese: "年"],
            "paywall.period.periods": [.traditionalChinese: "週期", .english: "periods", .japanese: "期間"],

            "subscription.info_title": [.traditionalChinese: "訂閱資訊", .english: "Subscription Info", .japanese: "サブスクリプション情報"],
            "subscription.details": [.traditionalChinese: "訂閱明細", .english: "Subscription Details", .japanese: "サブスクリプション詳細"],
            "subscription.title": [.traditionalChinese: "名稱", .english: "Title", .japanese: "名称"],
            "subscription.price": [.traditionalChinese: "價格", .english: "Price", .japanese: "価格"],
            "subscription.pro_fallback": [.traditionalChinese: "專業版訂閱", .english: "Pro Subscription", .japanese: "有料プラン"],
            "subscription.legal": [.traditionalChinese: "法務資訊", .english: "Legal", .japanese: "法的情報"],
            "subscription.footer": [.traditionalChinese: "款項會在確認購買時向您的 Apple 帳號收取。訂閱會自動續訂，除非在目前週期結束至少 24 小時前取消。", .english: "Payment will be charged to your Apple ID account at the confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period.", .japanese: "購入確認時にAppleアカウントへ請求されます。現在の期間終了24時間前までに解約しない限り、サブスクリプションは自動更新されます。"],
        ]
        let marketOverrides: [String: [AppLanguage: String]] = [
            "button.select_album": [.unitedStates: "Photos"],
        ]
        let format = marketOverrides[key]?[lang] ?? table[key]?[lang.translationBase] ?? table[key]?[.english] ?? key
        return String(format: format, arguments: args)
    }
}

struct InsightResult {
    let title: String
    let advice: String
    let knowledge: String
}

enum WeightGoalDirection: Equatable {
    case maintain
    case lose
    case gain
}

struct WeightGoalProgress {
    static func progress(startWeight: Double, currentWeight: Double, targetWeight: Double) -> Double {
        guard startWeight > 0, currentWeight > 0, targetWeight > 0 else { return 0 }
        let total = abs(startWeight - targetWeight)
        guard total >= 0.5 else { return 0 }

        let direction = targetWeight < startWeight ? -1.0 : 1.0
        let moved = (currentWeight - startWeight) * direction
        return min(max(moved / total, 0), 1)
    }
}

enum HealthSyncState: Equatable {
    case idle
    case unavailable
    case requesting
    case syncing
    case synced(Date)
    case failed(String)
}

enum NutritionRiskLevel: Equatable {
    case info
    case caution
    case alert

    var color: Color {
        switch self {
        case .info: return .blue
        case .caution: return .orange
        case .alert: return .red
        }
    }

    var iconName: String {
        switch self {
        case .info: return "info.circle.fill"
        case .caution: return "exclamationmark.triangle.fill"
        case .alert: return "cross.case.fill"
        }
    }
}

struct MedicalAuthoritySource: Identifiable, Equatable {
    let title: String
    let url: URL
    let reference: String
    let priority: MedicalSourcePriority

    var id: String { "\(priority.rawValue)|\(title)|\(url.absoluteString)" }
}

enum MedicalSourcePriority: String, Equatable {
    case localizedPrimary
    case supplemental

    func label(lang: AppLanguage) -> String {
        switch lang.translationBase {
        case .traditionalChinese:
            switch self {
            case .localizedPrimary: return "本地優先"
            case .supplemental: return "國際輔助"
            }
        case .japanese:
            switch self {
            case .localizedPrimary: return "地域優先"
            case .supplemental: return "国際補足"
            }
        default:
            switch self {
            case .localizedPrimary: return "Regional priority"
            case .supplemental: return "Supplemental"
            }
        }
    }

    var iconName: String {
        switch self {
        case .localizedPrimary: return "checkmark.seal.fill"
        case .supplemental: return "globe"
        }
    }
}

struct MedicalNutritionAdvice: Equatable {
    let title: String
    let summary: String
    let focusItems: [String]
    let riskLevel: NutritionRiskLevel
    let sources: [MedicalAuthoritySource]
    let guardrails: [String]
}

enum SpecialDietFoodConcern: String, CaseIterable, Hashable {
    case highSugarOrCarb
    case refinedOrProcessedCarb
    case highPotassium
    case highPhosphorus
    case highSodium
    case highProtein

    func label(lang: AppLanguage) -> String {
        switch lang.translationBase {
        case .traditionalChinese:
            switch self {
            case .highSugarOrCarb: return "高醣或含糖食物"
            case .refinedOrProcessedCarb: return "精緻或高度加工澱粉"
            case .highPotassium: return "高鉀食物"
            case .highPhosphorus: return "高磷或磷添加物"
            case .highSodium: return "高鈉食物"
            case .highProtein: return "蛋白質份量偏高"
            }
        case .japanese:
            switch self {
            case .highSugarOrCarb: return "糖質・甘味が多い食品"
            case .refinedOrProcessedCarb: return "精製・高度加工の炭水化物"
            case .highPotassium: return "高カリウム食品"
            case .highPhosphorus: return "高リンまたはリン添加物"
            case .highSodium: return "高ナトリウム食品"
            case .highProtein: return "たんぱく質量が多め"
            }
        default:
            switch self {
            case .highSugarOrCarb: return "higher-carb or sugary foods"
            case .refinedOrProcessedCarb: return "refined or highly processed starch"
            case .highPotassium: return "high-potassium foods"
            case .highPhosphorus: return "high-phosphorus or phosphate additives"
            case .highSodium: return "high-sodium foods"
            case .highProtein: return "higher protein portion"
            }
        }
    }
}

struct SpecialDietFoodAlert: Equatable {
    let mode: MedicalDietMode
    let concerns: [SpecialDietFoodConcern]
    let riskLevel: NutritionRiskLevel

    static func make(for data: CloudResponsePayload, profile: UserProfile) -> SpecialDietFoodAlert? {
        let text = searchableText(for: data)
        let concerns: [SpecialDietFoodConcern]
        let riskLevel: NutritionRiskLevel

        switch profile.medicalDietMode {
        case .standard:
            return nil
        case .diabetes:
            let highCarbByMacro = (data.macros?.carbs ?? 0) >= 60
            let highCarbByFood = containsAny(text, keywords: diabetesCarbAndSugarKeywords)
            let processedCarbByFood = containsAny(text, keywords: processedCarbSnackKeywords)
            var detected: [SpecialDietFoodConcern] = []
            if highCarbByMacro || highCarbByFood { detected.append(.highSugarOrCarb) }
            if processedCarbByFood { detected.append(.refinedOrProcessedCarb) }
            concerns = unique(detected)
            riskLevel = .caution
        case .chronicKidneyDisease:
            var detected: [SpecialDietFoodConcern] = []
            if containsAny(text, keywords: ckdHighSodiumKeywords) { detected.append(.highSodium) }
            if containsAny(text, keywords: ckdHighPotassiumKeywords) { detected.append(.highPotassium) }
            if containsAny(text, keywords: ckdHighPhosphorusKeywords) { detected.append(.highPhosphorus) }
            if (data.macros?.protein ?? 0) >= ckdProteinSignalThreshold(for: profile.ckdStage) { detected.append(.highProtein) }
            concerns = unique(detected)
            riskLevel = profile.ckdStage.isAdvanced ? .alert : .caution
        }

        guard !concerns.isEmpty else { return nil }
        return SpecialDietFoodAlert(mode: profile.medicalDietMode, concerns: concerns, riskLevel: riskLevel)
    }

    func title(lang: AppLanguage) -> String {
        switch (mode, lang.translationBase) {
        case (.diabetes, .traditionalChinese):
            return "特殊模式提醒：留意醣量"
        case (.diabetes, .japanese):
            return "特別モード注意：糖質量を確認"
        case (.diabetes, _):
            return "Special mode alert: check carb load"
        case (.chronicKidneyDisease, .traditionalChinese):
            return "特殊模式提醒：留意礦物質與份量"
        case (.chronicKidneyDisease, .japanese):
            return "特別モード注意：ミネラルと量を確認"
        case (.chronicKidneyDisease, _):
            return "Special mode alert: check minerals and portions"
        case (.standard, .traditionalChinese):
            return "飲食提醒"
        case (.standard, .japanese):
            return "食事の注意"
        case (.standard, _):
            return "Diet alert"
        }
    }

    func message(lang: AppLanguage) -> String {
        let labels = concerns.map { $0.label(lang: lang) }.joined(separator: localizedSeparator(lang: lang))
        switch (mode, lang.translationBase) {
        case (.diabetes, .traditionalChinese):
            return "AI 辨識到可能含 \(labels)。這不是禁食建議；請留意主食、甜飲或甜點份量，搭配蛋白質與非澱粉蔬菜，並依您的血糖紀錄調整。"
        case (.diabetes, .japanese):
            return "AIが \(labels) の可能性を検出しました。禁止ではありません。主食、甘い飲み物、デザートの量を控えめにし、たんぱく質と非でんぷん野菜を組み合わせて、血糖記録に合わせて調整してください。"
        case (.diabetes, _):
            return "AI detected possible \(labels). This is not a food ban; keep starches, sweet drinks, or desserts portion-aware, pair with protein and non-starchy vegetables, and adjust based on your glucose records."
        case (.chronicKidneyDisease, .traditionalChinese):
            return "AI 辨識到可能含 \(labels)。CKD 飲食需依分期、尿量與檢驗值調整；這類食物攝取請適量，必要時以腎臟營養師建議為準。"
        case (.chronicKidneyDisease, .japanese):
            return "AIが \(labels) の可能性を検出しました。CKDの食事はステージ、尿量、検査値で変わります。この種類の食品は量に注意し、必要に応じて腎臓専門の管理栄養士の指示を優先してください。"
        case (.chronicKidneyDisease, _):
            return "AI detected possible \(labels). CKD nutrition depends on stage, urine output, and lab results; keep these foods portion-aware and follow renal dietitian guidance when available."
        case (.standard, .traditionalChinese):
            return "請依個人狀況調整攝取量。"
        case (.standard, .japanese):
            return "個人の状況に合わせて量を調整してください。"
        case (.standard, _):
            return "Adjust portions based on your individual context."
        }
    }

    func imageAccessibilityLabel(lang: AppLanguage) -> String {
        switch lang.translationBase {
        case .traditionalChinese:
            return "特殊飲控食物警示"
        case .japanese:
            return "特別食事モードの食品注意"
        default:
            return "Special diet food alert"
        }
    }

    private static func searchableText(for data: CloudResponsePayload) -> String {
        let itemText = data.itemEstimates
            .map { [$0.name, $0.portionDescription, $0.portionBasis].compactMap { $0 }.joined(separator: " ") }
            .joined(separator: " ")
        return [data.foodList, data.reasoning, data.healthTip ?? "", itemText]
            .joined(separator: " ")
            .lowercased()
    }

    private static func containsAny(_ text: String, keywords: [String]) -> Bool {
        keywords.contains { text.contains($0.lowercased()) }
    }

    private static func unique(_ concerns: [SpecialDietFoodConcern]) -> [SpecialDietFoodConcern] {
        var seen = Set<SpecialDietFoodConcern>()
        return concerns.filter { seen.insert($0).inserted }
    }

    private static func ckdProteinSignalThreshold(for stage: CKDStage) -> Int {
        switch stage {
        case .stage1, .stage2:
            return 45
        case .stage3a:
            return 40
        case .stage3b:
            return 32
        case .stage4, .stage5:
            return 25
        }
    }

    private func localizedSeparator(lang: AppLanguage) -> String {
        switch lang.translationBase {
        case .traditionalChinese, .japanese: return "、"
        default: return ", "
        }
    }

    private static let diabetesCarbAndSugarKeywords = [
        "sugar", "sweet", "dessert", "cake", "cookie", "candy", "soda", "juice", "bubble tea", "boba",
        "milk tea", "sweet tea", "frappe", "ice cream", "donut", "pastry", "white rice", "fried rice",
        "rice", "noodle", "pasta", "bread", "bun", "toast", "porridge", "congee",
        "糖", "甜", "蛋糕", "餅乾", "糖果", "汽水", "果汁", "手搖", "珍奶", "奶茶", "冰淇淋",
        "白飯", "炒飯", "飯", "麵", "麵包", "吐司", "粥",
        "砂糖", "甘い", "ケーキ", "クッキー", "ジュース", "甘い飲み物", "アイス", "白米",
        "ご飯", "麺", "ラーメン", "うどん", "そば", "パン", "トースト"
    ]

    private static let processedCarbSnackKeywords = [
        "chips", "potato chips", "crisps", "cracker", "pretzel", "snack", "instant noodle", "instant ramen",
        "breakfast cereal", "granola", "oatmeal packet", "sweetened cereal", "packaged snack", "ultra-processed",
        "洋芋片", "薯片", "餅乾", "蘇打餅", "洋芋", "零食", "泡麵", "速食麵", "即食麵", "早餐穀片", "穀片", "即食燕麥", "加工澱粉",
        "ポテトチップス", "チップス", "クラッカー", "スナック", "インスタント麺", "インスタントラーメン", "シリアル", "グラノーラ", "加工炭水化物"
    ]

    private static let ckdHighSodiumKeywords = [
        "ramen", "instant", "soup", "sauce", "soy sauce", "bacon", "ham", "sausage", "deli", "chips",
        "potato chips", "crisps", "cracker", "pickle", "fast food", "processed", "salted", "packaged snack",
        "泡麵", "拉麵", "湯", "醬", "醬油", "培根", "火腿", "香腸", "滷", "鹹酥", "洋芋片", "薯片", "餅乾", "零食", "加工", "醃",
        "ラーメン", "インスタント", "スープ", "醤油", "ソース", "ベーコン", "ハム", "ソーセージ", "ポテトチップス", "チップス", "クラッカー", "スナック", "加工", "漬物"
    ]

    private static let ckdHighPotassiumKeywords = [
        "banana", "avocado", "potato", "potato chips", "chips", "crisps", "sweet potato", "tomato", "spinach", "beans", "legumes",
        "dried fruit", "coconut water", "orange", "kiwi", "melon", "pumpkin", "taro",
        "oat", "oats", "oatmeal", "rolled oats", "granola", "cereal",
        "香蕉", "酪梨", "馬鈴薯", "洋芋", "洋芋片", "薯片", "地瓜", "番茄", "菠菜", "豆", "乾果", "椰子水", "柳橙", "橘子", "奇異果", "哈密瓜", "南瓜", "芋頭", "燕麥", "燕麥片", "穀片",
        "バナナ", "アボカド", "じゃがいも", "ポテトチップス", "チップス", "さつまいも", "トマト", "ほうれん草", "豆", "ドライフルーツ",
        "ココナッツウォーター", "オレンジ", "キウイ", "メロン", "かぼちゃ", "里芋",
        "オートミール", "オーツ", "グラノーラ", "シリアル"
    ]

    private static let ckdHighPhosphorusKeywords = [
        "cola", "cheese", "dairy", "milk", "yogurt", "organ", "liver", "nuts", "seeds",
        "processed meat", "sausage", "ham", "bacon", "phosphate", "phosphorus", "chips", "potato chips", "crisps",
        "oat", "oats", "oatmeal", "rolled oats", "granola", "cereal", "packaged snack", "ultra-processed",
        "可樂", "起司", "乳製", "牛奶", "優格", "內臟", "肝", "堅果", "種子", "加工肉", "香腸", "火腿", "培根", "磷酸鹽", "高磷", "洋芋片", "薯片", "零食", "燕麥", "燕麥片", "穀片",
        "コーラ", "チーズ", "乳製品", "牛乳", "ヨーグルト", "内臓", "レバー", "ナッツ", "種", "加工肉", "ソーセージ", "ハム", "ベーコン", "リン酸塩", "高リン", "ポテトチップス", "チップス", "スナック", "オートミール", "オーツ", "グラノーラ", "シリアル"
    ]
}

struct MedicalNutritionAdvisor {
    static func advice(for data: CloudResponsePayload, profile: UserProfile, lang: AppLanguage) -> MedicalNutritionAdvice? {
        switch profile.medicalDietMode {
        case .standard:
            return nil
        case .diabetes:
            return diabetesAdvice(for: data, stage: profile.diabetesStage, lang: lang)
        case .chronicKidneyDisease:
            return ckdAdvice(for: data, stage: profile.ckdStage, lang: lang)
        }
    }

    private static func diabetesAdvice(for data: CloudResponsePayload, stage: DiabetesStage, lang: AppLanguage) -> MedicalNutritionAdvice {
        let text = analysisText(data)
        let carbs = data.macros?.carbs ?? 0
        let hasSugarSignal = containsAny(text, keywords: [
            "sugar", "sweet", "dessert", "cake", "cookie", "candy", "soda", "juice", "bubble tea", "frappe",
            "糖", "甜", "蛋糕", "餅乾", "糖果", "汽水", "果汁", "手搖",
            "砂糖", "甘い", "ケーキ", "クッキー", "ジュース"
        ])
        let processedCarbSignal = containsAny(text, keywords: processedCarbFoodKeywords)
        let highCarb = carbs >= 60 || hasSugarSignal || processedCarbSignal
        let risk: NutritionRiskLevel = highCarb ? .caution : .info

        switch lang.translationBase {
        case .traditionalChinese:
            let stageText = stage.label(lang: lang)
            var baseFocus = highCarb ? [
                "主食先抓半份到一份，甜飲或甜點盡量二擇一或不選。",
                "先吃蔬菜與蛋白質，再吃澱粉，幫助餐後血糖更平穩。",
                "餐後血糖反應以您的血糖機或 CGM 為準。"
            ] : [
                "選擇全穀、豆類或高纖澱粉，避免精緻糖和含糖飲。",
                "每餐保留蛋白質和蔬菜，減少單吃澱粉造成的波動。",
                "份量看起來正常時，仍建議把總醣量與您的餐後血糖紀錄對照。"
            ]
            if let portionFocus = diabetesPortionFocus(for: data, carbs: carbs, lang: lang) {
                baseFocus.insert(portionFocus, at: 0)
            }
            if processedCarbSignal {
                baseFocus.insert("AI 辨識到精緻或高度加工澱粉/零食；即使單份醣量不高，也容易因份量累積影響熱量與餐後血糖，請小份量食用並避免取代正餐。", at: 0)
            }
            let summaryLead: String
            if processedCarbSignal {
                summaryLead = "AI 辨識到這餐可能含精緻或高度加工澱粉/零食。建議先確認份量與總醣量，搭配蛋白質和非澱粉蔬菜，並依您的血糖監測計畫追蹤。"
            } else if highCarb {
                summaryLead = "AI 辨識到此餐可能含較多澱粉、糖或甜飲。建議先減量主食與甜飲，搭配蛋白質和非澱粉蔬菜，並依您的血糖監測計畫追蹤。"
            } else {
                summaryLead = "這餐未出現明顯高糖訊號，但仍建議估算總醣量，優先選擇高纖、少加工的澱粉來源。"
            }
            return MedicalNutritionAdvice(
                title: highCarb ? "\(stageText) 飲控：這餐可能偏高醣" : "\(stageText) 飲控：注意醣量與搭配",
                summary: summaryLead + " " + diabetesStageSummary(stage, lang: lang),
                focusItems: baseFocus + diabetesStageFocusItems(stage, lang: lang),
                riskLevel: risk,
                sources: diabetesSources(lang: lang, stage: stage),
                guardrails: medicalGuardrails(lang: lang)
            )
        case .japanese, .japan:
            let stageText = stage.label(lang: lang)
            var baseFocus = highCarb ? [
                "主食は少なめにし、甘い飲み物やデザートは重ねない。",
                "野菜とたんぱく質を先に食べ、その後に炭水化物を食べる。",
                "食後反応は血糖測定またはCGMの値を優先する。"
            ] : [
                "全粒穀物、豆類、高繊維の炭水化物を選ぶ。",
                "炭水化物だけで食べず、たんぱく質と野菜を組み合わせる。",
                "量が通常に見えても、総炭水化物量と食後血糖の記録を照合する。"
            ]
            if let portionFocus = diabetesPortionFocus(for: data, carbs: carbs, lang: lang) {
                baseFocus.insert(portionFocus, at: 0)
            }
            if processedCarbSignal {
                baseFocus.insert("AIが精製・高度加工の炭水化物やスナックを検出しました。1回量が少なく見えても量が増えやすいため、小分けにし、食事の代わりにしないでください。", at: 0)
            }
            let summaryLead: String
            if processedCarbSignal {
                summaryLead = "AIは、この食事に精製・高度加工の炭水化物やスナックが含まれる可能性を検出しました。量と総炭水化物量を確認し、たんぱく質と非でんぷん野菜を合わせてください。"
            } else if highCarb {
                summaryLead = "AIは、この食事に主食・糖分・甘い飲み物が多い可能性を検出しました。主食と甘い飲み物を控えめにし、たんぱく質と非でんぷん野菜を合わせてください。"
            } else {
                summaryLead = "明らかな高糖質シグナルは少なめですが、総炭水化物量を見積もり、食物繊維の多い未加工の炭水化物を優先してください。"
            }
            return MedicalNutritionAdvice(
                title: highCarb ? "\(stageText): 糖質が多めの可能性" : "\(stageText): 糖質量と組み合わせを確認",
                summary: summaryLead + " " + diabetesStageSummary(stage, lang: lang),
                focusItems: baseFocus + diabetesStageFocusItems(stage, lang: lang),
                riskLevel: risk,
                sources: diabetesSources(lang: lang, stage: stage),
                guardrails: medicalGuardrails(lang: lang)
            )
        default:
            let stageText = stage.label(lang: lang)
            var baseFocus = highCarb ? [
                "Keep starch to a measured portion and avoid stacking sweet drinks with dessert.",
                "Eat vegetables and protein before starch to support steadier post-meal glucose.",
                "Use your glucose meter or CGM response as the final guide."
            ] : [
                "Choose whole grains, legumes, or high-fiber carbs over refined sugar.",
                "Pair carbs with protein and vegetables instead of eating starch alone.",
                "Even when portions look ordinary, compare total carbs with your usual post-meal glucose pattern."
            ]
            if let portionFocus = diabetesPortionFocus(for: data, carbs: carbs, lang: lang) {
                baseFocus.insert(portionFocus, at: 0)
            }
            if processedCarbSignal {
                baseFocus.insert("AI detected refined or highly processed starch/snack foods; even when one serving looks small, portions can accumulate quickly, so keep it measured and do not use it as a meal replacement.", at: 0)
            }
            let summaryLead: String
            if processedCarbSignal {
                summaryLead = "AI detected refined or highly processed starch/snack foods. Check the portion and total carbs, pair with protein and non-starchy vegetables, and compare with your glucose plan."
            } else if highCarb {
                summaryLead = "AI detected a meal that may be heavier in starch, sugar, or sweet drinks. Consider reducing the carb portion, pairing it with protein and non-starchy vegetables, and checking glucose according to your plan."
            } else {
                summaryLead = "No strong high-sugar signal was detected, but estimate total carbohydrates and prefer fiber-rich, minimally processed carb sources."
            }
            return MedicalNutritionAdvice(
                title: highCarb ? "\(stageText): likely higher-carb meal" : "\(stageText): check carbs and pairing",
                summary: summaryLead + " " + diabetesStageSummary(stage, lang: lang),
                focusItems: baseFocus + diabetesStageFocusItems(stage, lang: lang),
                riskLevel: risk,
                sources: diabetesSources(lang: lang, stage: stage),
                guardrails: medicalGuardrails(lang: lang)
            )
        }
    }

    private static func diabetesStageSummary(_ stage: DiabetesStage, lang: AppLanguage) -> String {
        switch lang.translationBase {
        case .traditionalChinese:
            switch stage {
            case .prediabetes:
                return "目前以降低精緻糖、含糖飲與過量熱量為主，搭配體重與活動管理；照片不能用來判定是否已進展為糖尿病。"
            case .type2NonInsulin:
                return "重點是穩定每餐總醣量、提高纖維與規律用餐，並把建議和您的血糖紀錄對齊。"
            case .insulinOrHypoglycemiaRisk:
                return "若正在使用胰島素或易低血糖藥物，請依醫囑核對醣量與血糖，不要用本 App 調整劑量或自行少吃一餐。"
            case .gestational:
                return "孕期控糖需兼顧胎兒營養與餐後血糖，請依產科、醫師或營養師的餐次與醣量安排調整。"
            }
        case .japanese, .japan:
            switch stage {
            case .prediabetes:
                return "精製糖、甘い飲み物、過剰なエネルギーを減らし、体重と活動量の管理を優先します。写真から糖尿病への進行判定はできません。"
            case .type2NonInsulin:
                return "毎食の総炭水化物量、食物繊維、規則的な食事を整え、血糖記録と照合してください。"
            case .insulinOrHypoglycemiaRisk:
                return "インスリン等を使用中の場合は医療者の指示に従い、アプリで用量調整や欠食を判断しないでください。"
            case .gestational:
                return "妊娠中は胎児の栄養と食後血糖の両方が重要です。産科医、主治医、管理栄養士の食事計画を優先してください。"
            }
        default:
            switch stage {
            case .prediabetes:
                return "Focus on reducing refined sugar, sweet drinks, and excess calories while supporting weight and activity goals; a photo cannot determine progression to diabetes."
            case .type2NonInsulin:
                return "Keep total carbs consistent, build in fiber, and compare the advice with your own glucose records."
            case .insulinOrHypoglycemiaRisk:
                return "If you use insulin or hypoglycemia-risk medicines, follow your clinician's carb and glucose plan; do not use this app to adjust doses or skip meals."
            case .gestational:
                return "Pregnancy nutrition must balance fetal nutrition with post-meal glucose; follow your obstetric, clinician, or dietitian meal plan."
            }
        }
    }

    private static func diabetesStageFocusItems(_ stage: DiabetesStage, lang: AppLanguage) -> [String] {
        switch lang.translationBase {
        case .traditionalChinese:
            switch stage {
            case .prediabetes:
                return ["把含糖飲換成水或無糖茶，點心以水果原形、乳品或堅果少量取代甜點。"]
            case .type2NonInsulin:
                return ["若這餐澱粉較多，下一步不是禁食，而是調整下一餐主食份量並觀察餐後血糖。"]
            case .insulinOrHypoglycemiaRisk:
                return ["請用您的醫療團隊教的醣量估算法核對；AI 只提醒食物風險，不計算胰島素或藥量。"]
            case .gestational:
                return ["避免自行極端低醣；若早餐後血糖常高，請把早餐安排和產科或營養師討論。"]
            }
        case .japanese, .japan:
            switch stage {
            case .prediabetes:
                return ["甘い飲み物は水や無糖茶に替え、間食は少量の果物、乳製品、ナッツなどに寄せる。"]
            case .type2NonInsulin:
                return ["炭水化物が多い食事の後も欠食ではなく、次の食事量と食後血糖の記録で調整する。"]
            case .insulinOrHypoglycemiaRisk:
                return ["医療チームから教わったカーボカウントで確認してください。AIは食事リスク表示のみで、薬剤量は計算しません。"]
            case .gestational:
                return ["極端な低糖質は自己判断で行わず、朝食後血糖が高い場合は産科や管理栄養士に相談する。"]
            }
        default:
            switch stage {
            case .prediabetes:
                return ["Replace sweet drinks with water or unsweetened tea; use small portions of whole fruit, dairy, or nuts instead of dessert-style snacks."]
            case .type2NonInsulin:
                return ["If this meal is carb-heavy, do not compensate by fasting; adjust the next meal's starch portion and compare with post-meal glucose."]
            case .insulinOrHypoglycemiaRisk:
                return ["Use the carb-counting method taught by your care team; AI flags food risk only and does not calculate insulin or medicine doses."]
            case .gestational:
                return ["Avoid extreme carb restriction on your own; if breakfast glucose often runs high, review breakfast timing and portions with obstetric or nutrition care."]
            }
        }
    }

    private static func ckdAdvice(for data: CloudResponsePayload, stage: CKDStage, lang: AppLanguage) -> MedicalNutritionAdvice {
        let text = analysisText(data)
        let protein = data.macros?.protein ?? 0
        let processedCarbSignal = containsAny(text, keywords: processedCarbFoodKeywords)
        let oatSignal = containsAny(text, keywords: oatMineralKeywords)
        let potatoSnackSignal = containsAny(text, keywords: potatoSnackKeywords)
        let sodiumSignal = containsAny(text, keywords: ckdSodiumFoodKeywords) || processedCarbSignal
        let potassiumSignal = containsAny(text, keywords: ckdPotassiumFoodKeywords) || oatSignal || potatoSnackSignal
        let phosphorusSignal = containsAny(text, keywords: ckdPhosphorusFoodKeywords) || processedCarbSignal || oatSignal
        let highProtein = protein >= ckdProteinSignalThreshold(for: stage)
        let risk: NutritionRiskLevel = (stage.isAdvanced && (sodiumSignal || potassiumSignal || phosphorusSignal || highProtein)) ? .alert : ((sodiumSignal || potassiumSignal || phosphorusSignal || highProtein) ? .caution : .info)

        switch lang.translationBase {
        case .traditionalChinese:
            var focus = ckdStageFocusItems(stage, lang: lang)
            if let portionFocus = ckdPortionFocus(for: data, protein: protein, lang: lang) { focus.append(portionFocus) }
            if processedCarbSignal { focus.append("AI 辨識到高度加工澱粉或包裝零食訊號；這類食物常同時有鈉、磷添加物或較高熱量，CKD 模式下建議小份量，並查看鈉與含「磷/PHOS」的成分標示。") }
            if oatSignal { focus.append("AI 辨識到燕麥/穀片類訊號；燕麥本身可含較多磷與鉀，請依 CKD 分期、血鉀、血磷與營養師目標調整份量。") }
            if potassiumSignal { focus.append("此餐可能有高鉀食材訊號；若您的鉀偏高，請縮小份量或替換。") }
            if phosphorusSignal { focus.append("此餐可能有高磷或磷添加物訊號；加工食品和可樂要特別確認標示。") }
            if highProtein { focus.append("蛋白質估算偏高；未洗腎者請與腎臟營養師確認每日蛋白質目標。") }
            return MedicalNutritionAdvice(
                title: "CKD \(stage.label(lang: lang)) 飲控提醒",
                summary: ckdStageSummary(stage, hasRiskSignal: risk != .info, lang: lang),
                focusItems: focus,
                riskLevel: risk,
                sources: ckdSources(lang: lang),
                guardrails: medicalGuardrails(lang: lang)
            )
        case .japanese, .japan:
            var focus = ckdStageFocusItems(stage, lang: lang)
            if let portionFocus = ckdPortionFocus(for: data, protein: protein, lang: lang) { focus.append(portionFocus) }
            if processedCarbSignal { focus.append("AIが高度加工の炭水化物や包装スナックを検出しました。ナトリウム、リン添加物、エネルギーが重なりやすいため、CKDモードでは少量にし、ナトリウムと「リン/PHOS」表示を確認してください。") }
            if oatSignal { focus.append("AIがオートミール/シリアル系を検出しました。オーツはリンとカリウムを含むため、CKDステージ、血清カリウム、リン、管理栄養士の目標に合わせて量を調整してください。") }
            if potassiumSignal { focus.append("高カリウム食材の可能性があります。血清カリウムが高い場合は量を控えるか代替を。") }
            if phosphorusSignal { focus.append("高リンまたはリン添加物の可能性があります。加工食品やコーラは表示確認を。") }
            if highProtein { focus.append("たんぱく質が多めの推定です。透析前の場合は腎臓専門の栄養士に目標量を確認。") }
            return MedicalNutritionAdvice(
                title: "CKD \(stage.label(lang: lang)) 食事チェック",
                summary: ckdStageSummary(stage, hasRiskSignal: risk != .info, lang: lang),
                focusItems: focus,
                riskLevel: risk,
                sources: ckdSources(lang: lang),
                guardrails: medicalGuardrails(lang: lang)
            )
        default:
            var focus = ckdStageFocusItems(stage, lang: lang)
            if let portionFocus = ckdPortionFocus(for: data, protein: protein, lang: lang) { focus.append(portionFocus) }
            if processedCarbSignal { focus.append("AI detected highly processed starch or packaged snack signals; these often combine sodium, phosphate additives, or higher calories, so keep portions small and check sodium plus ingredients containing phosphorus or PHOS.") }
            if oatSignal { focus.append("AI detected oats or cereal-type foods; oats can contribute meaningful phosphorus and potassium, so adjust portions by CKD stage, potassium/phosphorus labs, and renal dietitian targets.") }
            if potassiumSignal { focus.append("Possible high-potassium ingredients detected; reduce or swap if your potassium runs high.") }
            if phosphorusSignal { focus.append("Possible phosphorus or phosphate-additive signal detected; check labels on processed foods and cola.") }
            if highProtein { focus.append("Estimated protein is high; if not on dialysis, confirm your daily protein target with a renal dietitian.") }
            return MedicalNutritionAdvice(
                title: "CKD \(stage.label(lang: lang)) diet check",
                summary: ckdStageSummary(stage, hasRiskSignal: risk != .info, lang: lang),
                focusItems: focus,
                riskLevel: risk,
                sources: ckdSources(lang: lang),
                guardrails: medicalGuardrails(lang: lang)
            )
        }
    }

    private static func diabetesPortionFocus(for data: CloudResponsePayload, carbs: Int, lang: AppLanguage) -> String? {
        let itemText = itemizedPortionSummary(for: data, lang: lang)
        switch lang.translationBase {
        case .traditionalChinese:
            if let itemText {
                return "份量核對：AI 目前拆分為 \(itemText)。糖尿病模式下請先確認這是否為實際吃下份量；若只是整包、整盒或多人份，請按實際比例調整紀錄。"
            }
            guard carbs > 0 else { return nil }
            return "份量核對：本次估算總醣約 \(carbs)g；若照片不是一人實際吃完的份量，請先換算實際比例再記錄。"
        case .japanese, .japan:
            if let itemText {
                return "量の確認：AIは現在 \(itemText) と分解しています。糖尿病モードでは、これが実際に食べる量か確認し、袋全体・箱全体・複数人分なら実際の割合で調整してください。"
            }
            guard carbs > 0 else { return nil }
            return "量の確認：総炭水化物は約 \(carbs)g の推定です。写真が一人で食べる量ではない場合は、実際の割合に直して記録してください。"
        default:
            if let itemText {
                return "Portion check: AI currently split this into \(itemText). In diabetes mode, confirm this is the amount you will actually eat; if it is a whole bag, box, or shared portion, adjust the log by your actual fraction."
            }
            guard carbs > 0 else { return nil }
            return "Portion check: estimated total carbs are about \(carbs)g; if the photo is not the amount you actually ate, adjust the log by your real portion."
        }
    }

    private static func ckdPortionFocus(for data: CloudResponsePayload, protein: Int, lang: AppLanguage) -> String? {
        let itemText = itemizedPortionSummary(for: data, lang: lang)
        switch lang.translationBase {
        case .traditionalChinese:
            if let itemText {
                return "份量核對：AI 目前拆分為 \(itemText)。CKD 模式下鈉、鉀、磷與蛋白質風險會隨份量放大；若只吃其中一部分，請按實際比例調整。"
            }
            guard protein > 0 else { return nil }
            return "份量核對：本次蛋白質估算約 \(protein)g；CKD 模式下請把這個數字和實際吃下比例、分期與營養師目標一起看。"
        case .japanese, .japan:
            if let itemText {
                return "量の確認：AIは現在 \(itemText) と分解しています。CKDモードではナトリウム、カリウム、リン、たんぱく質の注意度が量で変わるため、実際に食べる割合で調整してください。"
            }
            guard protein > 0 else { return nil }
            return "量の確認：たんぱく質は約 \(protein)g の推定です。CKDモードでは実際に食べる割合、ステージ、管理栄養士の目標と合わせて見てください。"
        default:
            if let itemText {
                return "Portion check: AI currently split this into \(itemText). In CKD mode, sodium, potassium, phosphorus, and protein concerns scale with portion size; adjust by the fraction you actually eat."
            }
            guard protein > 0 else { return nil }
            return "Portion check: estimated protein is about \(protein)g; in CKD mode, compare this with the portion you actually eat, your stage, and renal dietitian targets."
        }
    }

    private static func itemizedPortionSummary(for data: CloudResponsePayload, lang: AppLanguage) -> String? {
        let parts = data.itemEstimates.prefix(3).map { item -> String in
            let name = item.safeName(language: lang)
            let portion = item.safePortionDescription.map { " \($0)" } ?? ""
            let basis = item.safePortionBasis.map { " [\($0)]" } ?? ""
            return "\(name)\(portion) (\(item.caloriesMin)-\(item.caloriesMax) kcal)\(basis)"
        }
        guard !parts.isEmpty else { return nil }
        switch lang.translationBase {
        case .traditionalChinese, .japanese:
            return parts.joined(separator: "；")
        default:
            return parts.joined(separator: "; ")
        }
    }

    private static func ckdProteinSignalThreshold(for stage: CKDStage) -> Int {
        switch stage {
        case .stage1, .stage2:
            return 45
        case .stage3a:
            return 40
        case .stage3b:
            return 32
        case .stage4, .stage5:
            return 25
        }
    }

    private static func ckdStageSummary(_ stage: CKDStage, hasRiskSignal: Bool, lang: AppLanguage) -> String {
        switch lang.translationBase {
        case .traditionalChinese:
            let base: String
            switch stage {
            case .stage1, .stage2:
                base = "早期 CKD 多先從少鹽、少加工、規律追蹤血壓、血糖與尿蛋白開始；通常不自行限制鉀、磷。"
            case .stage3a:
                base = "第 3a 期開始更需要把 eGFR、尿蛋白、血鉀與血磷納入飲食回顧，避免高蛋白或高鈉飲食。"
            case .stage3b:
                base = "第 3b 期建議建立個人化蛋白質、鈉與外食策略，鉀、磷是否限制應看檢驗值。"
            case .stage4:
                base = "第 4 期需更密切對照抽血數值、尿量與腎臟營養師建議，優先管理鈉、蛋白質與磷酸鹽添加物。"
            case .stage5:
                base = "第 5 期飲食會因是否透析、尿量與治療計畫差異很大，請以腎臟團隊的個人化目標為準。"
            }
            return hasRiskSignal ? base + " AI 偵測到這餐可能有鈉、鉀、磷或蛋白質風險，建議把份量與下次檢驗紀錄對照。" : base
        case .japanese, .japan:
            let base: String
            switch stage {
            case .stage1, .stage2:
                base = "早期CKDでは減塩、加工食品を控えること、血圧・血糖・尿蛋白の定期確認が中心です。カリウムやリンは自己判断で制限しません。"
            case .stage3a:
                base = "ステージ3aではeGFR、尿蛋白、血清カリウム、リンを食事の振り返りに加え、高たんぱく・高ナトリウムを避けます。"
            case .stage3b:
                base = "ステージ3bでは、たんぱく質、ナトリウム、外食の選び方を腎臓専門の栄養指導で個別化します。カリウム・リン制限は検査値に基づきます。"
            case .stage4:
                base = "ステージ4では検査値、尿量、腎臓専門チームの方針に合わせ、ナトリウム、たんぱく質、リン酸塩添加物を優先して確認します。"
            case .stage5:
                base = "ステージ5の食事は透析の有無、尿量、治療計画で大きく変わります。腎臓チームの個別目標を優先してください。"
            }
            return hasRiskSignal ? base + " この食事にはナトリウム、カリウム、リン、たんぱく質の注意シグナルがあります。" : base
        default:
            let base: String
            switch stage {
            case .stage1, .stage2:
                base = "Earlier CKD usually starts with lower sodium, fewer ultraprocessed foods, and steady follow-up of blood pressure, glucose, and albuminuria; do not self-restrict potassium or phosphorus."
            case .stage3a:
                base = "Stage 3a benefits from reviewing eGFR, albuminuria, potassium, and phosphorus alongside meals, while avoiding high-protein or high-sodium patterns."
            case .stage3b:
                base = "Stage 3b should use individualized protein, sodium, and eating-out strategies; potassium and phosphorus limits depend on labs."
            case .stage4:
                base = "Stage 4 needs closer alignment with labs, urine output, and renal dietitian guidance, prioritizing sodium, protein portions, and phosphate additives."
            case .stage5:
                base = "Stage 5 nutrition varies greatly by dialysis status, urine output, and treatment plan; follow kidney-team targets rather than generic rules."
            }
            return hasRiskSignal ? base + " AI detected possible sodium, potassium, phosphorus, or protein concerns to compare with your lab-guided plan." : base
        }
    }

    private static func ckdStageFocusItems(_ stage: CKDStage, lang: AppLanguage) -> [String] {
        switch lang.translationBase {
        case .traditionalChinese:
            var focus = ["鈉是各期 CKD 都要優先注意的項目；醬汁、湯品、加工肉與泡麵建議減量。"]
            switch stage {
            case .stage1:
                focus.append("第 1 期以保護腎功能為目標：外食少湯少醬，蛋白質維持正常份量，不採高蛋白增肌法。")
            case .stage2:
                focus.append("第 2 期可建立固定餐盤：半盤蔬菜、適量主食與掌心蛋白質，並追蹤血壓、血糖和尿蛋白。")
            case .stage3a:
                focus.append("第 3a 期開始把加工食品、含磷添加物與大份量肉類列入檢查清單。")
            case .stage3b:
                focus.append("第 3b 期建議和腎臟營養師確認每日蛋白質與鈉目標，避免自行大幅限食。")
            case .stage4:
                focus.append("第 4 期請把每餐蛋白質、高鉀食材與高磷加工品和抽血結果對照調整。")
            case .stage5:
                focus.append("第 5 期若未透析，請避免自行採用透析飲食或極端限制；若已透析，蛋白質目標需另依透析團隊設定。")
            }
            if stage.isAdvanced {
                focus.append("避免使用高鉀鹽或低鈉鹽，包裝食品請看磷酸鹽添加物。")
            }
            return focus
        case .japanese, .japan:
            var focus = ["CKDでは全ステージでナトリウムに注意。ソース、汁物、加工肉、インスタント食品は控えめに。"]
            switch stage {
            case .stage1:
                focus.append("ステージ1は腎機能を守る段階です。外食は汁・たれを控え、たんぱく質は通常量にし高たんぱく法は避けます。")
            case .stage2:
                focus.append("ステージ2では、野菜、適量の主食、手のひら量のたんぱく質を基本に、血圧・血糖・尿蛋白を確認します。")
            case .stage3a:
                focus.append("ステージ3aからは加工食品、リン添加物、大盛りの肉類を確認リストに入れます。")
            case .stage3b:
                focus.append("ステージ3bでは、たんぱく質とナトリウムの目標を腎臓専門の栄養士と確認し、極端な制限は避けます。")
            case .stage4:
                focus.append("ステージ4では、毎食のたんぱく質、高カリウム食品、高リン加工食品を検査値と照合します。")
            case .stage5:
                focus.append("ステージ5では透析の有無で目標が変わります。未透析で透析食を自己判断で始めたり、極端に制限したりしないでください。")
            }
            if stage.isAdvanced {
                focus.append("高カリウムの代替塩を避け、加工食品はリン酸塩添加物を確認。")
            }
            return focus
        default:
            var focus = ["Sodium is a priority across CKD stages; reduce sauces, soups, processed meats, instant noodles, and salty packaged foods."]
            switch stage {
            case .stage1:
                focus.append("Stage 1 focuses on protecting kidney function: choose less sauce and broth when eating out, keep protein moderate, and avoid high-protein bulking plans.")
            case .stage2:
                focus.append("Stage 2 can use a steady plate pattern: vegetables, measured starch, and palm-sized protein while tracking blood pressure, glucose, and albuminuria.")
            case .stage3a:
                focus.append("Stage 3a adds closer checks for processed foods, phosphate additives, and oversized meat portions.")
            case .stage3b:
                focus.append("Stage 3b should confirm daily protein and sodium targets with a renal dietitian and avoid self-imposed severe restriction.")
            case .stage4:
                focus.append("Stage 4 should compare each meal's protein, high-potassium foods, and high-phosphorus processed foods with lab results.")
            case .stage5:
                focus.append("Stage 5 targets differ by dialysis status; if not on dialysis, do not self-start a dialysis diet or extreme restrictions.")
            }
            if stage.isAdvanced {
                focus.append("Avoid high-potassium salt substitutes and check packaged foods for phosphate additives.")
            }
            return focus
        }
    }

    private static func diabetesSources(lang: AppLanguage, stage: DiabetesStage? = nil) -> [MedicalAuthoritySource] {
        var sources: [MedicalAuthoritySource]
        switch lang.translationBase {
        case .traditionalChinese:
            sources = [
                source("衛生福利部國民健康署 糖尿病防治", "https://www.hpa.gov.tw/Pages/List.aspx?nodeid=359", reference: "台灣優先引用：糖尿病防治衛教架構，將建議限定在均衡飲食、規律追蹤與醫療團隊個別化照護。"),
                source("衛生福利部國民健康署 糖尿病與我", "https://health99.hpa.gov.tw/material/3404", reference: "台灣優先引用：固定醣量、高纖、適量油脂、體重控制與血糖自我監測等一般自我管理原則。")
            ]
        case .japanese:
            sources = [
                source("日本糖尿病学会 糖尿病診療ガイドライン2024", "https://www.jds.or.jp/modules/publication/index.php?content_id=40", reference: "日本優先参照：食事療法、血糖管理、低血糖リスク時は医療者の指示を優先する考え方を参照。"),
                source("糖尿病情報センター 食事のはなし", "https://dmic.jihs.go.jp/general/about-dm/040/020/02-1.html", reference: "日本優先参照：適正エネルギー、バランスのよい規則的な食事、食べてはいけない食品を決めつけない姿勢を参照。")
            ]
        default:
            sources = [
                source("ADA Standards of Care in Diabetes", "https://professional.diabetes.org/standards-of-care", reference: "U.S. priority reference: evidence-based diabetes care scope and individualized nutrition guidance without diagnosis or medication dosing."),
                source("CDC Diabetes Meal Planning", "https://www.cdc.gov/diabetes/healthy-eating/diabetes-meal-planning.html", reference: "U.S. priority reference: plate method, carb counting, portion awareness, and regular balanced meals as general guidance."),
                source("NICE Type 2 Diabetes Dietary Advice", "https://www.nice.org.uk/guidance/ng28/chapter/Dietary-advice-and-interventions", reference: "European priority reference: individualized, culturally sensitive nutrition advice from qualified professionals.")
            ]
        }
        switch stage {
        case .prediabetes?:
            switch lang.translationBase {
            case .traditionalChinese:
                sources.append(source("衛生福利部國民健康署 顧血糖4招", "https://www.hpa.gov.tw/Pages/Detail.aspx?nodeid=4878&pid=19042", reference: "台灣優先引用：糖尿病前期以均衡飲食、每週活動與風險追蹤作為生活型態支持。"))
            case .japanese:
                sources.append(source("糖尿病情報センター 糖尿病は早く見つけましょう", "https://dmic.jihs.go.jp/general/about-dm/030/010/01.html", reference: "日本優先参照：糖尿病予備群では生活習慣の見直しと健診・検査による確認を参照。"))
            default:
                sources.append(source("ADA Standards: Prevention or Delay of Diabetes", "https://professional.diabetes.org/standards-of-care", reference: "U.S. priority reference: prediabetes stage uses lifestyle-support framing and avoids diagnosing progression from images."))
            }
        case .gestational?:
            switch lang.translationBase {
            case .traditionalChinese:
                sources.append(source("衛生福利部國民健康署 妊娠糖尿病", "https://www.hpa.gov.tw/Pages/Detail.aspx?nodeid=4809&pid=17945", reference: "台灣優先引用：妊娠糖尿病需產檢、孕期控糖與孕期營養專業照護。"))
            case .japanese:
                sources.append(source("糖尿病情報センター 妊娠と糖尿病", "https://dmic.jihs.go.jp/general/about-dm/080/030/13.html", reference: "日本優先参照：妊娠中は産科・糖尿病チームの食事計画を優先し、極端な制限を避ける原則を参照。"))
            default:
                sources.append(source("CDC Gestational Diabetes", "https://www.cdc.gov/diabetes/about/gestational-diabetes.html", reference: "U.S. priority reference: gestational stage uses prenatal follow-up and clinician-led meal planning boundaries."))
            }
        case .insulinOrHypoglycemiaRisk?:
            let priority: MedicalSourcePriority = lang.translationBase == .english ? .localizedPrimary : .supplemental
            sources.append(source("ADA Standards: Glycemic Goals and Hypoglycemia", "https://professional.diabetes.org/standards-of-care", reference: "Insulin or hypo-risk stage uses carb-awareness and glucose-plan reminders, with no insulin or medicine dose calculation.", priority: priority))
        default:
            break
        }
        sources.append(contentsOf: diabetesSupplementalSources(lang: lang))
        return sources
    }

    private static func diabetesSupplementalSources(lang: AppLanguage) -> [MedicalAuthoritySource] {
        switch lang.translationBase {
        case .traditionalChinese:
            return [
                source("ADA Standards of Care in Diabetes", "https://professional.diabetes.org/standards-of-care", reference: "國際輔助引用：個人化營養照護、避免診斷與藥物劑量建議。", priority: .supplemental),
                source("CDC Diabetes Meal Planning", "https://www.cdc.gov/diabetes/healthy-eating/diabetes-meal-planning.html", reference: "國際輔助引用：餐盤法、醣量估算、份量意識與規律均衡用餐。", priority: .supplemental),
                source("NICE Type 2 Diabetes Dietary Advice", "https://www.nice.org.uk/guidance/ng28/chapter/Dietary-advice-and-interventions", reference: "國際輔助引用：營養建議需尊重個人需求、文化、意願與生活品質。", priority: .supplemental)
            ]
        case .japanese:
            return [
                source("ADA Standards of Care in Diabetes", "https://professional.diabetes.org/standards-of-care", reference: "国際補足参照：個別化された栄養ケア、診断や薬剤量提示を避ける範囲。", priority: .supplemental),
                source("CDC Diabetes Meal Planning", "https://www.cdc.gov/diabetes/healthy-eating/diabetes-meal-planning.html", reference: "国際補足参照：プレート法、炭水化物量、量の把握、規則的でバランスのよい食事。", priority: .supplemental),
                source("NICE Type 2 Diabetes Dietary Advice", "https://www.nice.org.uk/guidance/ng28/chapter/Dietary-advice-and-interventions", reference: "国際補足参照：本人のニーズ、文化、意欲、生活の質に配慮した栄養助言。", priority: .supplemental)
            ]
        default:
            return [
                source("衛生福利部國民健康署 糖尿病與我", "https://health99.hpa.gov.tw/material/3404", reference: "Taiwan supplemental reference: consistent carbs, fiber, appropriate fats, weight support, and glucose self-monitoring.", priority: .supplemental),
                source("糖尿病情報センター 食事のはなし", "https://dmic.jihs.go.jp/general/about-dm/040/020/02-1.html", reference: "Japan supplemental reference: appropriate energy, balanced regular meals, and avoiding unnecessary food bans.", priority: .supplemental)
            ]
        }
    }

    private static func ckdSources(lang: AppLanguage) -> [MedicalAuthoritySource] {
        switch lang.translationBase {
        case .traditionalChinese:
            return [
                source("衛生福利部國民健康署 慢性腎臟病防治", "https://www.hpa.gov.tw/Pages/List.aspx?nodeid=635", reference: "台灣優先引用：CKD 防治衛教架構，將提醒限制在一般飲食風險、追蹤與專業照護。"),
                source("衛生福利部國民健康署 慢性腎臟病健康管理手冊", "https://www.hpa.gov.tw/Pages/List.aspx?nodeid=1157", reference: "台灣優先引用：依分期、尿量、檢驗值與營養師建議調整鈉、鉀、磷、蛋白質。")
            ] + ckdSupplementalSources(lang: lang)
        case .japanese:
            return [
                source("日本腎臓学会 CKD診療ガイドライン2023", "https://cdn.jsn.or.jp/medic/guideline/pdf/guide/001-294.pdf", reference: "日本優先参照：CKDステージと検査値に応じた食塩、たんぱく質、カリウム、リンの個別調整。"),
                source("日本腎臓病協会 CKDの予防と治療", "https://j-ka.or.jp/ckd/care.php", reference: "日本優先参照：CKDの予防・治療は医療者の診療と生活習慣支援を組み合わせるという範囲。")
            ] + ckdSupplementalSources(lang: lang)
        default:
            return [
                source("NIDDK Healthy Eating for Adults with CKD", "https://www.niddk.nih.gov/health-information/kidney-disease/chronic-kidney-disease-ckd/healthy-eating-adults-chronic-kidney-disease", reference: "U.S. priority reference: there is no single CKD meal plan; diet changes depend on CKD progression and care-team goals."),
                source("National Kidney Foundation Nutrition and Kidney Disease", "https://www.kidney.org/kidney-topics/nutrition-and-kidney-disease-stages-1-5-not-dialysis", reference: "U.S. priority reference: sodium, potassium, phosphorus, calcium, and protein are lab-guided nutrients, not automatic restrictions."),
                source("KDIGO 2024 CKD Guideline", "https://kdigo.org/wp-content/uploads/2024/03/KDIGO-2024-CKD-Guideline.pdf", reference: "International priority reference: healthy diverse diets, sodium reduction, G3-G5 protein guidance, and individualized renal dietitian counseling."),
                source("NICE CKD Assessment and Management", "https://www.nice.org.uk/guidance/ng203/chapter/Recommendations", reference: "European priority reference: potassium, phosphate, calories, and salt advice should match CKD severity.")
            ] + ckdSupplementalSources(lang: lang)
        }
    }

    private static func ckdSupplementalSources(lang: AppLanguage) -> [MedicalAuthoritySource] {
        switch lang.translationBase {
        case .traditionalChinese:
            return [
                source("KDIGO 2024 CKD Guideline", "https://kdigo.org/wp-content/uploads/2024/03/KDIGO-2024-CKD-Guideline.pdf", reference: "國際輔助引用：健康多元飲食、減鈉、G3-G5 蛋白質建議與腎臟營養師個別化諮詢。", priority: .supplemental),
                source("NIDDK Healthy Eating for Adults with CKD", "https://www.niddk.nih.gov/health-information/kidney-disease/chronic-kidney-disease-ckd/healthy-eating-adults-chronic-kidney-disease", reference: "國際輔助引用：CKD 沒有單一飲食模板，營養調整會隨分期與醫療團隊目標改變。", priority: .supplemental),
                source("NICE CKD Assessment and Management", "https://www.nice.org.uk/guidance/ng203/chapter/Recommendations", reference: "國際輔助引用：鉀、磷、熱量與鹽分建議需符合 CKD 嚴重度。", priority: .supplemental),
                source("USDA FoodData Central", "https://fdc.nal.usda.gov/", reference: "國際輔助引用：食物成分資料庫，用於支持燕麥、穀物、包裝食品等鉀、磷、鈉成分提醒。", priority: .supplemental)
            ]
        case .japanese:
            return [
                source("KDIGO 2024 CKD Guideline", "https://kdigo.org/wp-content/uploads/2024/03/KDIGO-2024-CKD-Guideline.pdf", reference: "国際補足参照：多様で健康的な食事、減塩、G3-G5のたんぱく質、腎臓専門栄養士による個別助言。", priority: .supplemental),
                source("NIDDK Healthy Eating for Adults with CKD", "https://www.niddk.nih.gov/health-information/kidney-disease/chronic-kidney-disease-ckd/healthy-eating-adults-chronic-kidney-disease", reference: "国際補足参照：CKDに単一の食事計画はなく、進行度と医療チームの目標で変わる。", priority: .supplemental),
                source("NICE CKD Assessment and Management", "https://www.nice.org.uk/guidance/ng203/chapter/Recommendations", reference: "国際補足参照：カリウム、リン、エネルギー、塩分の助言はCKDの重症度に合わせる。", priority: .supplemental),
                source("USDA FoodData Central", "https://fdc.nal.usda.gov/", reference: "国際補足参照：食品成分データベース。オートミール、穀物、包装食品などのカリウム、リン、ナトリウム注意に使用。", priority: .supplemental)
            ]
        default:
            return [
                source("衛生福利部國民健康署 慢性腎臟病健康管理手冊", "https://www.hpa.gov.tw/Pages/List.aspx?nodeid=1157", reference: "Taiwan supplemental reference: stage, urine output, labs, and dietitian goals guide sodium, potassium, phosphorus, and protein advice.", priority: .supplemental),
                source("日本腎臓学会 CKD診療ガイドライン2023", "https://cdn.jsn.or.jp/medic/guideline/pdf/guide/001-294.pdf", reference: "Japan supplemental reference: CKD stage and lab-guided sodium, protein, potassium, and phosphorus individualization.", priority: .supplemental),
                source("USDA FoodData Central", "https://fdc.nal.usda.gov/", reference: "Food composition reference used to support potassium, phosphorus, and sodium flags for foods such as oats, cereal, and packaged snacks.", priority: .supplemental)
            ]
        }
    }

    private static func medicalGuardrails(lang: AppLanguage) -> [String] {
        switch lang.translationBase {
        case .traditionalChinese:
            return [
                "僅依照片辨識與營養估算提供一般飲食風險提示。",
                "不診斷疾病、不判定分期、不取代醫師或營養師的個人化限制。",
                "不從照片或裝置感測器測量血糖、eGFR、血鉀或血磷。",
                "不提供胰島素、降血糖藥、磷結合劑、鉀結合劑或任何藥物劑量。"
            ]
        case .japanese:
            return [
                "写真認識と栄養推定にもとづく一般的な食事リスク表示のみです。",
                "診断、ステージ判定、医師・管理栄養士の個別指示の代替は行いません。",
                "写真やデバイスセンサーから血糖、eGFR、血清カリウム、リンを測定しません。",
                "インスリン、血糖降下薬、リン吸着薬、カリウム結合薬などの用量は提示しません。"
            ]
        default:
            return [
                "Provides general diet risk flags from photo recognition and nutrition estimates only.",
                "Does not diagnose, stage disease, or replace clinician or dietitian instructions.",
                "Does not measure glucose, eGFR, potassium, or phosphorus from photos or device sensors.",
                "Does not provide insulin, glucose-lowering medicine, phosphate binder, potassium binder, or other medication dosing."
            ]
        }
    }

    private static func source(_ title: String, _ urlString: String, reference: String? = nil, priority: MedicalSourcePriority = .localizedPrimary) -> MedicalAuthoritySource {
        MedicalAuthoritySource(title: title, url: URL(string: urlString)!, reference: reference ?? title, priority: priority)
    }

    private static let processedCarbFoodKeywords = [
        "chips", "potato chips", "crisps", "cracker", "pretzel", "snack", "packaged snack", "ultra-processed",
        "instant noodle", "instant ramen", "breakfast cereal", "sweetened cereal", "granola", "cookie", "pastry",
        "洋芋片", "薯片", "餅乾", "蘇打餅", "零食", "包裝零食", "泡麵", "速食麵", "即食麵", "早餐穀片", "穀片", "即食燕麥", "加工澱粉",
        "ポテトチップス", "チップス", "クラッカー", "スナック", "包装スナック", "インスタント麺", "インスタントラーメン", "シリアル", "グラノーラ", "加工炭水化物"
    ]

    private static let oatMineralKeywords = [
        "oat", "oats", "oatmeal", "rolled oats", "steel cut oats", "granola",
        "燕麥", "燕麥片", "即食燕麥", "穀片",
        "オートミール", "オーツ", "グラノーラ", "シリアル"
    ]

    private static let potatoSnackKeywords = [
        "potato chips", "chips", "crisps",
        "洋芋片", "薯片", "洋芋",
        "ポテトチップス", "チップス"
    ]

    private static let ckdSodiumFoodKeywords = [
        "ramen", "instant", "soup", "sauce", "soy sauce", "bacon", "ham", "sausage", "deli", "pickle", "fast food", "processed", "salted",
        "泡麵", "拉麵", "湯", "醬", "醬油", "培根", "火腿", "香腸", "滷", "鹹酥", "加工", "醃",
        "ラーメン", "インスタント", "スープ", "醤油", "ソース", "ベーコン", "ハム", "ソーセージ", "加工", "漬物"
    ] + potatoSnackKeywords

    private static let ckdPotassiumFoodKeywords = [
        "banana", "avocado", "potato", "sweet potato", "tomato", "spinach", "beans", "legumes", "dried fruit", "coconut water", "orange", "kiwi", "melon", "pumpkin", "taro",
        "香蕉", "酪梨", "馬鈴薯", "地瓜", "番茄", "菠菜", "豆", "乾果", "椰子水", "柳橙", "橘子", "奇異果", "哈密瓜", "南瓜", "芋頭",
        "バナナ", "アボカド", "じゃがいも", "さつまいも", "トマト", "ほうれん草", "豆", "ドライフルーツ", "ココナッツウォーター", "オレンジ", "キウイ", "メロン", "かぼちゃ", "里芋"
    ]

    private static let ckdPhosphorusFoodKeywords = [
        "cola", "cheese", "dairy", "milk", "yogurt", "organ", "liver", "nuts", "seeds", "processed meat", "sausage", "ham", "bacon", "phosphate", "phosphorus",
        "可樂", "起司", "乳製", "牛奶", "優格", "內臟", "肝", "堅果", "種子", "加工肉", "香腸", "火腿", "培根", "磷酸鹽", "高磷",
        "コーラ", "チーズ", "乳製品", "牛乳", "ヨーグルト", "内臓", "レバー", "ナッツ", "種", "加工肉", "ソーセージ", "ハム", "ベーコン", "リン酸塩", "高リン"
    ]

    private static func analysisText(_ data: CloudResponsePayload) -> String {
        let itemText = data.itemEstimates
            .map { [$0.name, $0.portionDescription, $0.portionBasis].compactMap { $0 }.joined(separator: " ") }
            .joined(separator: " ")
        return [data.foodList, data.reasoning, data.healthTip ?? "", itemText].joined(separator: " ").lowercased()
    }

    private static func containsAny(_ text: String, keywords: [String]) -> Bool {
        keywords.contains { text.contains($0.lowercased()) }
    }
}

struct WatchHealthSnapshot: Codable, Equatable {
    var steps: Int = 0
    var activeEnergy: Double = 0
    var basalEnergy: Double = 0
    var exerciseMinutes: Double = 0
    var standMinutes: Double = 0
    var moveMinutes: Double = 0
    var distanceWalkingRunningKm: Double = 0
    var flightsClimbed: Double = 0
    var averageHeartRate: Double = 0
    var restingHeartRate: Double = 0
    var walkingHeartRateAverage: Double = 0
    var heartRateVariability: Double = 0
    var respiratoryRate: Double = 0
    var oxygenSaturation: Double = 0
    var sleepMinutes: Double = 0
    var wristTemperatureCelsius: Double = 0
    var timeInDaylightMinutes: Double = 0
    var physicalEffortMETs: Double = 0
    var workoutCount: Int = 0
    var workoutDurationMinutes: Double = 0
    var workoutEnergy: Double = 0
    var latestWorkoutName: String = ""
    var watchSourceName: String = ""
    var activitySourceName: String = ""
    var activitySourceKind: HealthDataSourceKind = .none
    var lastUpdated: Date = Date()

    var displaySourceName: String {
        if !activitySourceName.isEmpty { return activitySourceName }
        return watchSourceName
    }

    var hasActivitySignals: Bool {
        steps > 0 ||
        activeEnergy > 0 ||
        exerciseMinutes > 0 ||
        averageHeartRate > 0 ||
        restingHeartRate > 0 ||
        sleepMinutes > 0 ||
        workoutCount > 0 ||
        !displaySourceName.isEmpty
    }

    var hasWatchSignals: Bool {
        hasActivitySignals
    }
}

// --- Health Coach ---
struct HealthCoach {
    static func getDailyKnowledge(lang: AppLanguage) -> String {
        let index = (Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0) % 7
        switch lang.translationBase {
        case .traditionalChinese:
            let list = [
                "💡 **進食順序**：先吃膳食纖維(蔬菜)，再吃蛋白質，最後吃澱粉，能有效平穩血糖。",
                "💧 **水份攝取**：每公斤體重至少需要 30-40cc 的水。有時「餓」其實只是「渴」了。",
                "🥩 **蛋白質效應**：消化蛋白質需要消耗更多熱量。每餐至少要有一個手掌大的蛋白質。",
                "😴 **睡眠與體重**：睡眠不足會導致「飢餓素」上升，讓你隔天更想吃高糖高油食物。",
                "🍬 **隱形糖分**：小心醬料！番茄醬、燒烤醬通常含有大量的糖。",
                "🚶 **NEAT 效應**：非運動性消耗 (走路、站立) 佔了一天消耗的很大比例，多動比狂練更重要。",
                "⚖️ **體重波動**：一天內體重浮動 1-2 公斤是正常的。請看長期趨勢。"
            ]
            return list[index]
        case .english, .unitedStates:
            let list = [
                "💡 **Food Order**: Veggies first, then protein, carbs last to stabilize blood sugar.",
                "💧 **Hydration**: Drink 30-40ml water per kg. Thirst is often mistaken for hunger.",
                "🥩 **Protein**: Digesting protein burns calories. Eat a palm-sized portion per meal.",
                "😴 **Sleep**: Lack of sleep increases ghrelin (hunger hormone) and sugar cravings.",
                "🍬 **Hidden Sugar**: Sauces like ketchup often contain hidden sugar.",
                "🚶 **NEAT**: Walking and standing burn significant calories daily.",
                "⚖️ **Fluctuation**: Daily weight changes of 1-2kg are normal."
            ]
            return list[index]
        case .japanese, .japan:
            let list = [
                "💡 **食べる順番**: 野菜→タンパク質→炭水化物の順で食べると血糖値が安定します。",
                "💧 **水分補給**: 体重1kgあたり30-40mlの水が必要です。",
                "🥩 **タンパク質**: タンパク質の消化はカロリーを消費します。毎食摂取しましょう。",
                "😴 **睡眠**: 睡眠不足は食欲増進ホルモンを増やします。",
                "🍬 **隠れ糖分**: ソース類には糖分が多く含まれています。",
                "🚶 **NEAT**: 日常の歩行は重要なカロリー消費源です。",
                "⚖️ **体重変動**: 1日1-2kgの変動は正常です。"
            ]
            return list[index]
        }
    }

    static func generateInsight(profile: UserProfile, todayCalories: Int, lang: AppLanguage) -> InsightResult {
        let knowledge = getDailyKnowledge(lang: lang)
        guard profile.currentWeight > 0, profile.height > 0 else {
            return InsightResult(title: missingProfileTitle(lang: lang), advice: missingProfileAdvice(lang: lang), knowledge: knowledge)
        }

        let title: String
        let advice: String
        switch lang.translationBase {
        case .traditionalChinese:
            (title, advice) = chineseInsight(profile: profile, todayCalories: todayCalories, lang: lang)
        case .japanese:
            (title, advice) = japaneseInsight(profile: profile, todayCalories: todayCalories, lang: lang)
        default:
            (title, advice) = englishInsight(profile: profile, todayCalories: todayCalories, lang: lang)
        }

        return InsightResult(title: title, advice: advice, knowledge: knowledge)
    }

    private static func chineseInsight(profile: UserProfile, todayCalories: Int, lang: AppLanguage) -> (String, String) {
        let bmi = profile.bmiValue
        let maintenance = profile.estimatedMaintenanceCalories
        let target = profile.dailyCalorieLimit
        let remaining = target - todayCalories
        let diff = abs(profile.currentWeight - profile.targetWeight)
        let special = chineseSpecialNote(profile)
        let activity = chineseActivityNote(profile)
        let energy = remaining < 0
            ? "今天已比目標多 \(abs(remaining)) kcal，不需要用跳餐補救；把下一餐做得清爽、放慢進食，並在身體允許時安排一段輕鬆步行即可。"
            : "今天距離目標還有約 \(remaining) kcal，適合把空間留給一份完整正餐，而不是用零食零散補滿。"

        switch profile.weightGoalDirection {
        case .lose:
            let title = diff > 5 ? "減重目標：用穩定赤字推進" : "接近目標：先守住可持續節奏"
            let advice = "目前估算維持熱量約 \(maintenance) kcal，今日目標約 \(target) kcal，赤字設定在 \(abs(profile.goalCalorieAdjustment)) kcal 內，屬於較保守的速度。\(energy) \(activity) \(special)"
            return (title, advice)
        case .gain:
            let title = "增重目標：把多出的熱量放在正餐與恢復"
            let proteinLine = profile.medicalDietMode == .chronicKidneyDisease ? "因為你開啟 CKD 模式，不建議自行提高蛋白質份量，增重策略應先和腎臟營養師對齊。" : "若有做阻力訓練，可把多出的熱量放在主食、乳品或堅果等容易維持的加餐。"
            let advice = "目前估算維持熱量約 \(maintenance) kcal，今日目標約 \(target) kcal，比維持多 \(profile.goalCalorieAdjustment) kcal。\(proteinLine) \(activity) \(special)"
            return (title, advice)
        case .maintain:
            if bmi >= profile.bmiRiskThreshold(for: lang) {
                return ("維持期：先降低長期風險", "目前 BMI 約 \(String(format: "%.1f", bmi))。如果你還沒準備設定減重目標，可以先守住今日目標 \(target) kcal，從含糖飲、油炸點心或深夜加餐挑一項慢慢減量。\(activity) \(special)")
            }
            if bmi > 0 && bmi < 18.5 {
                return ("維持期：先把攝取補穩", "目前 BMI 約 \(String(format: "%.1f", bmi))，比起再降低熱量，更重要的是規律吃到足夠份量。今天目標約 \(target) kcal，可優先補完整正餐、優質油脂與你能穩定接受的加餐。\(special)")
            }
            return ("維持期：看趨勢，不追單日數字", "你的今日目標約 \(target) kcal，維持熱量約 \(maintenance) kcal。體重一天上下 1-2 公斤常和水分、鈉與腸胃內容物有關，建議看 7-14 天趨勢。\(activity) \(special)")
        }
    }

    private static func englishInsight(profile: UserProfile, todayCalories: Int, lang: AppLanguage) -> (String, String) {
        let bmi = profile.bmiValue
        let maintenance = profile.estimatedMaintenanceCalories
        let target = profile.dailyCalorieLimit
        let remaining = target - todayCalories
        let diff = abs(profile.currentWeight - profile.targetWeight)
        let special = englishSpecialNote(profile)
        let activity = englishActivityNote(profile)
        let energy = remaining < 0
            ? "You are about \(abs(remaining)) kcal over today, so avoid a skipped-meal rebound; make the next meal lighter, slower, and more structured, then return to the plan tomorrow."
            : "You have about \(remaining) kcal left today, enough to plan a complete meal rather than filling the gap with scattered snacks."

        switch profile.weightGoalDirection {
        case .lose:
            let title = diff > 5 ? "Weight loss: steady deficit" : "Close to target: keep it sustainable"
            let advice = "Estimated maintenance is about \(maintenance) kcal and today's target is about \(target) kcal, a conservative \(abs(profile.goalCalorieAdjustment)) kcal adjustment. \(energy) \(activity) \(special)"
            return (title, advice)
        case .gain:
            let title = "Weight gain: add calories where they support recovery"
            let proteinLine = profile.medicalDietMode == .chronicKidneyDisease ? "Because CKD mode is on, do not simply raise protein portions; align any protein change with your renal dietitian." : "If you train, put the extra calories into reliable meals or snacks such as an extra starch, dairy, nuts, or another balanced portion you can repeat."
            let advice = "Estimated maintenance is about \(maintenance) kcal and today's target is about \(target) kcal, roughly \(profile.goalCalorieAdjustment) kcal above maintenance. \(proteinLine) \(activity) \(special)"
            return (title, advice)
        case .maintain:
            if bmi >= profile.bmiRiskThreshold(for: lang) {
                return ("Maintenance: reduce risk without crash dieting", "Your BMI is about \(String(format: "%.1f", bmi)). If you are not setting a loss goal yet, start by holding today's target around \(target) kcal and choose one repeatable swap, such as reducing sugary drinks, fried snacks, or late-night extras. \(activity) \(special)")
            }
            if bmi > 0 && bmi < 18.5 {
                return ("Maintenance: build a steadier intake", "Your BMI is about \(String(format: "%.1f", bmi)). Rather than lowering calories, focus on reaching today's target of about \(target) kcal with regular meals and nutrient-dense additions you can keep up. \(special)")
            }
            return ("Maintenance: judge the trend, not one weigh-in", "Today's target is about \(target) kcal and estimated maintenance is about \(maintenance) kcal. Day-to-day weight swings often reflect water, sodium, and digestion, so use a 7-14 day trend before changing the plan. \(activity) \(special)")
        }
    }

    private static func japaneseInsight(profile: UserProfile, todayCalories: Int, lang: AppLanguage) -> (String, String) {
        let bmi = profile.bmiValue
        let maintenance = profile.estimatedMaintenanceCalories
        let target = profile.dailyCalorieLimit
        let remaining = target - todayCalories
        let diff = abs(profile.currentWeight - profile.targetWeight)
        let special = japaneseSpecialNote(profile)
        let activity = japaneseActivityNote(profile)
        let energy = remaining < 0
            ? "今日は目標より約 \(abs(remaining)) kcal 多めです。欠食で取り戻そうとせず、次の食事を軽めで整え、無理のない範囲で少し歩くくらいに留めましょう。"
            : "今日はあと約 \(remaining) kcal あります。間食で細かく埋めるより、主食・主菜・副菜のそろった食事に使う方が安定します。"

        switch profile.weightGoalDirection {
        case .lose:
            let title = diff > 5 ? "減量目標：ゆるやかな赤字で進める" : "目標近く：維持できるペースを優先"
            let advice = "推定維持カロリーは約 \(maintenance) kcal、今日の目標は約 \(target) kcal で、調整幅は \(abs(profile.goalCalorieAdjustment)) kcal 以内です。\(energy) \(activity) \(special)"
            return (title, advice)
        case .gain:
            let title = "増量目標：余分なカロリーを回復に使う"
            let proteinLine = profile.medicalDietMode == .chronicKidneyDisease ? "CKDモードが有効なため、たんぱく質量を自己判断で増やすのは避け、腎臓専門の栄養指導を優先してください。" : "筋トレをしている場合は、主食や乳製品、ナッツなど継続しやすい追加分に回すと続けやすいです。"
            let advice = "推定維持カロリーは約 \(maintenance) kcal、今日の目標は約 \(target) kcal で、維持より約 \(profile.goalCalorieAdjustment) kcal 多めです。\(proteinLine) \(activity) \(special)"
            return (title, advice)
        case .maintain:
            if bmi >= profile.bmiRiskThreshold(for: lang) {
                return ("維持期：急がずリスクを下げる", "BMIは約 \(String(format: "%.1f", bmi)) です。まだ減量目標を置かない場合も、今日の目標 \(target) kcal を目安にし、甘い飲み物、揚げ物、夜遅い追加食のどれか一つから整えると続けやすいです。\(activity) \(special)")
            }
            if bmi > 0 && bmi < 18.5 {
                return ("維持期：まず摂取を安定させる", "BMIは約 \(String(format: "%.1f", bmi)) です。さらに減らすより、今日の目標 \(target) kcal に近づけることを優先し、規則的な食事と無理のない間食を組み合わせましょう。\(special)")
            }
            return ("維持期：1回の体重より傾向を見る", "今日の目標は約 \(target) kcal、推定維持カロリーは約 \(maintenance) kcal です。体重は水分や塩分で日々動くため、7-14日の傾向で判断しましょう。\(activity) \(special)")
        }
    }

    private static func missingProfileTitle(lang: AppLanguage) -> String {
        switch lang.translationBase {
        case .traditionalChinese: return "先建立體重基準"
        case .japanese: return "まず基準を設定"
        default: return "Set a baseline first"
        }
    }

    private static func missingProfileAdvice(lang: AppLanguage) -> String {
        switch lang.translationBase {
        case .traditionalChinese: return "輸入身高、目前體重與目標體重後，App 才能把維持熱量和今日目標分開計算。沒有基準時，先用均衡餐與規律活動建立紀錄。"
        case .japanese: return "身長、現在の体重、目標体重を入力すると、維持カロリーと今日の目標を分けて計算できます。未設定の間は、食事と活動の記録を安定させましょう。"
        default: return "Enter height, current weight, and goal weight so the app can separate maintenance calories from today's target. Until then, focus on consistent meals and activity records."
        }
    }

    private static func chineseActivityNote(_ profile: UserProfile) -> String {
        if profile.stepCount > 0 && profile.stepCount < 6000 {
            return "今天步數 \(profile.stepCount) 步偏低，先把飯後 10 分鐘走動或通勤多一段路變成固定習慣。"
        }
        if profile.activeEnergy > 400 {
            let source = profile.activityDataSourceKind == .appleWatch ? "Apple Watch" : "Apple Health 活動資料"
            return "今天\(source)顯示活動量不錯，晚餐不必刻意壓得太低，重點是把份量和睡眠守穩。"
        }
        if !profile.usesSyncedActivityData {
            return "目前先用「\(profile.activityScenario.label(lang: .traditionalChinese))」估算活動量；若之後同步 Apple Health 或穿戴裝置，熱量目標會更貼近日常消耗。"
        }
        return "活動量先不用追求激烈，能穩定增加日常走動，通常比偶爾高強度更容易維持。"
    }

    private static func englishActivityNote(_ profile: UserProfile) -> String {
        if profile.stepCount > 0 && profile.stepCount < 6000 {
            return "Steps are low today at \(profile.stepCount), so a repeatable 10-minute walk after a meal is a better first lever than a hard workout."
        }
        if profile.activeEnergy > 400 {
            let source = profile.activityDataSourceKind == .appleWatch ? "Apple Watch" : "Apple Health activity data"
            return "\(source) shows a solid activity day, so keep dinner structured rather than overly restrictive."
        }
        if !profile.usesSyncedActivityData {
            return "The app is using your \(profile.activityScenario.label(lang: .unitedStates).lowercased()) setting until Apple Health or wearable data is synced."
        }
        return "Activity does not need to be intense; repeatable walking and standing usually matter more than occasional hard sessions."
    }

    private static func japaneseActivityNote(_ profile: UserProfile) -> String {
        if profile.stepCount > 0 && profile.stepCount < 6000 {
            return "今日は \(profile.stepCount) 歩で少なめです。まずは食後10分歩くなど、続けやすい動きを足しましょう。"
        }
        if profile.activeEnergy > 400 {
            let source = profile.activityDataSourceKind == .appleWatch ? "Apple Watch" : "Appleヘルスケアの活動データ"
            return "\(source)では活動量は十分あります。夕食を極端に減らすより、量と睡眠を整える方が安定します。"
        }
        if !profile.usesSyncedActivityData {
            return "現在は「\(profile.activityScenario.label(lang: .japan))」設定で活動量を推定しています。Appleヘルスケアや連携デバイスを同期すると、目標が日常消費に近づきます。"
        }
        return "運動は激しさより継続性が大切です。歩く時間や立つ時間を少しずつ増やしましょう。"
    }

    private static func chineseSpecialNote(_ profile: UserProfile) -> String {
        switch profile.medicalDietMode {
        case .diabetes:
            return "糖尿病友模式（\(profile.diabetesStage.label(lang: .traditionalChinese))）下，不建議用斷食或少吃一餐當補救；請以規律餐次、血糖監測計畫與醫療團隊設定為準。"
        case .chronicKidneyDisease:
            return "CKD 模式下，鈉、鉀、磷與蛋白質限制要依抽血數值和腎臟營養師指示，不要用高蛋白或低鈉鹽自行調整。"
        case .standard:
            return ""
        }
    }

    private static func englishSpecialNote(_ profile: UserProfile) -> String {
        switch profile.medicalDietMode {
        case .diabetes:
            return "With diabetes mode on (\(profile.diabetesStage.label(lang: .unitedStates))), avoid fasting or skipping a meal as a fix; keep meals consistent and follow your glucose plan."
        case .chronicKidneyDisease:
            return "With CKD mode on, sodium, potassium, phosphorus, and protein limits depend on labs and renal dietitian guidance; avoid generic high-protein advice."
        case .standard:
            return ""
        }
    }

    private static func japaneseSpecialNote(_ profile: UserProfile) -> String {
        switch profile.medicalDietMode {
        case .diabetes:
            return "糖尿病モード（\(profile.diabetesStage.label(lang: .japan))）では、欠食や断食で調整しようとせず、食事の規則性と血糖管理計画を優先してください。"
        case .chronicKidneyDisease:
            return "CKDモードでは、ナトリウム、カリウム、リン、たんぱく質の制限は検査値と腎臓栄養指導に合わせてください。"
        case .standard:
            return ""
        }
    }
}

// --- UserProfile ---
struct UserProfile: Codable {
    let height: Double
    let currentWeight: Double
    let targetWeight: Double
    var stepCount: Int = 0
    var basalEnergy: Double = 0
    var gender: UserGender = .notSet
    var activeEnergy: Double = 0
    var exerciseMinutes: Double = 0
    var standMinutes: Double = 0
    var sleepMinutes: Double = 0
    var restingHeartRate: Double = 0
    var heartRateVariability: Double = 0
    var respiratoryRate: Double = 0
    var oxygenSaturation: Double = 0
    var workoutMinutes: Double = 0
    var activityScenario: ActivityScenario = .mostlySitting
    var activityDataSourceKind: HealthDataSourceKind = .none
    var medicalDietMode: MedicalDietMode = .standard
    var diabetesStage: DiabetesStage = .type2NonInsulin
    var ckdStage: CKDStage = .stage3a

    var bmi: String {
        guard height > 0, currentWeight > 0 else { return "-" }
        let h = height / 100
        return String(format: "%.1f", currentWeight / (h * h))
    }

    var bmiValue: Double {
        guard height > 0, currentWeight > 0 else { return 0 }
        let h = height / 100
        return currentWeight / (h * h)
    }

    var estimatedMaintenanceCalories: Int {
        if currentWeight <= 0 {
            switch gender {
            case .male: return 2000
            case .female: return 1500
            default: return 1600
            }
        }

        let estimatedBase = currentWeight * 24
        let base = basalEnergy >= 1000 ? basalEnergy : estimatedBase
        if usesSyncedActivityData {
            let stepMultiplier = stepCount < 3000 ? 1.2 : (stepCount < 8000 ? 1.375 : (stepCount < 12000 ? 1.55 : 1.725))
            return Int(max(base * stepMultiplier, base + activeEnergy).rounded())
        }
        return Int((base * activityScenario.multiplier).rounded())
    }

    var usesSyncedActivityData: Bool {
        activeEnergy > 50 || stepCount > 0
    }

    var weightGoalDirection: WeightGoalDirection {
        guard targetWeight > 0, currentWeight > 0, abs(currentWeight - targetWeight) >= 1.0 else { return .maintain }
        return targetWeight < currentWeight ? .lose : .gain
    }

    var goalCalorieAdjustment: Int {
        guard targetWeight > 0, currentWeight > 0 else { return 0 }
        let gap = abs(currentWeight - targetWeight)
        guard gap >= 1.0 else { return 0 }

        switch weightGoalDirection {
        case .lose:
            if gap >= 10 { return -500 }
            if gap >= 4 { return -400 }
            return -250
        case .gain:
            if gap >= 5 { return 300 }
            if gap >= 2 { return 250 }
            return 150
        case .maintain:
            return 0
        }
    }

    var minimumDailyCalorieTarget: Int {
        switch gender {
        case .male: return 1500
        case .female: return 1200
        case .notSet: return 1300
        }
    }

    var dailyCalorieLimit: Int {
        let target = estimatedMaintenanceCalories + goalCalorieAdjustment
        return max(minimumDailyCalorieTarget, target)
    }

    func bmiRiskThreshold(for lang: AppLanguage) -> Double {
        switch lang {
        case .japan, .japanese, .traditionalChinese:
            return 25.0
        default:
            return 25.0
        }
    }
}

// --- Networking & States ---
struct FoodRecognitionProfile: Codable, Equatable {
    let height: Double
    let currentWeight: Double
    let targetWeight: Double
    let stepCount: Int
    let basalEnergy: Double
    let gender: UserGender
    let activeEnergy: Double
    let exerciseMinutes: Double
    let standMinutes: Double
    let sleepMinutes: Double
    let restingHeartRate: Double
    let heartRateVariability: Double
    let respiratoryRate: Double
    let oxygenSaturation: Double
    let workoutMinutes: Double
    let activityScenario: ActivityScenario
    let activityDataSourceKind: HealthDataSourceKind

    init(profile: UserProfile) {
        self.height = profile.height
        self.currentWeight = profile.currentWeight
        self.targetWeight = profile.targetWeight
        self.stepCount = profile.stepCount
        self.basalEnergy = profile.basalEnergy
        self.gender = profile.gender
        self.activeEnergy = profile.activeEnergy
        self.exerciseMinutes = profile.exerciseMinutes
        self.standMinutes = profile.standMinutes
        self.sleepMinutes = profile.sleepMinutes
        self.restingHeartRate = profile.restingHeartRate
        self.heartRateVariability = profile.heartRateVariability
        self.respiratoryRate = profile.respiratoryRate
        self.oxygenSaturation = profile.oxygenSaturation
        self.workoutMinutes = profile.workoutMinutes
        self.activityScenario = profile.activityScenario
        self.activityDataSourceKind = profile.activityDataSourceKind
    }
}

struct SpecialDietRequestContext: Codable, Equatable {
    let mode: MedicalDietMode
    let diabetesStage: DiabetesStage?
    let ckdStage: CKDStage?
    let instruction: String
    let prohibitedUses: [String]

    static func make(for profile: UserProfile, language: AppLanguage) -> SpecialDietRequestContext? {
        guard profile.medicalDietMode != .standard else { return nil }

        let instruction: String
        switch language.translationBase {
        case .traditionalChinese:
            instruction = "先獨立完成食物名稱、份量、熱量與三大營養素估算，再把特殊模式用於一般飲食風險提醒。特殊模式下請優先使用 items 的 portionDescription、portionBasis、servingCount 與 macros；若照片是整包、整盒、整桌或多人份，必須說明建議是依可見總量或單人份估算。不要只寫「均衡營養」或套版句；若糖尿病模式辨識到高醣、甜飲、甜點、精緻澱粉或高度加工零食，請連結到可見食物與可能成分，提醒份量、總醣量、纖維/蛋白質搭配與血糖紀錄。若 CKD 模式辨識到高鈉、高鉀、高磷、磷添加物或蛋白質份量偏高食物，包含洋芋片/包裝零食、泡麵、可樂、乳製品、加工肉、堅果種子、燕麥或穀片，請說明可能涉及鈉、鉀、磷或磷酸鹽添加物，並用中性語氣提醒攝取適量、查看標示、依 CKD 分期與個人檢驗值調整。糖尿病照護階段或 CKD 分期只作為使用者選擇的背景資訊，不可從照片判定。不可診斷、治療、開立處方、判定疾病分期、從照片或感測器測量血糖/eGFR/血鉀/血磷，或計算藥物劑量。"
        case .japanese:
            instruction = "食物名・量・カロリー・三大栄養素の推定を先に完了してから、この特殊モードは一般的な食事リスク表示にのみ使用する。特別モードでは items の portionDescription、portionBasis、servingCount、macros を優先して使う。写真が袋全体、箱全体、食卓全体、複数人分の場合は、可視総量か一人前推定かを明記する。「バランスよく」だけの定型文にしない。糖尿病モードで高糖質、甘い飲み物、デザート、精製炭水化物、高度加工スナックを検出した場合は、見えている食品と推定される成分に結びつけ、量、総炭水化物量、食物繊維/たんぱく質との組み合わせ、血糖記録を確認するよう伝える。CKDモードで高ナトリウム、高カリウム、高リン、リン添加物、たんぱく質量が多い食品を検出した場合、ポテトチップス/包装スナック、インスタント麺、コーラ、乳製品、加工肉、ナッツ・種子、オートミール/シリアルを含め、ナトリウム、カリウム、リン、リン酸塩添加物との関係を説明し、量に注意し、表示を確認し、CKDステージと検査値に合わせるよう中立的に伝える。糖尿病ケア段階またはCKDステージは利用者が選択した背景情報としてのみ扱い、画像から判定しない。診断、治療、処方、疾病ステージ判定、写真やセンサーからの血糖/eGFR/カリウム/リン測定、薬剤用量計算は行わない。"
        default:
            instruction = "First identify the food, portion, calories, and macros independently. Use this special mode only for general diet-risk guidance after estimation. In special modes, prioritize items.portionDescription, items.portionBasis, items.servingCount, and macros; if the image shows a whole bag, whole box, shared table, or multi-person portion, clearly state whether the advice is based on total visible food or a per-person estimate. Do not use a generic balanced-nutrition template. If diabetes mode detects higher-carb foods, sweet drinks, desserts, refined starch, or highly processed snacks, tie the advice to the visible food and likely ingredients, then mention portion size, total carbs, fiber/protein pairing, and personal glucose records. If CKD mode detects high-sodium, high-potassium, high-phosphorus, phosphate-additive, or higher-protein foods, including potato chips/packaged snacks, instant noodles, cola, dairy, processed meat, nuts/seeds, oats, or cereal, explain the likely sodium, potassium, phosphorus, or phosphate-additive concern and give neutral portion-aware guidance tied to CKD stage and personal labs. Treat diabetes care stage or CKD stage only as user-selected context, never infer it from the image. Do not diagnose, treat, prescribe, stage disease, measure glucose/eGFR/potassium/phosphorus from photos or sensors, or calculate medication doses."
        }

        return SpecialDietRequestContext(
            mode: profile.medicalDietMode,
            diabetesStage: profile.medicalDietMode == .diabetes ? profile.diabetesStage : nil,
            ckdStage: profile.medicalDietMode == .chronicKidneyDisease ? profile.ckdStage : nil,
            instruction: instruction,
            prohibitedUses: [
                "diagnosis",
                "treatment",
                "prescription",
                "disease staging from the image",
                "blood glucose measurement from the image or device sensors",
                "kidney function or electrolyte measurement from the image or device sensors",
                "insulin dosing",
                "glucose-lowering medication dosing",
                "phosphate binder dosing",
                "potassium binder dosing"
            ]
        )
    }
}

struct FoodSceneAnalysisContext: Codable, Equatable {
    let supportedSceneTypes: [String]
    let instruction: String
    let portionPolicy: String
    let responseContract: String

    static func make(language: AppLanguage) -> FoodSceneAnalysisContext {
        let instruction: String
        let portionPolicy: String
        let responseContract: String

        switch language.translationBase {
        case .traditionalChinese:
            instruction = "不論圖片是單一食物、多個食物、一餐、整桌共享菜、堆疊/袋裝/大盤混合食物或包裝食品，都要逐項辨識可見食物，不要合併成籠統的一餐。不要過度推測被遮住的食物；把不確定性反映在熱量範圍與 reasoning。"
            portionPolicy = "請用盤、碗、杯、餐具、手部比例、包裝標示、可見顆數/片數與份數估算可食部份量。若是整包、整盒、整桌或多人份，先估可見總量；若無法判定使用者實際吃掉比例，請明確寫在 portionDescription 或 portionBasis。特殊 DM/CKD 模式下要優先保留份量依據，因為後續建議會依份量、總醣量、鈉/鉀/磷/蛋白質風險調整。"
            responseContract = "JSON 必須包含 foodList, totalCaloriesMin, totalCaloriesMax, reasoning, macros, healthTip。請盡量回傳 items 陣列；每個項目包含 name, portionDescription, portionBasis, servingCount, caloriesMin, caloriesMax, confidence。portionBasis 請寫估算依據，例如包裝標示、可見片數、碗盤大小或多人份不確定性。"
        case .japanese:
            instruction = "画像が単品、複数品、一食分、テーブル全体の料理、山盛り・袋・大皿の混在食品のどれであっても、見えている食べ物をまとめて一品にせず、主要な食品ごとに識別する。隠れている部分は推測しすぎず、不確実性はカロリー範囲と説明に反映する。"
            portionPolicy = "皿、茶碗、カップ、箸、手、包装表示、見える個数/枚数/人数分などの手がかりから可食部の量を推定する。共有テーブル、袋全体、箱全体の場合は画像内の総量を推定し、利用者が実際に食べた割合が不明なら portionDescription または portionBasis に明記する。DM/CKD特別モードでは、量、総炭水化物、ナトリウム/カリウム/リン/たんぱく質リスクに関わるため、量の根拠を優先して残す。"
            responseContract = "JSONには foodList, totalCaloriesMin, totalCaloriesMax, reasoning, macros, healthTip を含める。可能なら items 配列も返し、各項目に name, portionDescription, portionBasis, servingCount, caloriesMin, caloriesMax, confidence を入れる。portionBasis には包装表示、見える枚数、器の大きさ、複数人分の不確実性など推定根拠を書く。"
        default:
            instruction = "Whether the image shows one food, several foods, one full meal, a shared table spread, or a pile/bag/platter of mixed food, identify the visible foods item by item instead of collapsing them into one generic meal. Do not over-infer hidden food; reflect uncertainty in calorie ranges and reasoning."
            portionPolicy = "Estimate edible portion size from visual cues such as plate, bowl, cup, utensils, hand size, package labels, visible count, and visible serving count. For shared-table, whole-bag, or whole-box images, estimate total visible food unless a per-person portion is clearly indicated; if the user's consumed fraction is unknown, state that in portionDescription or portionBasis. In DM/CKD special modes, preserve portion evidence because advice depends on portion size, total carbs, sodium, potassium, phosphorus, and protein risk."
            responseContract = "Return JSON with foodList, totalCaloriesMin, totalCaloriesMax, reasoning, macros, and healthTip. When possible, include an items array; each item should have name, portionDescription, portionBasis, servingCount, caloriesMin, caloriesMax, and confidence. portionBasis should state the evidence, such as package label, visible count, container size, or uncertainty about shared portions."
        }

        return FoodSceneAnalysisContext(
            supportedSceneTypes: [
                "single food item",
                "several separate foods",
                "one full meal plate or tray",
                "shared table spread",
                "pile, bag, bowl, platter, or mixed-food heap",
                "packaged food with visible label"
            ],
            instruction: instruction,
            portionPolicy: portionPolicy,
            responseContract: responseContract
        )
    }
}

struct WeightGuidanceContext: Codable, Equatable {
    let goalDirection: String
    let maintenanceCalories: Int
    let dailyTargetCalories: Int
    let calorieAdjustment: Int
    let instruction: String
    let safetyBoundaries: [String]

    static func make(profile: UserProfile, language: AppLanguage) -> WeightGuidanceContext {
        let direction: String
        switch profile.weightGoalDirection {
        case .lose: direction = "lose"
        case .gain: direction = "gain"
        case .maintain: direction = "maintain"
        }

        let instruction: String
        switch language.translationBase {
        case .japanese:
            instruction = "体重関連のhealthTipを書く場合は、写真の食事内容、推定維持カロリー、今日の目標、特殊モードを踏まえて、具体的で建設的な一文にする。定型文、欠食、断食、極端な制限、薬剤用量、診断は避ける。"
        default:
            instruction = "If writing a weight-related healthTip, make it specific to the photographed meal, estimated maintenance calories, today's target, and special diet mode. Avoid generic templates, skipped meals, fasting, extreme restriction, medication dosing, or diagnosis."
        }

        return WeightGuidanceContext(
            goalDirection: direction,
            maintenanceCalories: profile.estimatedMaintenanceCalories,
            dailyTargetCalories: profile.dailyCalorieLimit,
            calorieAdjustment: profile.goalCalorieAdjustment,
            instruction: instruction,
            safetyBoundaries: [
                "no fasting or skipped-meal fixes",
                "no extreme restriction",
                "no medication or insulin dosing",
                "no generic high-protein advice for CKD",
                "use sustainable changes and calorie ranges"
            ]
        )
    }
}

struct AICommunicationGuardrailContext: Codable, Equatable {
    let languageCode: String
    let instruction: String
    let uncertaintyPolicy: String
    let prohibitedLanguage: [String]

    static func make(language: AppLanguage) -> AICommunicationGuardrailContext {
        let instruction: String
        let uncertaintyPolicy: String
        let prohibitedLanguage: [String]

        switch language {
        case .japan, .japanese:
            instruction = "ユーザーに表示される文章は日本語で、落ち着いた建設的な表現にする。写真だけで分からない材料、調理油、持病、検査値、血糖や腎機能の結果を断定しない。"
            uncertaintyPolicy = "食品・量・カロリーは推定値として扱い、不確かな場合は「約」「可能性」「見える範囲では」などの表現で不確実性を示す。"
            prohibitedLanguage = [
                "診断・治療・処方・薬剤用量",
                "必ず治る、血糖値が必ず安定する、腎機能が改善する等の保証",
                "デトックス、脂肪燃焼、代謝を上げる等の根拠不明な効果",
                "太る、ダメ、罪悪感、悪い食べ物等の羞恥・非難表現",
                "画像に写っていない材料や量の断定"
            ]
        case .traditionalChinese:
            instruction = "使用者看得到的文字請使用繁體中文，語氣要冷靜、具體、有建設性。不要只靠照片就斷定看不見的食材、用油、疾病狀態、檢驗數值、血糖或腎功能結果。"
            uncertaintyPolicy = "食物、份量、熱量都要視為估算；不確定時使用「約」「可能」「從照片可見範圍」等說法，不要寫成保證。"
            prohibitedLanguage = [
                "診斷、治療、處方、藥物或胰島素劑量",
                "保證安全、治癒、逆轉糖尿病、改善腎功能等絕對承諾",
                "排毒、燃脂、加速代謝等缺乏根據的效果",
                "垃圾食物、你太胖、罪惡、失敗等羞辱或責備語氣",
                "把照片中看不到的食材或份量說成事實"
            ]
        default:
            instruction = "Write user-facing text in US English with a calm, constructive tone. Do not infer unseen ingredients, cooking oil, medical status, lab values, blood glucose outcomes, or kidney outcomes from the image alone."
            uncertaintyPolicy = "Treat food, portion, calories, and macros as estimates. Use wording such as 'about', 'likely', or 'from what is visible' when confidence is limited."
            prohibitedLanguage = [
                "diagnosis, treatment, prescription, medication or insulin dosing",
                "guaranteed safe, cure, reverse diabetes, or kidney function improvement claims",
                "detox, fat-burning, metabolism-boosting, or unsupported effect claims",
                "shaming or moralizing labels such as bad food, guilt, failure, lazy, or fat",
                "stating unseen ingredients or portions as facts"
            ]
        }

        return AICommunicationGuardrailContext(
            languageCode: language.aiLanguageCode,
            instruction: instruction,
            uncertaintyPolicy: uncertaintyPolicy,
            prohibitedLanguage: prohibitedLanguage
        )
    }
}

struct AIResponseDetailContext: Codable, Equatable {
    let tier: String
    let instruction: String
    let requiredReasoningElements: [String]
    let antiFillerRules: [String]
    let healthTipLength: String

    static func make(isPro: Bool, language: AppLanguage) -> AIResponseDetailContext {
        let tier = isPro ? "pro" : "standard"
        let requiredReasoningElements: [String]
        let antiFillerRules: [String]
        let healthTipLength: String
        let instruction: String

        switch (isPro, language) {
        case (true, .japan), (true, .japanese):
            instruction = "Proモードでは、reasoningを無料版より具体的にする。ただし長文化せず、写真から判断できる根拠だけを書く。"
            requiredReasoningElements = [
                "見えている主な食品ごとの識別",
                "量を推定した視覚的手がかり",
                "カロリー範囲が広い、または狭い理由",
                "不確実な点",
                "この食事に合う実行しやすい一つの調整"
            ]
            antiFillerRules = [
                "一般的な栄養教育を長く書かない",
                "免責文を繰り返さない",
                "写真にない食材を足さない",
                "同じ内容を言い換えて水増ししない"
            ]
            healthTipLength = "1〜2文"
        case (false, .japan), (false, .japanese):
            instruction = "標準モードでは、reasoningを短く実用的にまとめる。"
            requiredReasoningElements = [
                "見えている主な食品",
                "大まかな量とカロリー範囲の理由"
            ]
            antiFillerRules = [
                "一般論で水増ししない",
                "写真にない内容を断定しない"
            ]
            healthTipLength = "1文"
        case (true, .traditionalChinese):
            instruction = "Pro 模式的 reasoning 要比免費版更完整，但只能寫照片與使用者脈絡支持的內容，不要加長篇空泛說明。"
            requiredReasoningElements = [
                "逐項說明可見的主要食物",
                "份量推估使用到的視覺線索",
                "熱量區間偏寬或偏窄的理由",
                "仍不確定的地方",
                "針對這餐的一個可執行調整"
            ]
            antiFillerRules = [
                "不要加入一般營養課文",
                "不要重複免責聲明",
                "不要補上照片沒看到的食材",
                "不要用換句話說來填充篇幅"
            ]
            healthTipLength = "1 到 2 句"
        case (false, .traditionalChinese):
            instruction = "標準模式的 reasoning 保持短而實用。"
            requiredReasoningElements = [
                "可見的主要食物",
                "大致份量與熱量區間理由"
            ]
            antiFillerRules = [
                "不要用一般論填充",
                "不要斷定照片看不到的內容"
            ]
            healthTipLength = "1 句"
        case (true, _):
            instruction = "For Pro mode, make reasoning more complete than the free version, but only include evidence supported by the photo and user context. Use US English."
            requiredReasoningElements = [
                "visible main foods item by item",
                "portion cues used for the estimate",
                "why the calorie range is narrow or wide",
                "remaining uncertainty",
                "one practical adjustment for this meal"
            ]
            antiFillerRules = [
                "do not add generic nutrition lessons",
                "do not repeat disclaimers",
                "do not invent unseen ingredients",
                "do not pad with repeated wording"
            ]
            healthTipLength = "1 to 2 sentences"
        case (false, _):
            instruction = "For standard mode, keep reasoning short and practical. Use US English."
            requiredReasoningElements = [
                "visible main foods",
                "brief portion and calorie-range rationale"
            ]
            antiFillerRules = [
                "do not pad with generic advice",
                "do not state unseen details as facts"
            ]
            healthTipLength = "1 sentence"
        }

        return AIResponseDetailContext(
            tier: tier,
            instruction: instruction,
            requiredReasoningElements: requiredReasoningElements,
            antiFillerRules: antiFillerRules,
            healthTipLength: healthTipLength
        )
    }
}

struct LegacyServerCompatibilityPrompt {
    static func detectedText(
        ocrText: String?,
        foodSceneContext: FoodSceneAnalysisContext,
        weightGuidanceContext: WeightGuidanceContext?,
        specialDietContext: SpecialDietRequestContext?,
        communicationGuardrailContext: AICommunicationGuardrailContext? = nil,
        responseDetailContext: AIResponseDetailContext? = nil,
        language: AppLanguage
    ) -> String {
        var sections: [String] = []
        if let cleaned = cleanedOCRText(ocrText) {
            sections.append("OCR_TEXT:\n\(cleaned)")
        }

        sections.append(foodSceneInstructions(foodSceneContext, language: language))

        if let communicationGuardrailContext {
            sections.append(communicationGuardrailInstructions(communicationGuardrailContext, language: language))
        }

        if let responseDetailContext {
            sections.append(responseDetailInstructions(responseDetailContext, language: language))
        }

        if let weightGuidanceContext {
            sections.append(weightGuidanceInstructions(weightGuidanceContext, language: language))
        }

        if let specialDietContext {
            sections.append(specialDietInstructions(specialDietContext, language: language))
        }

        return sections.joined(separator: "\n\n")
    }

    private static func cleanedOCRText(_ text: String?) -> String? {
        guard let text else { return nil }
        let cleaned = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        return String(cleaned.prefix(1_200))
    }

    private static func foodSceneInstructions(_ context: FoodSceneAnalysisContext, language: AppLanguage) -> String {
        switch language.translationBase {
        case .japanese:
            return """
            CLIENT_COMPATIBILITY_INSTRUCTIONS:
            - この画像は単品、複数品、一食分、一桌分の料理、または山盛り・大皿・袋入り食品の可能性があります。
            - 見えている主要食品を一つずつ識別し、各食品の份量、caloriesMin、caloriesMaxを推定してから合計してください。
            - 隠れている食品や見えない量は断定せず、不確実性は広めのカロリー範囲とreasoningに反映してください。
            - 可能ならJSONにitems配列を含めてください: name, portionDescription, caloriesMin, caloriesMax, confidence。
            \(context.instruction)
            \(context.portionPolicy)
            """
        default:
            return """
            CLIENT_COMPATIBILITY_INSTRUCTIONS:
            - This image may show one food, several foods, one full meal, a shared table spread, or a pile/platter/bag of mixed foods.
            - Identify visible major foods item by item, estimate each item's portion, caloriesMin, and caloriesMax, then sum the total range.
            - Do not invent hidden food or unseen portions; reflect uncertainty with wider calorie ranges and reasoning.
            - When possible, return an items array in JSON: name, portionDescription, caloriesMin, caloriesMax, confidence.
            \(context.instruction)
            \(context.portionPolicy)
            """
        }
    }

    private static func communicationGuardrailInstructions(_ context: AICommunicationGuardrailContext, language: AppLanguage) -> String {
        let prohibited = context.prohibitedLanguage.map { "- \($0)" }.joined(separator: "\n")
        switch language.translationBase {
        case .japanese:
            return """
            AI_COMMUNICATION_GUARDRAILS:
            - 表示言語: \(context.languageCode)
            - \(context.instruction)
            - \(context.uncertaintyPolicy)
            - 不明な内容は推測で埋めず、不確実な点として短く説明してください。
            - 禁止表現:
            \(prohibited)
            """
        case .traditionalChinese:
            return """
            AI_COMMUNICATION_GUARDRAILS:
            - 顯示語言: \(context.languageCode)
            - \(context.instruction)
            - \(context.uncertaintyPolicy)
            - 不知道的內容不要補故事，請直接說明不確定之處。
            - 禁止表述:
            \(prohibited)
            """
        default:
            return """
            AI_COMMUNICATION_GUARDRAILS:
            - Display language: \(context.languageCode)
            - \(context.instruction)
            - \(context.uncertaintyPolicy)
            - Do not fill gaps with a story; briefly state uncertainty instead.
            - Prohibited language:
            \(prohibited)
            """
        }
    }

    private static func responseDetailInstructions(_ context: AIResponseDetailContext, language: AppLanguage) -> String {
        let elements = context.requiredReasoningElements.map { "- \($0)" }.joined(separator: "\n")
        let antiFiller = context.antiFillerRules.map { "- \($0)" }.joined(separator: "\n")

        switch language.translationBase {
        case .japanese:
            return """
            AI_RESPONSE_DETAIL_COMPATIBILITY:
            - tier: \(context.tier)
            - \(context.instruction)
            - reasoningに含める内容:
            \(elements)
            - healthTipの長さ: \(context.healthTipLength)
            - 水増し禁止:
            \(antiFiller)
            """
        case .traditionalChinese:
            return """
            AI_RESPONSE_DETAIL_COMPATIBILITY:
            - tier: \(context.tier)
            - \(context.instruction)
            - reasoning 必須內容:
            \(elements)
            - healthTip 長度: \(context.healthTipLength)
            - 不要填充:
            \(antiFiller)
            """
        default:
            return """
            AI_RESPONSE_DETAIL_COMPATIBILITY:
            - tier: \(context.tier)
            - \(context.instruction)
            - Required reasoning elements:
            \(elements)
            - healthTip length: \(context.healthTipLength)
            - No filler:
            \(antiFiller)
            """
        }
    }

    private static func weightGuidanceInstructions(_ context: WeightGuidanceContext, language: AppLanguage) -> String {
        switch language.translationBase {
        case .japanese:
            return """
            WEIGHT_GUIDANCE_COMPATIBILITY:
            - goalDirection: \(context.goalDirection)
            - maintenanceCalories: \(context.maintenanceCalories), dailyTargetCalories: \(context.dailyTargetCalories), adjustment: \(context.calorieAdjustment)
            - healthTipを書く場合は、この食事に即した建設的な提案にし、定型文や欠食・断食・極端な制限は避けてください。
            - CKDや糖尿病の特殊モードがある場合は、その制限を優先してください。
            """
        default:
            return """
            WEIGHT_GUIDANCE_COMPATIBILITY:
            - goalDirection: \(context.goalDirection)
            - maintenanceCalories: \(context.maintenanceCalories), dailyTargetCalories: \(context.dailyTargetCalories), adjustment: \(context.calorieAdjustment)
            - If you write healthTip, make it constructive and specific to this meal, not a generic template. Avoid skipped meals, fasting, extreme restriction, or compensatory punishment.
            - If diabetes or CKD special mode is present, those safety limits override generic weight advice.
            """
        }
    }

    private static func specialDietInstructions(_ context: SpecialDietRequestContext, language: AppLanguage) -> String {
        let modeText: String
        if let diabetesStage = context.diabetesStage {
            modeText = "\(context.mode.rawValue), \(diabetesStage.rawValue)"
        } else if let ckdStage = context.ckdStage {
            modeText = "\(context.mode.rawValue), \(ckdStage.rawValue)"
        } else {
            modeText = context.mode.rawValue
        }
        switch language.translationBase {
        case .traditionalChinese:
            return """
            SPECIAL_DIET_COMPATIBILITY:
            - mode: \(modeText)
            - 只能在完成食物、份量、熱量與三大營養素估算後，用於一般飲食風險提醒。
            - 優先使用 items 的 portionDescription、portionBasis、servingCount 與 macros；整包、整盒、整桌或多人份要說明是可見總量或單人份估算。
            - 不要只寫「均衡營養」或套版句；請依照片中食物與可能成分說明原因。
            - 若糖尿病模式辨識到高醣、甜飲、甜點、精緻澱粉或高度加工零食，請提醒份量、總醣量、纖維/蛋白質搭配與血糖紀錄。
            - 若 CKD 模式辨識到洋芋片/包裝零食、泡麵、可樂、乳製品、加工肉、堅果種子、燕麥或穀片，請評估鈉、鉀、磷、磷酸鹽添加物或蛋白質份量，提醒攝取適量、查看標示，並依 CKD 分期與檢驗值調整；不可說成禁食或治療指令。
            - 糖尿病照護階段或 CKD 分期是使用者選擇的背景資訊，不可從照片推斷。
            - 禁止: 診斷、治療、處方、從圖片判定疾病分期、從照片/感測器測量血糖或腎功能、胰島素或藥物劑量計算。
            """
        case .japanese:
            return """
            SPECIAL_DIET_COMPATIBILITY:
            - mode: \(modeText)
            - 食品・量・カロリー推定が完了した後にのみ、一般的な食事リスク表示として使ってください。
            - items の portionDescription、portionBasis、servingCount、macros を優先してください。袋全体、箱全体、食卓全体、複数人分は可視総量か一人前推定かを明記してください。
            - 「バランスよく」だけの定型文にせず、写真の食品と推定される成分に結びつけて理由を書いてください。
            - 糖尿病モードで高糖質、甘い飲み物、デザート、精製炭水化物、高度加工スナックを検出した場合は、量、総炭水化物量、食物繊維/たんぱく質との組み合わせ、血糖記録の確認を伝えてください。
            - CKDモードでポテトチップス/包装スナック、インスタント麺、コーラ、乳製品、加工肉、ナッツ・種子、オートミール/シリアルを検出した場合は、ナトリウム、カリウム、リン、リン酸塩添加物、たんぱく質量を評価し、量に注意し表示を確認しCKDステージと検査値に合わせるよう伝えてください。禁止や治療指示として書かないでください。
            - 糖尿病ケア段階またはCKDステージは利用者が選択した背景情報です。画像から判定しないでください。
            - 禁止: 診断、治療、処方、画像からの疾病ステージ判定、写真/センサーからの血糖や腎機能測定、インスリンや薬剤用量計算。
            """
        default:
            return """
            SPECIAL_DIET_COMPATIBILITY:
            - mode: \(modeText)
            - Use only after food, portion, calories, and macros are estimated, and only for general diet-risk guidance.
            - Prioritize items.portionDescription, items.portionBasis, items.servingCount, and macros. For a whole bag, whole box, shared table, or multi-person portion, state whether advice uses total visible food or a per-person estimate.
            - Do not write a generic balanced-nutrition template; tie the reason to the visible food and likely ingredients.
            - If diabetes mode detects higher-carb foods, sweet drinks, desserts, refined starch, or highly processed snacks, include a portion-aware reminder about total carbs, fiber/protein pairing, and personal glucose records.
            - If CKD mode detects potato chips/packaged snacks, instant noodles, cola, dairy, processed meat, nuts/seeds, oats, or cereal, evaluate sodium, potassium, phosphorus, phosphate additives, and protein portion, then advise portion awareness, label checks, and alignment with CKD stage/labs. Do not frame it as a food ban or treatment instruction.
            - Diabetes care stage or CKD stage is user-selected context. Do not infer it from the image.
            - Prohibited: diagnosis, treatment, prescription, disease staging from the image, glucose or kidney-function measurement from photos/sensors, insulin or medication dosing.
            """
        }
    }
}

struct RequestPayload: Codable {
    let image: String
    let language: String
    let userProfile: FoodRecognitionProfile?
    let detectedText: String?
    let mealTime: String
    let communicationGuardrailContext: AICommunicationGuardrailContext
    let responseDetailContext: AIResponseDetailContext
    let foodSceneContext: FoodSceneAnalysisContext
    let weightGuidanceContext: WeightGuidanceContext
    let specialDietContext: SpecialDietRequestContext?
}
struct Macronutrients: Codable, Equatable { let protein: Int; let carbs: Int; let fat: Int }
struct FoodEstimateItem: Codable, Equatable, Identifiable {
    let name: String
    let portionDescription: String?
    let portionBasis: String?
    let servingCount: Double?
    let caloriesMin: Int
    let caloriesMax: Int
    let confidence: Double?

    var id: String { "\(name)-\(portionDescription ?? "")-\(portionBasis ?? "")-\(caloriesMin)-\(caloriesMax)" }

    enum CodingKeys: String, CodingKey {
        case name, itemName, foodName, portionDescription, portion, quantity, serving
        case portionBasis, basis, visualBasis, estimateBasis, servingCount, servings, visibleCount
        case caloriesMin, caloriesMax, minCalories, maxCalories, calories, estimatedCalories, confidence
    }

    init(name: String, portionDescription: String?, caloriesMin: Int, caloriesMax: Int, confidence: Double?, portionBasis: String? = nil, servingCount: Double? = nil) {
        self.name = name
        self.portionDescription = portionDescription
        self.portionBasis = portionBasis
        self.servingCount = servingCount
        self.caloriesMin = caloriesMin
        self.caloriesMax = caloriesMax
        self.confidence = confidence
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let exactCalories = Self.firstInt(in: container, keys: [.calories, .estimatedCalories])
        var minCalories = Self.firstInt(in: container, keys: [.caloriesMin, .minCalories]) ?? exactCalories ?? 0
        var maxCalories = Self.firstInt(in: container, keys: [.caloriesMax, .maxCalories]) ?? exactCalories ?? minCalories
        if maxCalories < minCalories {
            swap(&minCalories, &maxCalories)
        }

        self.name = Self.firstString(in: container, keys: [.name, .itemName, .foodName]) ?? "Unknown"
        self.portionDescription = Self.firstString(in: container, keys: [.portionDescription, .portion, .quantity, .serving])
        self.portionBasis = Self.firstString(in: container, keys: [.portionBasis, .basis, .visualBasis, .estimateBasis])
        self.servingCount = Self.firstDouble(in: container, keys: [.servingCount, .servings, .visibleCount])
        self.caloriesMin = minCalories
        self.caloriesMax = maxCalories
        self.confidence = Self.firstDouble(in: container, keys: [.confidence])
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(portionDescription, forKey: .portionDescription)
        try container.encodeIfPresent(portionBasis, forKey: .portionBasis)
        try container.encodeIfPresent(servingCount, forKey: .servingCount)
        try container.encode(caloriesMin, forKey: .caloriesMin)
        try container.encode(caloriesMax, forKey: .caloriesMax)
        try container.encodeIfPresent(confidence, forKey: .confidence)
    }

    func sanitizedForDisplay(language: AppLanguage) -> FoodEstimateItem {
        let sanitizedName = AIOutputSafetyGuard.safeFoodText(name, language: language)
        let sanitizedPortion = AIOutputSafetyGuard.safeOptionalText(portionDescription, maximumLength: 140)
        let sanitizedBasis = AIOutputSafetyGuard.safeOptionalText(portionBasis, maximumLength: 180)
        let minCalories = max(0, min(caloriesMin, caloriesMax))
        let maxCalories = max(minCalories, max(caloriesMin, caloriesMax))
        let sanitizedServingCount = normalizedServingCount

        return FoodEstimateItem(
            name: sanitizedName,
            portionDescription: sanitizedPortion,
            caloriesMin: minCalories,
            caloriesMax: maxCalories,
            confidence: confidence,
            portionBasis: sanitizedBasis,
            servingCount: sanitizedServingCount
        )
    }

    func safeName(language: AppLanguage) -> String {
        AIOutputSafetyGuard.safeFoodText(name, language: language)
    }

    var safePortionDescription: String? {
        AIOutputSafetyGuard.safeOptionalText(portionDescription, maximumLength: 140)
    }

    var safePortionBasis: String? {
        AIOutputSafetyGuard.safeOptionalText(portionBasis, maximumLength: 180)
    }

    var normalizedServingCount: Double? {
        guard let servingCount, servingCount > 0 else { return nil }
        return min(servingCount, 99)
    }

    private static func firstString(in container: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) -> String? {
        for key in keys {
            if let value = try? container.decode(String.self, forKey: key), !value.isEmpty {
                return value
            }
        }
        return nil
    }

    private static func firstInt(in container: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) -> Int? {
        for key in keys {
            if let value = try? container.decode(Int.self, forKey: key) {
                return value
            }
            if let value = try? container.decode(Double.self, forKey: key) {
                return Int(value.rounded())
            }
            if let value = try? container.decode(String.self, forKey: key), let intValue = Int(value) {
                return intValue
            }
        }
        return nil
    }

    private static func firstDouble(in container: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) -> Double? {
        for key in keys {
            if let value = try? container.decode(Double.self, forKey: key) {
                return value
            }
            if let value = try? container.decode(Int.self, forKey: key) {
                return Double(value)
            }
            if let value = try? container.decode(String.self, forKey: key), let doubleValue = Double(value) {
                return doubleValue
            }
        }
        return nil
    }
}

struct AIOutputSafetyGuard {
    private static let restrictedTerms = [
        "diagnose", "diagnosis", "treatment", "treat this", "prescribe", "prescription", "dosage",
        "insulin dose", "medication dose", "drug dose", "phosphate binder", "potassium binder",
        "guaranteed safe", "safe to eat freely", "eat as much as you want", "cure", "reverse diabetes",
        "will stabilize blood sugar", "will lower blood sugar", "kidney function will improve",
        "detox", "cleanse", "flush toxins", "fat-burning", "fat burning", "burn fat", "boost metabolism",
        "bad food", "junk food", "cheat meal", "guilt", "guilty", "failure", "lazy", "you are fat",
        "must not eat", "never eat", "only eat", "ignore previous", "system prompt", "developer message",
        "as an ai language model",
        "診斷", "診断", "治療", "處方", "処方", "胰島素", "インスリン", "劑量", "用量", "藥量", "薬量", "投与量",
        "磷結合劑", "リン吸着薬", "鉀結合劑", "カリウム結合薬",
        "保證安全", "放心吃到飽", "治癒", "治愈", "逆轉糖尿病", "逆转糖尿病", "改善腎功能", "改善肾功能",
        "血糖一定", "血糖必定", "排毒", "燃脂", "脂肪燃燒", "脂肪燃烧", "加速代謝", "加速代谢",
        "垃圾食物", "你太胖", "罪惡", "罪恶", "失敗", "失败", "懶惰", "懒惰", "絕對不能吃", "绝对不能吃",
        "必ず治る", "必ず安定", "腎機能が改善", "デトックス", "脂肪燃焼", "代謝を上げ",
        "悪い食べ物", "ジャンクフード", "罪悪感", "失敗", "怠け", "太りすぎ", "絶対に食べない"
    ]

    static func safeHealthTip(_ tip: String?, language: AppLanguage = .unitedStates) -> String? {
        safeText(tip, maximumLength: 420, language: language)
    }

    static func safeReasoning(_ reasoning: String?, language: AppLanguage = .unitedStates) -> String? {
        safeText(reasoning, maximumLength: 1_200, language: language)
    }

    static func safeFoodText(_ text: String?, language: AppLanguage) -> String {
        safeText(text, maximumLength: 220, language: language) ?? unknownFoodName(language: language)
    }

    static func safeOptionalText(_ text: String?, maximumLength: Int, language: AppLanguage = .unitedStates) -> String? {
        safeText(text, maximumLength: maximumLength, language: language)
    }

    private static func safeText(_ text: String?, maximumLength: Int, language: AppLanguage) -> String? {
        guard let cleaned = cleanedText(text) else { return nil }
        let normalized = cleaned.lowercased()
        guard !restrictedTerms.contains(where: { normalized.contains($0.lowercased()) }) else { return nil }
        if cleaned.count > maximumLength {
            return String(cleaned.prefix(maximumLength)).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
        }
        return cleaned
    }

    private static func cleanedText(_ text: String?) -> String? {
        guard let text else { return nil }
        let cleaned = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }

    private static func unknownFoodName(language: AppLanguage) -> String {
        switch language.translationBase {
        case .traditionalChinese:
            return "未確認食物"
        case .japanese:
            return "未確認の食品"
        default:
            return "Unknown Food"
        }
    }
}

struct MedicalSafetyFilter {
    static func safeHealthTip(_ tip: String?, language: AppLanguage = .unitedStates) -> String? {
        AIOutputSafetyGuard.safeHealthTip(tip, language: language)
    }
}

struct CloudResponsePayload: Codable, Equatable {
    let foodList: String
    let totalCaloriesMin: Int
    let totalCaloriesMax: Int
    let reasoning: String
    let macros: Macronutrients?
    let healthTip: String?
    let itemEstimates: [FoodEstimateItem]

    init(foodList: String, totalCaloriesMin: Int, totalCaloriesMax: Int, reasoning: String, macros: Macronutrients?, healthTip: String?, itemEstimates: [FoodEstimateItem] = []) {
        self.foodList = foodList
        self.totalCaloriesMin = totalCaloriesMin
        self.totalCaloriesMax = totalCaloriesMax
        self.reasoning = reasoning
        self.macros = macros
        self.healthTip = healthTip
        self.itemEstimates = itemEstimates
    }

    enum CodingKeys: String, CodingKey {
        case foodList, totalCaloriesMin, totalCaloriesMax, reasoning, macros, healthTip, itemEstimates
        case food, foods, items, totalCalories, calories, estimatedCalories, minCalories, maxCalories
        case analysis, explanation, protein, carbs, carbohydrates, fat
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedItems = (try? container.decode([FoodEstimateItem].self, forKey: .itemEstimates))
            ?? ((try? container.decode([FoodEstimateItem].self, forKey: .items)) ?? [])
        let exactCalories = Self.firstInt(in: container, keys: [.totalCalories, .calories, .estimatedCalories])
        var minCalories = Self.firstInt(in: container, keys: [.totalCaloriesMin, .minCalories]) ?? exactCalories ?? 0
        var maxCalories = Self.firstInt(in: container, keys: [.totalCaloriesMax, .maxCalories]) ?? exactCalories ?? minCalories
        if maxCalories < minCalories {
            swap(&minCalories, &maxCalories)
        }

        self.foodList = Self.firstString(in: container, keys: [.foodList, .food, .foods, .items])
            ?? (decodedItems.isEmpty ? "Unknown Food" : decodedItems.map(\.name).joined(separator: ", "))
        self.totalCaloriesMin = minCalories
        self.totalCaloriesMax = maxCalories
        self.reasoning = Self.firstString(in: container, keys: [.reasoning, .analysis, .explanation]) ?? ""
        self.macros = try container.decodeIfPresent(Macronutrients.self, forKey: .macros) ?? Self.flatMacros(from: container)
        self.healthTip = try container.decodeIfPresent(String.self, forKey: .healthTip)
        self.itemEstimates = decodedItems
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(foodList, forKey: .foodList)
        try container.encode(totalCaloriesMin, forKey: .totalCaloriesMin)
        try container.encode(totalCaloriesMax, forKey: .totalCaloriesMax)
        try container.encode(reasoning, forKey: .reasoning)
        try container.encodeIfPresent(macros, forKey: .macros)
        try container.encodeIfPresent(healthTip, forKey: .healthTip)
        if !itemEstimates.isEmpty {
            try container.encode(itemEstimates, forKey: .itemEstimates)
        }
    }

    private static func firstString(in container: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) -> String? {
        for key in keys {
            if let value = try? container.decode(String.self, forKey: key), !value.isEmpty {
                return value
            }
            if let values = try? container.decode([String].self, forKey: key), !values.isEmpty {
                return values.joined(separator: ", ")
            }
        }
        return nil
    }

    private static func firstInt(in container: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) -> Int? {
        for key in keys {
            if let value = try? container.decode(Int.self, forKey: key) {
                return value
            }
            if let value = try? container.decode(Double.self, forKey: key) {
                return Int(value.rounded())
            }
            if let value = try? container.decode(String.self, forKey: key), let intValue = Int(value) {
                return intValue
            }
        }
        return nil
    }

    private static func flatMacros(from container: KeyedDecodingContainer<CodingKeys>) -> Macronutrients? {
        guard
            let protein = firstInt(in: container, keys: [.protein]),
            let carbs = firstInt(in: container, keys: [.carbs, .carbohydrates]),
            let fat = firstInt(in: container, keys: [.fat])
        else {
            return nil
        }
        return Macronutrients(protein: protein, carbs: carbs, fat: fat)
    }

    func sanitizedForDisplay(language: AppLanguage) -> CloudResponsePayload {
        CloudResponsePayload(
            foodList: AIOutputSafetyGuard.safeFoodText(foodList, language: language),
            totalCaloriesMin: max(0, min(totalCaloriesMin, totalCaloriesMax)),
            totalCaloriesMax: max(0, max(totalCaloriesMin, totalCaloriesMax)),
            reasoning: AIOutputSafetyGuard.safeReasoning(reasoning, language: language) ?? "",
            macros: macros,
            healthTip: MedicalSafetyFilter.safeHealthTip(healthTip, language: language),
            itemEstimates: itemEstimates.map { $0.sanitizedForDisplay(language: language) }
        )
    }

    var safeFoodList: String { safeFoodList(language: .unitedStates) }
    func safeFoodList(language: AppLanguage) -> String { AIOutputSafetyGuard.safeFoodText(foodList, language: language) }
    var safeMin: Int { totalCaloriesMin }; var safeMax: Int { totalCaloriesMax }
    var safeReasoning: String? { safeReasoning(language: .unitedStates) }
    func safeReasoning(language: AppLanguage) -> String? { AIOutputSafetyGuard.safeReasoning(reasoning, language: language) }
    var safeHealthTip: String? { MedicalSafetyFilter.safeHealthTip(healthTip) }
    func safeHealthTip(language: AppLanguage) -> String? { MedicalSafetyFilter.safeHealthTip(healthTip, language: language) }

    var averageSafeCalories: Int {
        (safeMin + safeMax) / 2
    }

    var mealLogAssessment: MealLogAssessment {
        MealLoggingClassifier.assess(self)
    }
}

enum MealLogConfirmationReason: Equatable {
    case sharedSpread
    case bulkQuantity
    case broadEstimate
    case ambiguousPortion

    var messageKey: String {
        switch self {
        case .sharedSpread: return "meal_log.confirm_shared"
        case .bulkQuantity: return "meal_log.confirm_bulk"
        case .broadEstimate: return "meal_log.confirm_broad"
        case .ambiguousPortion: return "meal_log.confirm_ambiguous"
        }
    }
}

struct MealLogAssessment: Equatable {
    let requiresConfirmation: Bool
    let reason: MealLogConfirmationReason?

    static let direct = MealLogAssessment(requiresConfirmation: false, reason: nil)

    static func confirm(_ reason: MealLogConfirmationReason) -> MealLogAssessment {
        MealLogAssessment(requiresConfirmation: true, reason: reason)
    }

    func confirmationMessage(calories: Int, language: AppLanguage) -> String {
        TranslationManager.get(reason?.messageKey ?? "meal_log.confirm_ambiguous", lang: language, args: [calories])
    }
}

struct MealLoggingClassifier {
    static func assess(_ payload: CloudResponsePayload) -> MealLogAssessment {
        let text = searchableText(for: payload)
        let itemCount = payload.itemEstimates.count
        let maxCalories = payload.safeMax
        let calorieRange = payload.safeMax - payload.safeMin
        let hasMealAnchor = containsAny(mealAnchorKeywords, in: text)

        if containsAny(sharedSpreadKeywords, in: text) {
            return .confirm(.sharedSpread)
        }

        if containsAny(bulkQuantityKeywords, in: text) {
            return .confirm(.bulkQuantity)
        }

        if maxCalories >= 2_200 || (maxCalories >= 1_600 && itemCount >= 5) {
            return .confirm(.sharedSpread)
        }

        if calorieRange >= 1_000 && maxCalories >= 1_500 {
            return .confirm(.broadEstimate)
        }

        if itemCount >= 7 && !hasMealAnchor {
            return .confirm(.ambiguousPortion)
        }

        return .direct
    }

    private static func searchableText(for payload: CloudResponsePayload) -> String {
        let itemText = payload.itemEstimates
            .map { [$0.name, $0.portionDescription, $0.portionBasis].compactMap { $0 }.joined(separator: " ") }
            .joined(separator: " ")
        return [payload.foodList, payload.reasoning, itemText]
            .joined(separator: " ")
            .lowercased()
    }

    private static func containsAny(_ keywords: [String], in text: String) -> Bool {
        keywords.contains { text.contains($0.lowercased()) }
    }

    private static let sharedSpreadKeywords = [
        "shared table", "table spread", "table of", "buffet", "family-style", "family style",
        "party platter", "banquet", "shared dishes", "many dishes", "for sharing", "multi-person",
        "一桌", "整桌", "桌菜", "合菜", "共享", "多人", "聚餐", "宴席", "自助餐", "多人份",
        "食卓全体", "食卓", "大皿料理", "取り分け", "シェア", "宴会", "ビュッフェ", "複数人"
    ]

    private static let bulkQuantityKeywords = [
        "bunch", "cluster", "whole bag", "bag of", "box of", "package of", "pile", "heap",
        "basket", "tray of", "platter of", "bulk", "groceries", "ingredients", "whole package",
        "一串", "一堆", "整袋", "整包", "整盒", "整箱", "一籃", "一袋", "一盒", "一箱",
        "一大盤", "一整盤", "未分食", "食材", "整串",
        "房", "束", "袋入り", "箱入り", "山盛り", "盛り合わせ", "パック", "食材", "まとめ買い"
    ]

    private static let mealAnchorKeywords = [
        "meal", "plate", "bowl", "set meal", "bento", "lunch", "dinner", "breakfast",
        "serving", "single serving", "portion", "one-person", "one person",
        "餐", "便當", "飯盒", "套餐", "餐盒", "一人份", "一份", "單人", "盤餐", "碗",
        "弁当", "定食", "一食", "一人前", "ランチ", "夕食", "朝食", "丼", "皿"
    ]
}

enum CalorieEstimatorError: Error, LocalizedError, Equatable {
    case imageConversionFailed
    case jsonEncodingFailed
    case invalidAPIURL
    case invalidHTTPResponse
    case serverRejected(statusCode: Int, message: String)
    case responseDecodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Could not prepare the image for analysis."
        case .jsonEncodingFailed:
            return "Could not prepare the analysis request."
        case .invalidAPIURL:
            return "Invalid API URL."
        case .invalidHTTPResponse:
            return "Invalid server response."
        case .serverRejected(let statusCode, let message):
            return "Server error \(statusCode): \(message)"
        case .responseDecodingFailed(let message):
            return "Could not read the AI response: \(message)"
        }
    }
}
struct AnalysisProgress: Equatable {
    let message: String
    let detail: String
    let fraction: Double

    var clampedFraction: Double {
        min(max(fraction, 0), 1)
    }

    var percentage: Int {
        Int((clampedFraction * 100).rounded())
    }
}

enum ViewState: Equatable { case empty, loading(AnalysisProgress), success(CloudResponsePayload), error(String) }

extension String {
    var truncatedForErrorMessage: String {
        let singleLine = replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard singleLine.count > 240 else { return singleLine.isEmpty ? "No response body." : singleLine }
        return String(singleLine.prefix(240)) + "..."
    }
}

struct DailyFreeUsage: Codable, Equatable {
    let dateKey: String
    let usedCount: Int
}

struct FreeScanLimiter {
    let dailyLimit: Int
    var calendar: Calendar = .autoupdatingCurrent

    private var effectiveDailyLimit: Int {
        max(0, dailyLimit)
    }

    func dateKey(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    func normalizedUsage(_ usage: DailyFreeUsage?, now: Date) -> DailyFreeUsage {
        let todayKey = dateKey(for: now)
        guard let usage, usage.dateKey == todayKey else {
            return DailyFreeUsage(dateKey: todayKey, usedCount: 0)
        }
        return DailyFreeUsage(dateKey: todayKey, usedCount: min(effectiveDailyLimit, max(0, usage.usedCount)))
    }

    func remainingCount(usage: DailyFreeUsage?, now: Date, isPro: Bool, proDisplayCount: Int = 999) -> Int {
        if isPro { return proDisplayCount }
        let usage = normalizedUsage(usage, now: now)
        return max(0, effectiveDailyLimit - usage.usedCount)
    }

    func canStartAnalysis(usage: DailyFreeUsage?, now: Date, isPro: Bool, bypass: Bool) -> Bool {
        isPro || bypass || normalizedUsage(usage, now: now).usedCount < effectiveDailyLimit
    }

    func usageAfterSuccessfulAnalysis(usage: DailyFreeUsage?, now: Date, isPro: Bool, bypass: Bool) -> DailyFreeUsage {
        let usage = normalizedUsage(usage, now: now)
        guard !isPro && !bypass else { return usage }
        return DailyFreeUsage(dateKey: usage.dateKey, usedCount: min(effectiveDailyLimit, usage.usedCount + 1))
    }

    func usageAfterFailedAnalysis(usage: DailyFreeUsage?, now: Date) -> DailyFreeUsage {
        normalizedUsage(usage, now: now)
    }
}

enum SubscriptionAccessPolicy {
    static let proEntitlementIdentifier = "pro"

    static func hasActiveProEntitlement<EntitlementIDs: Sequence>(_ activeEntitlementIDs: EntitlementIDs) -> Bool where EntitlementIDs.Element == String {
        activeEntitlementIDs.contains(proEntitlementIdentifier)
    }
}

// [Modified] AppLanguage with market-specific language regions.
enum AppLanguage: String, CaseIterable, Identifiable {
    case unitedStates = "en-US"
    case japan = "ja-JP"

    // Legacy/internal translation buckets retained for old saved values and fallbacks.
    case traditionalChinese = "zh-Hant"
    case english = "en"
    case japanese = "ja"

    static let allCases: [AppLanguage] = [.traditionalChinese, .unitedStates, .japan]

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .unitedStates: return "United States · English"
        case .japan: return "日本 · 日本語"
        case .english: return "English"
        case .japanese: return "日本語"
        case .traditionalChinese: return "台灣 · 繁體中文"
        }
    }

    var compactDisplayName: String {
        switch self {
        case .unitedStates, .english: return "EN"
        case .japan, .japanese: return "日本語"
        case .traditionalChinese: return "繁中"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .unitedStates, .japan, .traditionalChinese:
            return rawValue
        case .english:
            return AppLanguage.unitedStates.rawValue
        case .japanese:
            return AppLanguage.japan.rawValue
        }
    }

    var aiLanguageCode: String {
        switch self {
        case .english:
            return AppLanguage.unitedStates.rawValue
        case .japanese:
            return AppLanguage.japan.rawValue
        default:
            return rawValue
        }
    }

    var translationBase: AppLanguage {
        switch self {
        case .unitedStates, .english:
            return .english
        case .japan, .japanese:
            return .japanese
        case .traditionalChinese:
            return .traditionalChinese
        }
    }

    static func fromStored(_ rawValue: String) -> AppLanguage? {
        switch rawValue {
        case "en", "en-GB", "en-IE", "en-AU", "en-NZ":
            return .unitedStates
        case "ja":
            return .japan
        case "zh-Hant", "zh-TW", "zh-HK", "zh-Hans", "zh-CN":
            return .traditionalChinese
        default:
            return AppLanguage(rawValue: rawValue)
        }
    }

    static func initialSelection(savedRawValue: String, hasUserSelectedPreference: Bool, systemPreferred: AppLanguage) -> (language: AppLanguage, shouldPersistAsUserPreference: Bool) {
        if hasUserSelectedPreference, let saved = fromStored(savedRawValue) {
            return (saved, true)
        }

        if let legacySaved = fromStored(savedRawValue), !savedRawValue.isEmpty, legacySaved != systemPreferred {
            return (legacySaved, true)
        }

        return (systemPreferred, false)
    }

    // Detect the user's preferred language on first launch; manual app choices are handled separately.
    static var systemPreferred: AppLanguage {
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? "en-us"

        if preferred.hasPrefix("zh") {
            return .traditionalChinese
        }
        if preferred.hasPrefix("ja") {
            return .japan
        }
        return .unitedStates
    }
}

enum ServerStatus {
    case unknown, checking, online, offline
    var color: Color { switch self { case .unknown: return .gray; case .checking: return .orange; case .online: return .green; case .offline: return .red } }
    var label: LocalizedStringKey { switch self { case .unknown: return "status.server.unknown"; case .checking: return "status.server.checking"; case .online: return "status.server.online"; case .offline: return "status.server.offline" } }

    func label(lang: AppLanguage) -> String {
        switch self {
        case .unknown: return TranslationManager.get("status.server.unknown", lang: lang)
        case .checking: return TranslationManager.get("status.server.checking", lang: lang)
        case .online: return TranslationManager.get("status.server.online", lang: lang)
        case .offline: return TranslationManager.get("status.server.offline", lang: lang)
        }
    }
}

extension UIImage {
    func resizeTo(maxDimension: CGFloat) -> UIImage {
        let size = self.size; if size.width <= 0 || size.height <= 0 { return self }
        let ratio = size.width / size.height; let newSize = size.width > size.height ? CGSize(width: min(size.width, maxDimension), height: min(size.width, maxDimension) / ratio) : CGSize(width: min(size.height, maxDimension) * ratio, height: min(size.height, maxDimension))
        if newSize.width <= 0 || newSize.height <= 0 { return self }; return UIGraphicsImageRenderer(size: newSize).image { _ in draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}

struct KeychainHelper {
    static let service = "com.aicounter.service"

    private static func baseQuery(key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }

    static func save(data: Data, key: String) {
        let query = baseQuery(key: key)
        SecItemDelete(query as CFDictionary)

        var item = query
        item[kSecValueData as String] = data
        SecItemAdd(item as CFDictionary, nil)
    }

    static func readData(key: String) -> Data? {
        var query = baseQuery(key: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }

    static func save<Value: Encodable>(_ value: Value, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        save(data: data, key: key)
    }

    static func read<Value: Decodable>(_ type: Value.Type, key: String) -> Value? {
        guard let data = readData(key: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    static func save(count: Int, key: String) {
        let data = Data(withUnsafeBytes(of: count) { Data($0) })
        save(data: data, key: key)
    }

    static func read(key: String) -> Int {
        guard let data = readData(key: key), data.count == MemoryLayout<Int>.size else { return 0 }
        var value = 0
        withUnsafeMutableBytes(of: &value) { valueBuffer in
            _ = data.copyBytes(to: valueBuffer)
        }
        return value
    }
}
