import SwiftUI

struct WelcomeView: View {
    @AppStorage("notion_db_name") var dbName: String = ""
    @AppStorage("isSetupComplete") var isSetupComplete: Bool = false

    @State private var input = ""

    var body: some View {
        VStack(spacing: 30) {
            Text("Welcome to Habit Tracker")
                .font(.largeTitle)
                .multilineTextAlignment(.center)

            Text("Please enter the name of your Notion database")
                .multilineTextAlignment(.center)

            TextField("e.g. Habits", text: $input)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Continue") {
                dbName = input
                isSetupComplete = true
            }
            .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }
}
