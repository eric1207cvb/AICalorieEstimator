import SwiftUI

struct ResultView: View {
    let data: CloudResponsePayload
    let profile: UserProfile
    let language: AppLanguage
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .largeTitle) private var calorieFontSize: CGFloat = 48

    private var macroColumns: [GridItem] {
        [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 150 : 96), spacing: 12)]
    }

    var body: some View {
        VStack(spacing: dynamicTypeSize.isAccessibilitySize ? 24 : 20) {

            // 1. 熱量大標題
            VStack(spacing: 8) {
                Text(TranslationManager.get("result.calorie_estimate", lang: language))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text("\(data.safeMin) - \(data.safeMax)")
                    .font(.system(size: calorieFontSize, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("kcal")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 10)

            // 2. 營養素儀表板 (Macros)
            if let macros = data.macros {
                LazyVGrid(columns: macroColumns, spacing: 12) {
                    MacroCard(title: TranslationManager.get("result.protein", lang: language), value: "\(macros.protein)g", color: .red)
                    MacroCard(title: TranslationManager.get("result.carbs", lang: language), value: "\(macros.carbs)g", color: .blue)
                    MacroCard(title: TranslationManager.get("result.fat", lang: language), value: "\(macros.fat)g", color: .yellow)
                }
            }

            // 3. 辨識結果與建議卡片
            VStack(alignment: .leading, spacing: 16) {

                // 食物名稱
                VStack(alignment: .leading, spacing: 8) {
                    Label(TranslationManager.get("result.items_found", lang: language), systemImage: "fork.knife")
                        .font(.headline)
                        .foregroundStyle(.orange)
                    Text(data.safeFoodList(language: language))
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let alert = SpecialDietFoodAlert.make(for: data, profile: profile) {
                    SpecialDietFoodAlertCard(alert: alert, language: language)
                }

                if !data.itemEstimates.isEmpty {
                    FoodItemEstimatesView(items: data.itemEstimates, language: language)
                }

                Divider()

                // 營養建議 (Health Tip)
                if let tip = data.safeHealthTip(language: language) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(TranslationManager.get("result.health_advice", lang: language), systemImage: "heart.text.square.fill")
                            .font(.headline)
                            .foregroundStyle(.pink)

                        Text(tip)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                            .padding(12)
                            .background(Color.pink.opacity(colorScheme == .dark ? 0.18 : 0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.pink.opacity(colorScheme == .dark ? 0.35 : 0.18), lineWidth: 1)
                            )
                            .cornerRadius(12)
                    }
                }

                if let advice = MedicalNutritionAdvisor.advice(for: data, profile: profile, lang: language) {
                    MedicalNutritionAdviceCard(advice: advice, language: language)
                }

                // 分析過程 (Reasoning)
                if let reasoning = data.safeReasoning(language: language) {
                    DisclosureGroup {
                        Text(reasoning)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                            .fixedSize(horizontal: false, vertical: true)
                    } label: {
                        Label(TranslationManager.get("result.ai_comment", lang: language), systemImage: "brain.head.profile")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.06), lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }
}

struct SpecialDietFoodAlertCard: View {
    let alert: SpecialDietFoodAlert
    let language: AppLanguage
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 10) {
                alertIcon
                content
            }
            VStack(alignment: .leading, spacing: 10) {
                alertIcon
                content
            }
        }
        .padding(12)
        .background(alert.riskLevel.color.opacity(colorScheme == .dark ? 0.18 : 0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(alert.riskLevel.color.opacity(colorScheme == .dark ? 0.38 : 0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var alertIcon: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(dynamicTypeSize.isAccessibilitySize ? .title2 : .title3)
            .foregroundStyle(alert.riskLevel.color)
            .frame(width: dynamicTypeSize.isAccessibilitySize ? 34 : 28, alignment: .leading)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(alert.title(lang: language))
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(alert.message(lang: language))
                .font(.callout)
                .foregroundStyle(.primary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(alert.concerns, id: \.self) { concern in
                    Label(concern.label(lang: language), systemImage: "exclamationmark.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct FoodItemEstimatesView: View {
    let items: [FoodEstimateItem]
    let language: AppLanguage
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        DisclosureGroup {
            VStack(spacing: 8) {
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Label(item.safeName(language: language), systemImage: "circle.grid.2x2.fill")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 8)
                            Text("\(item.caloriesMin)-\(item.caloriesMax) kcal")
                                .font(.callout)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)
                        }

                        if let portion = item.safePortionDescription, !portion.isEmpty {
                            Text(portion)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let basis = item.safePortionBasis, !basis.isEmpty {
                            Text(basis)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        HStack(spacing: 10) {
                            if let servingCount = item.normalizedServingCount {
                                Text(servingText(servingCount))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if let confidence = item.confidence {
                                Text("\(TranslationManager.get("result.confidence", lang: language)): \(Int((confidence <= 1 ? confidence * 100 : confidence).rounded()))%")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.orange.opacity(colorScheme == .dark ? 0.14 : 0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange.opacity(colorScheme == .dark ? 0.32 : 0.16), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.top, 6)
        } label: {
            Label(TranslationManager.get("result.itemized_estimate", lang: language), systemImage: "list.bullet.rectangle")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.orange)
        }
        .tint(.orange)
    }

    private func servingText(_ servingCount: Double) -> String {
        let countText = servingCount == floor(servingCount)
            ? String(Int(servingCount))
            : String(format: "%.1f", servingCount)
        switch language.translationBase {
        case .traditionalChinese:
            return "可見份數 \(countText)"
        case .japanese:
            return "見える量 \(countText)人前"
        default:
            return "Visible servings \(countText)"
        }
    }
}

struct MedicalNutritionAdviceCard: View {
    let advice: MedicalNutritionAdvice
    let language: AppLanguage
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(TranslationManager.get("result.special_diet_advice", lang: language), systemImage: advice.riskLevel.iconName)
                .font(.headline)
                .foregroundStyle(advice.riskLevel.color)

            Text(advice.title)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(advice.summary)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(advice.focusItems, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(advice.riskLevel.color)
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)
                        Text(item)
                            .font(.callout)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.top, 2)

            if !advice.guardrails.isEmpty {
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(advice.guardrails, id: \.self) { item in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.caption2)
                                    .foregroundStyle(advice.riskLevel.color)
                                    .padding(.top, 1)
                                Text(item)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.top, 6)
                } label: {
                    Label(TranslationManager.get("result.guidance_scope", lang: language), systemImage: "shield.lefthalf.filled")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .tint(advice.riskLevel.color)
            }

            if !advice.sources.isEmpty {
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(advice.sources) { source in
                            VStack(alignment: .leading, spacing: 3) {
                                Link(destination: source.url) {
                                    Label(source.title, systemImage: "link")
                                        .font(.footnote)
                                        .multilineTextAlignment(.leading)
                                }

                                Label(source.priority.label(lang: language), systemImage: source.priority.iconName)
                                    .font(.caption2)
                                    .foregroundStyle(source.priority == .localizedPrimary ? advice.riskLevel.color : .secondary)

                                Text(source.reference)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineSpacing(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        Text(TranslationManager.get("result.source_note", lang: language))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                    .padding(.top, 6)
                } label: {
                    Label(TranslationManager.get("result.authoritative_sources", lang: language), systemImage: "books.vertical.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .tint(advice.riskLevel.color)
            }

            Text(TranslationManager.get("result.medical_disclaimer", lang: language))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .padding(12)
        .background(advice.riskLevel.color.opacity(colorScheme == .dark ? 0.16 : 0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(advice.riskLevel.color.opacity(colorScheme == .dark ? 0.32 : 0.16), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MacroCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
                .background(color.opacity(0.05))
        )
        .cornerRadius(12)
    }
}
