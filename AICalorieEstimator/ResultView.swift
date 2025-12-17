import SwiftUI

struct ResultView: View {
    let data: CloudResponsePayload
    let language: AppLanguage
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 1. 熱量大標題
            VStack(spacing: 8) {
                Text(TranslationManager.get("result.calorie_estimate", lang: language))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                
                Text("\(data.safeMin) - \(data.safeMax)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
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
                HStack(spacing: 12) {
                    MacroCard(title: "Protein", value: "\(macros.protein)g", color: .red)
                    MacroCard(title: "Carbs", value: "\(macros.carbs)g", color: .blue)
                    MacroCard(title: "Fat", value: "\(macros.fat)g", color: .yellow)
                }
            }
            
            // 3. 辨識結果與建議卡片
            VStack(alignment: .leading, spacing: 16) {
                
                // 食物名稱
                VStack(alignment: .leading, spacing: 8) {
                    Label(TranslationManager.get("result.items_found", lang: language), systemImage: "fork.knife")
                        .font(.headline)
                        .foregroundStyle(.orange)
                    Text(data.safeFoodList)
                        .font(.body)
                        .foregroundStyle(.primary)
                }
                
                Divider()
                
                // 營養建議 (Health Tip)
                if let tip = data.healthTip, !tip.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(TranslationManager.get("result.health_advice", lang: language), systemImage: "heart.text.square.fill")
                            .font(.headline)
                            .foregroundStyle(.pink)
                        
                        Text(tip)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                            .padding(12)
                            .background(Color.pink.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                
                // 分析過程 (Reasoning)
                if !data.reasoning.isEmpty {
                    DisclosureGroup {
                        Text(data.reasoning)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
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
        }
        .padding(.horizontal)
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
