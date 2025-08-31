import SwiftUI
import EventDeskCoreBindings

struct NewEventSheet: View {
    var onCreate: (String) -> Void

    @State private var name = ""
    @State private var startDate = Date().addingTimeInterval(3600)
    @State private var endDate = Date().addingTimeInterval(3*3600)
    @State private var location = ""
    @State private var capacity: Int64 = 0
    @State private var timezoneId = TimeZone.current.identifier
    @State private var sizeLabel: String = ""
    @State private var description = ""
    @State private var error: String? = nil

    private let tzOptions: [String] = {
        var base = [
            "UTC",
            "America/New_York",
            "America/Chicago",
            "America/Denver",
            "America/Los_Angeles",
            "Europe/London",
            "Europe/Berlin",
            "Asia/Tokyo",
            "Asia/Singapore",
            "Australia/Sydney"
        ]
        let sys = TimeZone.current.identifier
        if !base.contains(sys) { base.insert(sys, at: 0) }
        return base
    }()

    private var capacityFormatter: NumberFormatter { let f = NumberFormatter(); f.allowsFloats = false; f.minimum = 0; return f }

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("New Event").font(.headline)
            if let e = error { ErrorStateView(message: e) }
            TextField("Event name", text: $name).textFieldStyle(.roundedBorder)
            HStack {
                DatePicker("Starts", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                DatePicker("Ends", selection: $endDate, in: startDate..., displayedComponents: [.date, .hourAndMinute])
            }
            if !datesValid { Text("End must be after Start.").font(.caption).foregroundColor(.orange) }
            HStack {
                TextField("Location", text: $location).textFieldStyle(.roundedBorder)
                TimezonePicker(timezoneId: $timezoneId)
                .frame(maxWidth: 220)
            }
            if !timezoneValid { Text("Timezone not recognized; example: America/New_York, UTC").font(.caption).foregroundColor(.orange) }
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    TextField("Max guests (capacity)", value: $capacity, formatter: capacityFormatter).textFieldStyle(.roundedBorder)
                    Spacer()
                }
                Text("Use 0 for unlimited. Whole numbers only.").font(.caption).foregroundColor(.secondary)
            }
            HStack {
                Text("Size (optional)")
                Picker("Size", selection: $sizeLabel) { Text("None").tag(""); Text("Small").tag("Small"); Text("Medium").tag("Medium"); Text("Large").tag("Large") }
                    .pickerStyle(.segmented)
                Spacer()
            }
            TextField("Description", text: $description).textFieldStyle(.roundedBorder)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Create") { create() }
                    .keyboardShortcut(.defaultAction)
                    .keyboardShortcut(.return, modifiers: [.command])
                    .disabled(!canCreate)
            }
        }
        .padding(16)
        .frame(minWidth: 560)
    }

    private func create() {
        do {
            let fmt = ISO8601DateFormatter(); fmt.timeZone = TimeZone(secondsFromGMT: 0)
            let startsAt = fmt.string(from: startDate); let endsAt = fmt.string(from: endDate)
            let id = try EDPCore.shared.createEvent(name: name, startsAt: startsAt, endsAt: endsAt, location: location.isEmpty ? nil : location, capacity: capacity, status: "active", timezone: timezoneId, description: description.isEmpty ? nil : description)
            onCreate(id)
            NotificationCenter.default.post(name: .edpEventsShouldRefresh, object: nil)
            dismiss()
        } catch { self.error = EDPCore.shared.lastError() ?? "Failed to create event" }
    }

    private var datesValid: Bool { endDate > startDate }
    private var timezoneValid: Bool { TimeZone(identifier: timezoneId) != nil }
    private var canCreate: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && datesValid && capacity >= 0 }
}
