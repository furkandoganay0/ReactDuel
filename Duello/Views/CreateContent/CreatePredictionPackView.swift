import SwiftUI

/// Kullanıcının kendi "Tahmin Et" paketini yazabildiği ekran — önceden tüm
/// içerik sadece bundled JSON'dan geliyordu, kullanıcı kendi sorularını
/// (ör. arkadaş grubuna özel bilgi yarışması) hiç ekleyemiyordu.
struct CreatePredictionPackView: View {
    @Binding var path: [AppRoute]
    @EnvironmentObject private var userContentStore: UserContentStore
    @Environment(\.locale) private var locale

    @State private var title = ""
    @State private var questions: [QuestionInput] = [QuestionInput(), QuestionInput(), QuestionInput()]

    private static let minimumQuestions = 3

    struct QuestionInput: Identifiable {
        let id = UUID()
        var prompt = ""
        var answer = ""
        var distractor1 = ""
        var distractor2 = ""
        var distractor3 = ""

        var isValid: Bool {
            let trimmedFields = [prompt, answer, distractor1, distractor2, distractor3].map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            guard trimmedFields.allSatisfy({ !$0.isEmpty }) else { return false }
            let choices = Set(trimmedFields.dropFirst())
            return choices.count == 4
        }
    }

    private var validQuestionCount: Int { questions.filter(\.isValid).count }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && questions.count >= Self.minimumQuestions
            && questions.allSatisfy(\.isValid)
    }

    var body: some View {
        Form {
            Section {
                TextField("ör. Ünlüleri Tahmin Et", text: $title)
            } header: {
                Text("Paket Adı")
            }

            ForEach($questions) { $question in
                Section {
                    TextField("İpucu / soru metni", text: $question.prompt, axis: .vertical)
                    TextField("Doğru Cevap", text: $question.answer)
                    TextField("Yanlış Seçenek 1", text: $question.distractor1)
                    TextField("Yanlış Seçenek 2", text: $question.distractor2)
                    TextField("Yanlış Seçenek 3", text: $question.distractor3)

                    if questions.count > 1 {
                        Button(role: .destructive) {
                            withAnimation { questions.removeAll { $0.id == question.id } }
                        } label: {
                            Text("Bu Soruyu Sil")
                        }
                    }
                } header: {
                    Text(L10n.questionNumberLabel(questionIndex(of: question) + 1, locale: locale))
                }
            }

            Section {
                Button {
                    withAnimation { questions.append(QuestionInput()) }
                } label: {
                    Label("Soru Ekle", systemImage: "plus.circle.fill")
                }
            } footer: {
                Text(L10n.addedProgress(current: validQuestionCount, minimum: Self.minimumQuestions, unit: .question, locale: locale))
            }
        }
        .navigationTitle(Text("Yeni Tahmin Paketi"))
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

    private func questionIndex(of question: QuestionInput) -> Int {
        questions.firstIndex(where: { $0.id == question.id }) ?? 0
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let builtQuestions: [PredictionQuestion] = questions.enumerated().map { index, input in
            let answer = input.answer.trimmingCharacters(in: .whitespacesAndNewlines)
            let choices = [
                answer,
                input.distractor1.trimmingCharacters(in: .whitespacesAndNewlines),
                input.distractor2.trimmingCharacters(in: .whitespacesAndNewlines),
                input.distractor3.trimmingCharacters(in: .whitespacesAndNewlines)
            ]
            return PredictionQuestion(
                id: "q\(index + 1)",
                prompt: input.prompt.trimmingCharacters(in: .whitespacesAndNewlines),
                answer: answer,
                answerImage: "",
                timerSeconds: 6,
                choices: choices
            )
        }
        userContentStore.addPredictionPack(title: trimmedTitle, questions: builtQuestions)
        path.removeLast()
    }
}

#Preview {
    NavigationStack {
        CreatePredictionPackView(path: .constant([]))
    }
    .environmentObject(UserContentStore())
}
