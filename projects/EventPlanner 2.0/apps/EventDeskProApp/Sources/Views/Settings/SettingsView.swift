import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("orgName") private var orgName: String = "My Org"
    @AppStorage("timezone") private var timezone: String = "UTC"
    @AppStorage("theme") private var theme: String = "system"
    @AppStorage("piiExportAllowed") private var piiExportAllowed: Bool = true
    @FocusState private var focusedField: Field?
    enum Field { case orgName, timezone }

    var body: some View {
        Form {
            Section(header: Text("Organization")) {
                TextField("Organization Name", text: $orgName)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .orgName)
            }
            Section(header: Text("Preferences")) {
                Picker("Theme", selection: $theme) { Text("System").tag("system"); Text("Light").tag("light"); Text("Dark").tag("dark") }
                HStack {
                    TimezonePicker(timezoneId: $timezone, label: "Timezone")
                        .frame(maxWidth: 280)
                }
                Toggle("Allow PII export (CSV/JSON)", isOn: $piiExportAllowed)
            }
            Section {
                HStack { Spacer(); Button("Close") { dismiss() }.keyboardShortcut(.cancelAction) }
            }
        }
        .padding(12)
        .frame(minWidth: 420, minHeight: 260)
        .onAppear { focusedField = .orgName }
    }
}

private let commonTimezones: [String] = [
    "UTC", "America/New_York", "America/Chicago", "America/Denver", "America/Los_Angeles",
    "Europe/London", "Europe/Berlin", "Asia/Tokyo", "Asia/Singapore", "Australia/Sydney"
]
