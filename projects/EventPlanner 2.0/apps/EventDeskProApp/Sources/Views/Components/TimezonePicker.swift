import SwiftUI

struct TimezonePicker: View {
    @Binding var timezoneId: String
    var label: String = "Time zone"
    @State private var query: String = ""

    private var filtered: [String] {
        let all = TimeZone.knownTimeZoneIdentifiers
        let q = query.trimmingCharacters(in: .whitespaces)
        return q.isEmpty ? all : all.filter { $0.localizedCaseInsensitiveContains(q) }
    }

    private var isValid: Bool { TimeZone(identifier: timezoneId) != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                Spacer()
                TextField("Search time zone", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 220)
            }
            List(filtered, id: \.self) { id in
                HStack {
                    Text(id)
                    Spacer()
                    if id == timezoneId { Image(systemName: "checkmark").foregroundColor(.accentColor) }
                }
                .contentShape(Rectangle())
                .onTapGesture { timezoneId = id }
            }
            if !isValid {
                Text("Unrecognized time zone ID").font(.caption).foregroundColor(.orange)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(label))
    }
}
