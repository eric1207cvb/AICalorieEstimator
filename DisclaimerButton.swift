import SwiftUI

struct DisclaimerButton: View {
    let renderAsCard: Bool
    let language: AppLanguage
    @State private var showDisclaimer = false

    init(renderAsCard: Bool = false, language: AppLanguage = .unitedStates) {
        self.renderAsCard = renderAsCard
        self.language = language
    }

    private var title: String { TranslationManager.get("disclaimer.title", lang: language) }
    private var message: String { TranslationManager.get("disclaimer.message", lang: language) }

    var body: some View {
        Button {
            showDisclaimer = true
        } label: {
            if renderAsCard {
                HStack(spacing: 8) {
                    Text(title)
                    Spacer()
                    Image(systemName: "chevron.right").font(.footnote)
                }
                .font(.footnote)
                .padding(12)
                    .background(Color.gray.opacity(0.12))
                    .cornerRadius(10)
            } else {
                Text(title)
            }
        }
        .sheet(isPresented: $showDisclaimer) {
            NavigationStack {
                List {
                    Section {
                        Text(message).font(.body).padding(.vertical, 4)
                    } header: {
                        Text(title)
                    }

                    Section {
                        Button {
                            UIPasteboard.general.string = message
                        } label: {
                            Label(TranslationManager.get("disclaimer.copy_all", lang: language), systemImage: "doc.on.doc")
                        }
                    }
                }
                .navigationTitle(title)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(TranslationManager.get("disclaimer.close", lang: language)) { showDisclaimer = false }
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
