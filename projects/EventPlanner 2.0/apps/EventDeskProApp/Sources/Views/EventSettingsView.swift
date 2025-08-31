import SwiftUI
import EventDeskCoreBindings

struct EventSettingsView: View {
    let event: EDPCore.EventDTO
    @State private var name: String = ""
    @State private var location: String = ""
    @State private var timezone: String = "UTC"
    @State private var description: String = ""
    @State private var error: String? = nil

    var body: some View {
        Form {
            Section(header: Text("Basics")) {
                TextField("Name", text: $name)
                TextField("Location", text: $location)
                TimezonePicker(timezoneId: $timezone, label: "Timezone")
                TextField("Description", text: $description)
                Button("Save") { save() }
            }
            if let e = error { Text(e).foregroundColor(.red) }
        }
        .onAppear {
            name = event.name
            location = event.location ?? ""
            timezone = event.timezone ?? "UTC"
            description = event.description ?? ""
        }
        .padding(12)
    }

    private func save() {
        let ok = EDPCore.shared.updateEvent(id: event.id, name: name, startsAt: nil, endsAt: nil, location: location, capacity: 0, status: event.status, timezone: timezone, description: description)
        if !ok { error = "Failed to update event" }
    }
}
