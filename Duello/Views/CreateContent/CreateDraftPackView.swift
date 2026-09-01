import SwiftUI

/// Kullanıcının kendi "Bütçeli Draft" paketini yazabildiği ekran — bkz.
/// `CreatePredictionPackView` üstündeki genel gerekçe. Diğer ikisinden farkı:
/// bütçe/kadro boyutu/maliyet tutarlılığını (en ucuz `rosterSize` öğenin toplamı
/// bütçeyi aşmamalı — aksi halde kadro asla tamamlanamaz) canlı doğrulaması gerekiyor.
struct CreateDraftPackView: View {
    @Binding var path: [AppRoute]
    @EnvironmentObject private var userContentStore: UserContentStore
    @Environment(\.locale) private var locale

    @State private var title = ""
    @State private var budget = 20
    @State private var rosterSize = 5
    @State private var pool: [PoolItemInput] = (1...8).map { _ in PoolItemInput() }

    struct PoolItemInput: Identifiable {
        let id = UUID()
        var name = ""
        var cost = 5

        var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
        var isValid: Bool { !trimmedName.isEmpty && cost >= 1 }
    }

    private var minimumPoolCount: Int { rosterSize + 3 }

    private var validPoolCount: Int { pool.filter(\.isValid).count }

    private var namesAreUnique: Bool {
        let trimmedNames = pool.map(\.trimmedName).filter { !$0.isEmpty }
        return Set(trimmedNames).count == trimmedNames.count
    }

    private var cheapestRosterSum: Int {
        pool.map(\.cost).sorted().prefix(rosterSize).reduce(0, +)
    }

    private var budgetAllowsCompletion: Bool { cheapestRosterSum <= budget }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && pool.count >= minimumPoolCount
            && pool.allSatisfy(\.isValid)
            && namesAreUnique
            && budgetAllowsCompletion
    }

    var body: some View {
        Form {
            Section {
                TextField("ör. Dizi Draftı", text: $title)
            } header: {
                Text("Paket Adı")
            }

            Section {
                Stepper(value: $budget, in: 10...40, step: 5) {
                    HStack {
                        Text("Bütçe")
                        Spacer()
                        Text("\(budget)").foregroundStyle(.secondary)
                    }
                }
                Stepper(value: $rosterSize, in: 3...6) {
                    HStack {
                        Text("Kadro Boyutu")
                        Spacer()
                        Text("\(rosterSize)").foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Bütçe ve Kadro")
            } footer: {
                Text(L10n.draftPoolBudgetHint(cheapestRosterSum: cheapestRosterSum, budget: budget, rosterSize: rosterSize, locale: locale))
                    .foregroundStyle(budgetAllowsCompletion ? Color.secondary : Color.red)
            }

            ForEach($pool) { $item in
                Section {
                    TextField("İsim", text: $item.name)
                    Stepper(value: $item.cost, in: 1...budget) {
                        HStack {
                            Text("Maliyet")
                            Spacer()
                            Text("\(item.cost)").foregroundStyle(.secondary)
                        }
                    }

                    if pool.count > 1 {
                        Button(role: .destructive) {
                            withAnimation { pool.removeAll { $0.id == item.id } }
                        } label: {
                            Text("Bu Öğeyi Sil")
                        }
                    }
                }
            }

            Section {
                Button {
                    withAnimation { pool.append(PoolItemInput()) }
                } label: {
                    Label("Öğe Ekle", systemImage: "plus.circle.fill")
                }
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.addedProgress(current: validPoolCount, minimum: minimumPoolCount, unit: .poolItem, locale: locale))
                    if !namesAreUnique {
                        Text("İsimler birbirinden farklı olmalı.")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle(Text("Yeni Draft Paketi"))
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

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let builtPool: [DraftPoolItem] = pool.enumerated().map { index, input in
            DraftPoolItem(id: "p\(index + 1)", name: input.trimmedName, cost: input.cost, image: "")
        }
        userContentStore.addDraftPack(title: trimmedTitle, budget: budget, rosterSize: rosterSize, pool: builtPool)
        path.removeLast()
    }
}

#Preview {
    NavigationStack {
        CreateDraftPackView(path: .constant([]))
    }
    .environmentObject(UserContentStore())
}
