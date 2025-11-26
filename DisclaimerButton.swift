import SwiftUI

struct DisclaimerButton: View {
    let renderAsCard: Bool
    @State private var showDisclaimer = false

    private let zhTW = "本應用程式提供的估算結果僅供參考，並非醫療建議。在使用任何飲食計畫前，請諮詢專業醫師。數據由 AI 模型估算。"
    private let enUS = "The estimates provided by this app are for reference only and do not constitute medical advice. Please consult a professional doctor before starting any diet plan. Data is estimated by AI models."
    private let jaJP = "本アプリの推定結果はあくまで参考であり、医療的な助言ではありません。食事計画を始める前に、必ず医師にご相談ください。データはAIモデルによって算出されています。"

    init(renderAsCard: Bool = false) {
        self.renderAsCard = renderAsCard
    }

    var body: some View {
        Button {
            showDisclaimer = true
        } label: {
            if renderAsCard {
                HStack(spacing: 8) {
                    Text("Disclaimer")
                    Spacer()
                    Image(systemName: "chevron.right").font(.footnote)
                }
                .font(.footnote)
                .padding(12)
                .background(Color.gray.opacity(0.12))
                .cornerRadius(10)
            } else {
                Text("免責聲明 / Disclaimer")
            }
        }
        .sheet(isPresented: $showDisclaimer) {
            NavigationStack {
                List {
                    Section {
                        DisclosureGroup("繁體中文") {
                            Text(zhTW).font(.body).padding(.vertical, 4)
                        }
                        DisclosureGroup("English") {
                            Text(enUS).font(.body).padding(.vertical, 4)
                        }
                        DisclosureGroup("日本語") {
                            Text(jaJP).font(.body).padding(.vertical, 4)
                        }
                    } header: {
                        Text("免責聲明 / Disclaimer")
                    }

                    Section {
                        Button {
                            let all = "【繁體中文】\n\(zhTW)\n\n【English】\n\(enUS)\n\n【日本語】\n\(jaJP)"
                            UIPasteboard.general.string = all
                        } label: {
                            Label("複製全部", systemImage: "doc.on.doc")
                        }
                    }
                }
                .navigationTitle("免責聲明")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("關閉") { showDisclaimer = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    DisclaimerButton().padding()
}
