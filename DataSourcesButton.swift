import SwiftUI

public struct DataSourcesButton: View {
    public enum Style { case compact, capsule }
    
    public var title: String = "Data Sources"
    var style: Style = .capsule
    var locale: Locale = .current
    
    @State private var isPresented = false
    
    public init(title: String = "Data Sources", style: Style = .capsule) {
        self.title = title
        self.style = style
    }
    
    init(title: String = "Data Sources", style: Style = .capsule, locale: Locale = .current) {
        self.title = title
        self.style = style
        self.locale = locale
    }
    
    private enum LangCategory { case zhHant, ja, en }
    private var langCategory: LangCategory {
        let id = locale.identifier.lowercased()
        if id.contains("zh-hant") || id.contains("zh_tw") || id.contains("zh-tw") || id.contains("zh-hk") { return .zhHant }
        if id.hasPrefix("ja") { return .ja }
        return .en
    }
    
    private struct Source: Identifiable { let id = UUID(); let title: String; let url: URL }
    private var orderedSources: [Source] {
        // URLs
        let usda = Source(title: titleForUSDA, url: URL(string: "https://fdc.nal.usda.gov/")!)
        let tfda = Source(title: titleForTFDA, url: URL(string: "https://consumer.fda.gov.tw/Food/TFND.aspx")!)
        let mext = Source(title: titleForMEXT, url: URL(string: "https://www.mext.go.jp/")!)
        switch langCategory {
        case .zhHant: return [tfda, usda, mext]
        case .ja:     return [mext, usda, tfda]
        case .en:     return [usda, tfda, mext]
        }
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
    
    public var body: some View {
        let label = Label(title, systemImage: "book")
        
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
                            Text("這些來源用作估算的參考資料。")
                            Text("These sources are used as references for estimates.")
                            Text("これらの情報源は推定の参考資料として使用されています。")
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Section("Links") {
                        ForEach(orderedSources) { src in
                            Link(src.title, destination: src.url)
                        }
                    }
                }
                .navigationTitle(title)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            isPresented = false
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        DataSourcesButton()
        DataSourcesButton(style: .compact)
    }
}
