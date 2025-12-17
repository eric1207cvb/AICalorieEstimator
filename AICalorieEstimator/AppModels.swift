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
        switch self {
        case .male: return "男性 (Male)"
        case .female: return "女性 (Female)"
        case .notSet: return "未設定 (Not Set)"
        }
    }
}

// --- 翻譯管理器 ---
struct TranslationManager {
    static func get(_ key: String, lang: AppLanguage, args: [CVarArg] = []) -> String {
        let table: [String: [AppLanguage: String]] = [
            "hint.loading_upload": [.traditionalChinese: "上傳美食照...", .english: "Uploading...", .japanese: "アップロード中..."],
            "hint.loading_ai": [.traditionalChinese: "AI 正在分析飲食內容...", .english: "AI Analyzing Diet...", .japanese: "AIが食事を分析中..."],
            "hint.loading_ocr": [.traditionalChinese: "讀取包裝標示...", .english: "Reading Label...", .japanese: "ラベル読み取り..."],
            "hint.initial": [.traditionalChinese: "準備好分析美食了嗎？", .english: "Ready to Analyze?", .japanese: "分析の準備はいいですか？"],
            
            "result.items_found": [.traditionalChinese: "辨識結果", .english: "Detected Food", .japanese: "検出された食品"],
            "result.calorie_estimate": [.traditionalChinese: "熱量估算", .english: "Calories", .japanese: "カロリー推定"],
            "result.ai_comment": [.traditionalChinese: "AI 分析觀點", .english: "AI Insight", .japanese: "AI分析"],
            "result.health_advice": [.traditionalChinese: "飲食建議", .english: "Health Tip", .japanese: "食事のアドバイス"],
            
            "ring.target_title": [.traditionalChinese: "今日預算", .english: "Daily Budget", .japanese: "目安摂取量"],
            "ring.intake_title": [.traditionalChinese: "已攝取", .english: "Intake", .japanese: "摂取済み"],
            "ring.status_over": [.traditionalChinese: "超出預算", .english: "Over Budget", .japanese: "目安超過"],
            "ring.status_remain": [.traditionalChinese: "剩餘額度", .english: "Remaining", .japanese: "残り"],
            "ring.advice_over": [.traditionalChinese: "建議多動動", .english: "Move More", .japanese: "運動しましょ"],
            "ring.advice_good": [.traditionalChinese: "控制精準", .english: "On Track", .japanese: "順調です"],
            
            "dash.edit_title": [.traditionalChinese: "編輯身體數據", .english: "Edit Profile", .japanese: "身体データの編集"],
            "dash.edit_subtitle": [.traditionalChinese: "更新體重與目標", .english: "Update Weight & Goal", .japanese: "体重と目標の更新"],
            "dash.advice_header": [.traditionalChinese: "🎯 本階段指引", .english: "🎯 Stage Guide", .japanese: "🎯 今の指針"],
            
            "health.steps": [.traditionalChinese: "今日步數", .english: "Steps", .japanese: "歩数"],
            "health.weight_goal": [.traditionalChinese: "目標體重", .english: "Goal Weight", .japanese: "目標体重"],
            "health.coach_title": [.traditionalChinese: "每日健康指引", .english: "Daily Guide", .japanese: "健康ガイド"],
            "health.to_target": [.traditionalChinese: "距離目標還有 %.1f kg", .english: "%.1f kg to go", .japanese: "あと %.1f kg"],
            "profile.gender": [.traditionalChinese: "生理性別", .english: "Sex", .japanese: "性別"],
            
            "chart.title": [.traditionalChinese: "近七日攝取趨勢", .english: "7-Day Trend", .japanese: "週間傾向"],
            "chart.unit": [.traditionalChinese: "大卡 (kcal)", .english: "kcal", .japanese: "kcal"],
            "button.add_to_log": [.traditionalChinese: "🍽️ 紀錄這餐", .english: "Log Meal", .japanese: "記録する"],
            "button.logged": [.traditionalChinese: "✅ 已完成紀錄", .english: "Logged", .japanese: "記録済み"],
            "button.take_photo": [.traditionalChinese: "拍照分析", .english: "Take Photo", .japanese: "写真を撮る"],
            "button.select_album": [.traditionalChinese: "從相簿選取", .english: "Album", .japanese: "アルバム"],
            
            "profile.title": [.traditionalChinese: "個人檔案", .english: "Profile", .japanese: "プロフィール"],
            "profile.height": [.traditionalChinese: "身高", .english: "Height", .japanese: "身長"],
            "profile.weight": [.traditionalChinese: "體重", .english: "Weight", .japanese: "体重"],
            "profile.sync_health": [.traditionalChinese: "同步健康資料", .english: "Sync Health", .japanese: "ヘルスケア同期"],
            
            "status.pro_active": [.traditionalChinese: "👑 專業版會員", .english: "👑 Pro Member", .japanese: "👑 プロ会員"],
            "status.free_remaining": [.traditionalChinese: "免費額度剩餘 %d 次", .english: "%d Free Scans Left", .japanese: "残り %d 回"],
            "status.free_exhausted": [.traditionalChinese: "免費額度已用完", .english: "Free Limit Reached", .japanese: "無料枠終了"],
            "status.upgrade_pro": [.traditionalChinese: "升級無限用", .english: "Upgrade", .japanese: "無制限プラン"],
            "alert.no_credits": [.traditionalChinese: "次數已用完，請升級專業版以繼續使用。", .english: "No credits left. Please upgrade to continue.", .japanese: "回数制限です。プロ版にアップグレードしてください。"],
            
            "badge.deficit_title": [.traditionalChinese: "🔥 熱量赤字達成", .english: "🔥 Deficit Hit", .japanese: "🔥 カロリー赤字"],
            "badge.deficit_desc": [.traditionalChinese: "本週少攝取 %d kcal", .english: "-%d kcal this week", .japanese: "-%d kcal"],
        ]
        let format = table[key]?[lang] ?? key
        return String(format: format, arguments: args)
    }
}

struct InsightResult {
    let title: String
    let advice: String
    let knowledge: String
}

// --- Health Coach ---
struct HealthCoach {
    static func getDailyKnowledge(lang: AppLanguage) -> String {
        let index = (Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0) % 7
        switch lang {
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
        case .english:
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
        case .japanese:
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
        let tdee = profile.dailyCalorieLimit
        let diff = profile.currentWeight - profile.targetWeight
        let knowledge = getDailyKnowledge(lang: lang)
        let isMaintenance = profile.targetWeight <= 0 || abs(diff) < 1.0
        let isWeightLoss = !isMaintenance && diff > 0
        let bmi = profile.bmiValue
        
        var title = ""
        var advice = ""
        
        switch lang {
        case .traditionalChinese:
            if isMaintenance {
                if bmi > 24.0 {
                    title = "⚠️ 體重注意 (BMI: \(String(format: "%.1f", bmi)))"
                    advice = "雖然您未設定減重目標，但目前 BMI 已進入過重範圍。\n為了心血管健康，建議：\n1. 控制精緻澱粉攝取。\n2. 每日步數嘗試達到 8,000 步。"
                } else if bmi < 18.5 && bmi > 0 {
                    title = "⚠️ 體重偏輕 (BMI: \(String(format: "%.1f", bmi)))"
                    advice = "目前 BMI 低於標準，可能影響免疫力。\n建議：\n1. 確保每日熱量攝取達標。\n2. 多補充優質蛋白質與堅果等好油。"
                } else {
                    title = "🌿 健康維持模式"
                    if profile.stepCount < 6000 {
                        advice = "體重標準，但今日活動量偏低 (\(profile.stepCount) 步)。\n建議多起來走動，維持基礎代謝率。"
                    } else {
                        advice = "太棒了！BMI 標準且活動量充足 (\(profile.stepCount) 步)。\n請繼續保持均衡飲食與良好作息。"
                    }
                }
            } else if isWeightLoss {
                if diff > 5.0 {
                    title = "🏋️‍♂️ 減重啟動期"
                    advice = "建立習慣最重要：\n1. 戒除含糖飲料。\n2. 晚餐澱粉減半。\n3. 每天快走 30 分鐘。"
                } else if diff > 2.0 {
                    title = "🔥 燃脂穩定期"
                    advice = "進展不錯！若停滯可嘗試：\n1. 增加間歇運動 (HIIT)。\n2. 實施 168 斷食。\n3. 減少水果攝取。"
                } else {
                    title = "🏆 最後衝刺期"
                    advice = "只差一點了！\n1. 控制鈉含量(消水腫)。\n2. 增加蛋白質維持肌肉。\n3. 睡前 3 小時禁食。"
                }
                if todayCalories > tdee { advice = "🚨 今日熱量超標！建議這餐只吃蔬菜與蛋白質，飯後散步 20 分鐘補救。" }
            } else {
                title = "💪 增肌建設期"
                advice = "1. 訓練前後補充足夠碳水。\n2. 每日蛋白質吃到體重 x 1.5倍。\n3. 攝取優質油脂。"
            }
            
        case .english:
            if isMaintenance {
                if bmi > 25.0 {
                    title = "⚠️ BMI Alert: \(String(format: "%.1f", bmi))"
                    advice = "BMI indicates overweight.\n1. Limit refined carbs.\n2. Aim for 8,000 steps daily."
                } else if bmi < 18.5 && bmi > 0 {
                    title = "⚠️ Low BMI: \(String(format: "%.1f", bmi))"
                    advice = "BMI is below standard.\n1. Meet daily calories.\n2. Add healthy fats."
                } else {
                    title = "🌿 Maintenance Mode"
                    advice = profile.stepCount < 6000 ? "Activity is low. Walk more." : "Great job! Keep it up."
                }
            } else if isWeightLoss {
                title = diff > 5.0 ? "🏋️‍♂️ Start Phase" : (diff > 2.0 ? "🔥 Fat Burn Phase" : "🏆 Final Sprint")
                advice = "Keep moving and watch your diet."
                if todayCalories > tdee { advice = "🚨 Over budget! Walk for 20 mins." }
            } else {
                title = "💪 Muscle Gain"
                advice = "Prioritize protein and healthy fats."
            }
            
        case .japanese:
            if isMaintenance {
                if bmi > 25.0 {
                    title = "⚠️ BMI注意: \(String(format: "%.1f", bmi))"
                    advice = "BMIが高めです。\n1. 糖質を控える。\n2. 1日8,000歩を目指す。"
                } else if bmi < 18.5 && bmi > 0 {
                    title = "⚠️ 低BMI注意: \(String(format: "%.1f", bmi))"
                    advice = "BMIが低いです。\n1. 摂取カロリーを確保。\n2. 良質な脂質を摂る。"
                } else {
                    title = "🌿 健康維持モード"
                    advice = profile.stepCount < 6000 ? "歩数が少ないです。歩きましょう。" : "素晴らしい！その調子です。"
                }
            } else if isWeightLoss {
                title = diff > 5.0 ? "🏋️‍♂️ 減量開始期" : (diff > 2.0 ? "🔥 燃焼安定期" : "🏆 ラストスパート")
                advice = "運動と食事制限を続けましょう。"
                if todayCalories > tdee { advice = "🚨 カロリー超過！食後に散歩しましょう。" }
            } else {
                title = "💪 増量期"
                advice = "タンパク質を意識しましょう。"
            }
        }
        
        return InsightResult(title: title, advice: advice, knowledge: knowledge)
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
    
    var dailyCalorieLimit: Int {
        // Smart Default based on Gender
        if currentWeight <= 0 {
            switch gender {
            case .male: return 2000
            case .female: return 1500
            default: return 1600
            }
        }
        
        let base = basalEnergy > 0 ? basalEnergy : (currentWeight * 24)
        let mult = stepCount < 3000 ? 1.2 : (stepCount < 8000 ? 1.375 : (stepCount < 12000 ? 1.55 : 1.725))
        var tdee = base * mult
        
        if targetWeight > 0 {
            if targetWeight < (currentWeight - 1.0) { tdee -= 300 }
            if targetWeight > (currentWeight + 1.0) { tdee += 300 }
        }
        
        return max(1200, Int(tdee))
    }
}

// --- Networking & States ---
struct RequestPayload: Codable { let image: String; let language: String; let userProfile: UserProfile?; let detectedText: String?; let mealTime: String }
struct Macronutrients: Codable, Equatable { let protein: Int; let carbs: Int; let fat: Int }
struct CloudResponsePayload: Codable, Equatable {
    let foodList: String; let totalCaloriesMin: Int; let totalCaloriesMax: Int; let reasoning: String; let macros: Macronutrients?; let healthTip: String?
    var safeFoodList: String { foodList.isEmpty ? "Unknown Food" : foodList }
    var safeMin: Int { totalCaloriesMin }; var safeMax: Int { totalCaloriesMax }
}
enum CalorieEstimatorError: Error, LocalizedError { case imageConversionFailed, jsonEncodingFailed, invalidAPIURL; var errorDescription: String? { "Processing Error" } }
enum ViewState: Equatable { case empty, loading(String), success(CloudResponsePayload), error(String) }

// [Modified] AppLanguage with Auto-Detection
enum AppLanguage: String, CaseIterable, Identifiable {
    case traditionalChinese = "zh-Hant"
    case english = "en"
    case japanese = "ja"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .japanese: return "日本語"
        case .traditionalChinese: return "繁體中文"
        }
    }
    
    // 👇 智慧語系偵測邏輯
    static var systemPreferred: AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        
        if preferred.contains("zh-Hant") || preferred.contains("zh-TW") || preferred.contains("zh-HK") {
            return .traditionalChinese
        } else if preferred.contains("zh-Hans") || preferred.contains("zh-CN") {
            return .traditionalChinese // 簡體用戶回退到繁體
        } else if preferred.contains("ja") {
            return .japanese
        } else {
            return .english // 其他所有國家 (US/UK/AU/IN...)
        }
    }
}

enum ServerStatus {
    case unknown, checking, online, offline
    var color: Color { switch self { case .unknown: return .gray; case .checking: return .orange; case .online: return .green; case .offline: return .red } }
    var label: LocalizedStringKey { switch self { case .unknown: return "status.server.unknown"; case .checking: return "status.server.checking"; case .online: return "status.server.online"; case .offline: return "status.server.offline" } }
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
    static func save(count: Int, key: String) { let data = Data(withUnsafeBytes(of: count) { Data($0) }); SecItemDelete([kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: key] as CFDictionary); SecItemAdd([kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: key, kSecValueData: data] as CFDictionary, nil) }
    static func read(key: String) -> Int { var res: AnyObject?; SecItemCopyMatching([kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: key, kSecReturnData: true, kSecMatchLimit: kSecMatchLimitOne] as CFDictionary, &res); return (res as? Data)?.withUnsafeBytes { $0.load(as: Int.self) } ?? 0 }
}
