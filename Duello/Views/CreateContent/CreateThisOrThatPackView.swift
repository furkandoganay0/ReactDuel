import SwiftUI

/// Kullanıcının kendi "Bu mu O mu" paketini yazabildiği ekran — bkz.
/// `CreatePredictionPackView` üstündeki genel gerekçe (`existingPack` ile
/// düzenleme modu dahil).
struct CreateThisOrThatPackView: View {
    let existingPack: ThisOrThatTemplate?
    @Binding var path: [AppRoute]
    @EnvironmentObject private var userContentStore: UserContentStore
    @Environment(\.locale) private var locale

    @State private var title: String
    @State private var rounds: [RoundInput]

    private static let minimumRounds = 3

    struct RoundInput: Identifiable {
        let id = UUID()
        var optionA = ""
        var optionB = ""

        var isValid: Bool {
            let a = optionA.trimmingCharacters(in: .whitespacesAndNewlines)
            let b = optionB.trimmingCharacters(in: .whitespacesAndNewlines)
            return !a.isEmpty && !b.isEmpty && a != b
        }
    }

    init(existingPack: ThisOrThatTemplate? = nil, path: Binding<[AppRoute]>) {
        self.existingPack = existingPack
        self._path = path
        if let existingPack {
            _title = State(initialValue: existingPack.title)
            _rounds = State(initialValue: existingPack.rounds.map { round in
                RoundInput(optionA: round.optionA, optionB: round.optionB)
            })
        } else {
            _title = State(initialValue: "")
            _rounds = State(initialValue: [RoundInput(), RoundInput(), RoundInput()])
        }
    }

    private var validRoundCount: Int { rounds.filter(\.isValid).count }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && rounds.count >= Self.minimumRounds
            && rounds.allSatisfy(\.isValid)
    }

    var body: some View {
        Form {
            Section {
                TextField("ör. Bu mu O mu: Tatiller", text: $title)
            } header: {
                Text("Paket Adı")
            }

            ForEach($rounds) { $round in
                Section {
                    TextField("Seçenek A", text: $round.optionA)
                    TextField("Seçenek B", text: $round.optionB)

                    if rounds.count > 1 {
                        Button(role: .destructive) {
                            withAnimation { rounds.removeAll { $0.id == round.id } }
                        } label: {
                            Text("Bu Turu Sil")
                        }
                    }
                } header: {
                    Text(L10n.roundNumberLabel(roundIndex(of: round) + 1, locale: locale))
                }
            }

            Section {
                Button {
                    withAnimation { rounds.append(RoundInput()) }
                } label: {
                    Label("Tur Ekle", systemImage: "plus.circle.fill")
                }
            } footer: {
                Text(L10n.addedProgress(current: validRoundCount, minimum: Self.minimumRounds, unit: .round, locale: locale))
            }
        }
        .navigationTitle(Text(existingPack == nil ? "Yeni Bu mu O mu Paketi" : "Paketi Düzenle"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    path.removeLast()
                } label: {
                    Text("İptal")
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    save()
                } label: {
                    Text("Kaydet").fontWeight(.semibold)
                }
                .disabled(!isValid)
            }
        }
    }

    private func roundIndex(of round: RoundInput) -> Int {
        rounds.firstIndex(where: { $0.id == round.id }) ?? 0
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let builtRounds: [ThisOrThatRound] = rounds.enumerated().map { index, input in
            ThisOrThatRound(
                id: "r\(index + 1)",
                optionA: input.optionA.trimmingCharacters(in: .whitespacesAndNewlines),
                optionB: input.optionB.trimmingCharacters(in: .whitespacesAndNewlines),
                timerSeconds: 5
            )
        }
        if let existingPack {
            userContentStore.updateThisOrThatPack(id: existingPack.id, title: trimmedTitle, rounds: builtRounds)
        } else {
            userContentStore.addThisOrThatPack(title: trimmedTitle, rounds: builtRounds)
        }
        path.removeLast()
    }
}

#Preview {
    NavigationStack {
        CreateThisOrThatPackView(path: .constant([]))
    }
    .environmentObject(UserContentStore())
}
