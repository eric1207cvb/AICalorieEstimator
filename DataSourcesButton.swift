import SwiftUI

struct DataSourcesButton: View {
    enum Style { case compact, capsule }

    var title: String?
    var style: Style = .capsule
    var language: AppLanguage = .unitedStates

    @State private var isPresented = false

    init(title: String? = nil, style: Style = .capsule, language: AppLanguage = .unitedStates) {
        self.title = title
        self.style = style
        self.language = language
    }

    private enum LangCategory { case zhHant, ja, en }
    private var langCategory: LangCategory {
        switch language.translationBase {
        case .traditionalChinese: return .zhHant
        case .japanese, .japan: return .ja
        default: return .en
        }
    }

    private enum SourceTopic {
        case nutrition
        case diabetes
        case ckd

        var iconName: String {
            switch self {
            case .nutrition: return "fork.knife"
            case .diabetes: return "drop.fill"
            case .ckd: return "heart.text.square.fill"
            }
        }

        var tint: Color {
            switch self {
            case .nutrition: return .green
            case .diabetes: return .orange
            case .ckd: return .blue
            }
        }

        func label(lang: AppLanguage) -> String {
            switch lang.translationBase {
            case .traditionalChinese:
                switch self {
                case .nutrition: return "營養估算"
                case .diabetes: return "糖尿病"
                case .ckd: return "CKD"
                }
            case .japanese:
                switch self {
                case .nutrition: return "栄養推定"
                case .diabetes: return "糖尿病"
                case .ckd: return "CKD"
                }
            default:
                switch self {
                case .nutrition: return "Nutrition"
                case .diabetes: return "Diabetes"
                case .ckd: return "CKD"
                }
            }
        }
    }

    private struct Source: Identifiable {
        let id = UUID()
        let title: String
        let url: URL
        let reference: String
        let topic: SourceTopic
        let priority: MedicalSourcePriority?

        init(title: String, url: URL, reference: String, topic: SourceTopic = .nutrition, priority: MedicalSourcePriority? = nil) {
            self.title = title
            self.url = url
            self.reference = reference
            self.topic = topic
            self.priority = priority
        }

        var domainLabel: String {
            (url.host ?? url.absoluteString)
                .replacingOccurrences(of: "www.", with: "")
        }
    }
    private var orderedSources: [Source] {
        let reference = TranslationManager.get("data_sources.calorie_reference", lang: language)
        let usda = Source(title: titleForUSDA, url: URL(string: "https://fdc.nal.usda.gov/")!, reference: reference)
        let tfda = Source(title: titleForTFDA, url: URL(string: "https://consumer.fda.gov.tw/Food/TFND.aspx")!, reference: reference)
        let mext = Source(title: titleForMEXT, url: URL(string: "https://www.mext.go.jp/")!, reference: reference)
        switch langCategory {
        case .zhHant: return [tfda, usda, mext]
        case .ja:     return [mext, usda, tfda]
        case .en:     return [usda, tfda, mext]
        }
    }

    private var medicalSources: [Source] {
        switch langCategory {
        case .zhHant:
            return [
                Source(title: "衛生福利部國民健康署 糖尿病防治", url: URL(string: "https://www.hpa.gov.tw/Pages/List.aspx?nodeid=359")!, reference: "糖尿病模式優先引用：均衡飲食、規律追蹤與醫療團隊個別化照護。", topic: .diabetes, priority: .localizedPrimary),
                Source(title: "衛生福利部國民健康署 糖尿病與我", url: URL(string: "https://health99.hpa.gov.tw/material/3404")!, reference: "糖尿病模式優先引用：固定醣量、高纖、適量油脂、血糖自我監測。", topic: .diabetes, priority: .localizedPrimary),
                Source(title: "衛生福利部國民健康署 慢性腎臟病防治", url: URL(string: "https://www.hpa.gov.tw/Pages/List.aspx?nodeid=635")!, reference: "CKD 模式優先引用：一般飲食風險、追蹤與專業照護。", topic: .ckd, priority: .localizedPrimary),
                Source(title: "衛生福利部國民健康署 慢性腎臟病健康管理手冊", url: URL(string: "https://www.hpa.gov.tw/Pages/List.aspx?nodeid=1157")!, reference: "CKD 模式優先引用：依分期與檢驗值調整鈉、鉀、磷與蛋白質，並以腎臟營養師建議為準。", topic: .ckd, priority: .localizedPrimary),
                Source(title: "ADA Standards of Care in Diabetes", url: URL(string: "https://professional.diabetes.org/standards-of-care")!, reference: "糖尿病模式輔助引用：個人化營養照護與避免診斷、藥物劑量建議。", topic: .diabetes, priority: .supplemental),
                Source(title: "CDC Diabetes Meal Planning", url: URL(string: "https://www.cdc.gov/diabetes/healthy-eating/diabetes-meal-planning.html")!, reference: "糖尿病模式輔助引用：餐盤法、醣量估算、份量意識與規律均衡用餐。", topic: .diabetes, priority: .supplemental),
                Source(title: "NICE Type 2 Diabetes Dietary Advice", url: URL(string: "https://www.nice.org.uk/guidance/ng28/chapter/Dietary-advice-and-interventions")!, reference: "糖尿病模式輔助引用：營養建議需尊重個人需求、文化、意願與生活品質。", topic: .diabetes, priority: .supplemental),
                Source(title: "KDIGO 2024 CKD Guideline", url: URL(string: "https://kdigo.org/wp-content/uploads/2024/03/KDIGO-2024-CKD-Guideline.pdf")!, reference: "CKD 模式輔助引用：健康多元飲食、減鈉、G3-G5 蛋白質與個別化營養諮詢。", topic: .ckd, priority: .supplemental),
                Source(title: "NIDDK Healthy Eating for Adults with CKD", url: URL(string: "https://www.niddk.nih.gov/health-information/kidney-disease/chronic-kidney-disease-ckd/healthy-eating-adults-chronic-kidney-disease")!, reference: "CKD 模式輔助引用：CKD 沒有單一飲食模板，需依分期與醫療團隊目標調整。", topic: .ckd, priority: .supplemental),
                Source(title: "NICE CKD Assessment and Management", url: URL(string: "https://www.nice.org.uk/guidance/ng203/chapter/Recommendations")!, reference: "CKD 模式輔助引用：鉀、磷、熱量與鹽分建議需符合 CKD 嚴重度。", topic: .ckd, priority: .supplemental)
            ]
        case .ja:
            return [
                Source(title: "日本糖尿病学会 糖尿病診療ガイドライン2024", url: URL(string: "https://www.jds.or.jp/modules/publication/index.php?content_id=40")!, reference: "糖尿病モードの優先参照：食事療法、血糖管理、低血糖リスク時の医療者指示優先。", topic: .diabetes, priority: .localizedPrimary),
                Source(title: "糖尿病情報センター 食事のはなし", url: URL(string: "https://dmic.jihs.go.jp/general/about-dm/040/020/02-1.html")!, reference: "糖尿病モードの優先参照：適正エネルギー、バランスのよい規則的な食事。", topic: .diabetes, priority: .localizedPrimary),
                Source(title: "日本腎臓学会 CKD診療ガイドライン2023", url: URL(string: "https://cdn.jsn.or.jp/medic/guideline/pdf/guide/001-294.pdf")!, reference: "CKDモードの優先参照：ステージと検査値に応じた食塩、たんぱく質、カリウム、リンの個別調整。", topic: .ckd, priority: .localizedPrimary),
                Source(title: "日本腎臓病協会 CKDの予防と治療", url: URL(string: "https://j-ka.or.jp/ckd/care.php")!, reference: "CKDモードの優先参照：医療者の診療と生活習慣支援を組み合わせる範囲。", topic: .ckd, priority: .localizedPrimary),
                Source(title: "ADA Standards of Care in Diabetes", url: URL(string: "https://professional.diabetes.org/standards-of-care")!, reference: "糖尿病モードの補足参照：個別化された栄養ケア、診断や薬剤量提示を避ける範囲。", topic: .diabetes, priority: .supplemental),
                Source(title: "CDC Diabetes Meal Planning", url: URL(string: "https://www.cdc.gov/diabetes/healthy-eating/diabetes-meal-planning.html")!, reference: "糖尿病モードの補足参照：プレート法、炭水化物量、量の把握、規則的でバランスのよい食事。", topic: .diabetes, priority: .supplemental),
                Source(title: "NICE Type 2 Diabetes Dietary Advice", url: URL(string: "https://www.nice.org.uk/guidance/ng28/chapter/Dietary-advice-and-interventions")!, reference: "糖尿病モードの補足参照：本人のニーズ、文化、意欲、生活の質に配慮した栄養助言。", topic: .diabetes, priority: .supplemental),
                Source(title: "KDIGO 2024 CKD Guideline", url: URL(string: "https://kdigo.org/wp-content/uploads/2024/03/KDIGO-2024-CKD-Guideline.pdf")!, reference: "CKDモードの補足参照：多様で健康的な食事、減塩、G3-G5のたんぱく質、個別助言。", topic: .ckd, priority: .supplemental),
                Source(title: "NIDDK Healthy Eating for Adults with CKD", url: URL(string: "https://www.niddk.nih.gov/health-information/kidney-disease/chronic-kidney-disease-ckd/healthy-eating-adults-chronic-kidney-disease")!, reference: "CKDモードの補足参照：CKDに単一の食事計画はなく、進行度と医療チームの目標で変わる。", topic: .ckd, priority: .supplemental),
                Source(title: "NICE CKD Assessment and Management", url: URL(string: "https://www.nice.org.uk/guidance/ng203/chapter/Recommendations")!, reference: "CKDモードの補足参照：カリウム、リン、エネルギー、塩分の助言はCKDの重症度に合わせる。", topic: .ckd, priority: .supplemental)
            ]
        case .en:
            return [
                Source(title: "ADA Standards of Care in Diabetes", url: URL(string: "https://professional.diabetes.org/standards-of-care")!, reference: "Diabetes mode priority reference: individualized nutrition guidance and clinician-led care.", topic: .diabetes, priority: .localizedPrimary),
                Source(title: "CDC Diabetes Meal Planning", url: URL(string: "https://www.cdc.gov/diabetes/healthy-eating/diabetes-meal-planning.html")!, reference: "Diabetes mode priority reference: plate method, carb counting, portion awareness, and regular balanced meals.", topic: .diabetes, priority: .localizedPrimary),
                Source(title: "NICE Type 2 Diabetes Dietary Advice", url: URL(string: "https://www.nice.org.uk/guidance/ng28/chapter/Dietary-advice-and-interventions")!, reference: "Diabetes mode European priority reference: individualized and culturally sensitive nutrition advice.", topic: .diabetes, priority: .localizedPrimary),
                Source(title: "KDIGO 2024 CKD Guideline", url: URL(string: "https://kdigo.org/wp-content/uploads/2024/03/KDIGO-2024-CKD-Guideline.pdf")!, reference: "CKD mode priority reference: healthy diverse diets, sodium reduction, protein guidance for G3-G5, and individualized potassium/phosphorus counseling.", topic: .ckd, priority: .localizedPrimary),
                Source(title: "NIDDK Healthy Eating for Adults with CKD", url: URL(string: "https://www.niddk.nih.gov/health-information/kidney-disease/chronic-kidney-disease-ckd/healthy-eating-adults-chronic-kidney-disease")!, reference: "CKD mode priority reference: no single meal plan; nutrition changes increase as CKD advances and should be set with the care team.", topic: .ckd, priority: .localizedPrimary),
                Source(title: "National Kidney Foundation Nutrition and Kidney Disease", url: URL(string: "https://www.kidney.org/kidney-topics/nutrition-and-kidney-disease-stages-1-5-not-dialysis")!, reference: "CKD mode priority reference: lab-guided sodium, potassium, phosphorus, calcium, and protein decisions.", topic: .ckd, priority: .localizedPrimary),
                Source(title: "NICE CKD Assessment and Management", url: URL(string: "https://www.nice.org.uk/guidance/ng203/chapter/Recommendations")!, reference: "CKD mode European priority reference: potassium, phosphate, calories, and salt advice should match CKD severity.", topic: .ckd, priority: .localizedPrimary),
                Source(title: "衛生福利部國民健康署 糖尿病與我", url: URL(string: "https://health99.hpa.gov.tw/material/3404")!, reference: "Taiwan supplemental reference: consistent carbs, fiber, appropriate fats, and glucose self-monitoring.", topic: .diabetes, priority: .supplemental),
                Source(title: "糖尿病情報センター 食事のはなし", url: URL(string: "https://dmic.jihs.go.jp/general/about-dm/040/020/02-1.html")!, reference: "Japan supplemental reference: appropriate energy, balanced regular meals, and avoiding unnecessary food bans.", topic: .diabetes, priority: .supplemental),
                Source(title: "衛生福利部國民健康署 慢性腎臟病健康管理手冊", url: URL(string: "https://www.hpa.gov.tw/Pages/List.aspx?nodeid=1157")!, reference: "Taiwan supplemental reference: stage, urine output, labs, and dietitian goals guide CKD nutrition advice.", topic: .ckd, priority: .supplemental),
                Source(title: "日本腎臓学会 CKD診療ガイドライン2023", url: URL(string: "https://cdn.jsn.or.jp/medic/guideline/pdf/guide/001-294.pdf")!, reference: "Japan supplemental reference: CKD stage and lab-guided sodium, protein, potassium, and phosphorus individualization.", topic: .ckd, priority: .supplemental)
            ]
        }
    }

    private var primaryMedicalSources: [Source] {
        medicalSources.filter { $0.priority == .localizedPrimary }
    }

    private var supplementalMedicalSources: [Source] {
        medicalSources.filter { $0.priority == .supplemental }
    }

    private var titleForUSDA: String {
        switch langCategory {
        case .zhHant: return "美國 USDA FoodData Central"
        case .ja: return "USDA FoodData Central"
        case .en: return "USDA FoodData Central"
        }
    }
    private var titleForTFDA: String {
        switch langCategory {
        case .zhHant: return "臺灣食藥署 – TFND"
        case .ja: return "Taiwan FDA – TFND"
        case .en: return "Taiwan FDA – TFND"
        }
    }
    private var titleForMEXT: String {
        switch langCategory {
        case .zhHant: return "日本 文部科學省 (MEXT)"
        case .ja: return "文部科学省 (MEXT)"
        case .en: return "Japan MEXT"
        }
    }

    private var resolvedTitle: String {
        title ?? TranslationManager.get("data_sources.title", lang: language)
    }

    var body: some View {
        let label = Label(resolvedTitle, systemImage: "book")

        Button {
            isPresented = true
        } label: {
            if style == .capsule {
                label
                    .font(.callout).bold()
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(radius: 0.5)
            } else {
                label
                    .font(.caption)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(TranslationManager.get("data_sources.description", lang: language))
                        }
                        .padding(.vertical, 4)
                    }

                    Section {
                        ForEach(orderedSources) { src in
                            sourceRow(src)
                        }
                    } header: {
                        Text(TranslationManager.get("data_sources.links", lang: language))
                    } footer: {
                        Text(TranslationManager.get("data_sources.nutrition_note", lang: language))
                    }

                    Section {
                        ForEach(primaryMedicalSources) { src in
                            sourceRow(src)
                        }
                    } header: {
                        Text(TranslationManager.get("data_sources.medical_primary", lang: language))
                    } footer: {
                        Text(TranslationManager.get("data_sources.primary_note", lang: language))
                    }

                    Section {
                        ForEach(supplementalMedicalSources) { src in
                            sourceRow(src)
                        }
                    } header: {
                        Text(TranslationManager.get("data_sources.medical_supplemental", lang: language))
                    } footer: {
                        Text(TranslationManager.get("data_sources.supplemental_note", lang: language))
                    }
                }
                .navigationTitle(resolvedTitle)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(TranslationManager.get("paywall.done", lang: language)) {
                            isPresented = false
                        }
                    }
                }
            }
        }
    }

    private func sourceRow(_ source: Source) -> some View {
        Link(destination: source.url) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: source.topic.iconName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(source.topic.tint)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(source.topic.tint.opacity(0.12)))

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(source.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 8)

                        Image(systemName: "arrow.up.right")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .padding(.top, 3)
                    }

                    sourceMetaRow(source)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(TranslationManager.get("data_sources.reference", lang: language))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Text(source.reference)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func sourceMetaRow(_ source: Source) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                sourceMetaLabel(source.topic.label(lang: language), icon: source.topic.iconName, tint: source.topic.tint)
                if let priority = source.priority {
                    sourceMetaLabel(priority.label(lang: language), icon: priority.iconName, tint: priority == .localizedPrimary ? .accentColor : .secondary)
                }
                sourceMetaLabel(source.domainLabel, icon: "globe", tint: .secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                sourceMetaLabel(source.topic.label(lang: language), icon: source.topic.iconName, tint: source.topic.tint)
                if let priority = source.priority {
                    sourceMetaLabel(priority.label(lang: language), icon: priority.iconName, tint: priority == .localizedPrimary ? .accentColor : .secondary)
                }
                sourceMetaLabel(source.domainLabel, icon: "globe", tint: .secondary)
            }
        }
    }

    private func sourceMetaLabel(_ text: String, icon: String, tint: Color) -> some View {
        Label {
            Text(text)
                .lineLimit(1)
                .truncationMode(.middle)
        } icon: {
            Image(systemName: icon)
        }
        .font(.caption2)
        .foregroundStyle(tint)
    }
}

#Preview {
    VStack(spacing: 20) {
        DataSourcesButton()
        DataSourcesButton(style: .compact)
    }
}
