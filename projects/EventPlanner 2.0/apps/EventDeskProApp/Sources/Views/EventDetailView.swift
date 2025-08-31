import SwiftUI
import EventDeskCoreBindings

struct EventDetailView: View {
    let event: EDPCore.EventDTO
    @State private var tab: Tab = .attendees
    @State private var showEdit = false
    @State private var duplicateError: String? = nil

    enum Tab: Hashable { case overview, attendees, schedule, assets, settings, reports }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                BackToEventsButton()
                Text(event.name).font(.title).bold()
                Spacer()
                if let status = event.status { Text(status.uppercased()).font(.caption).padding(6).background(Color.secondary.opacity(0.1)).cornerRadius(4) }
                Button("Edit") { showEdit = true }
                Button("Duplicate") { duplicateEvent() }
            }
            HStack(spacing: 16) {
                if let loc = event.location { Label(loc, systemImage: "mappin.and.ellipse") }
                Label("\(event.startsAt) → \(event.endsAt)", systemImage: "calendar")
            }.foregroundColor(.secondary).font(.caption)

            Picker("Tab", selection: $tab) {
                Text("Overview").tag(Tab.overview)
                Text("Attendees").tag(Tab.attendees)
                Text("Schedule").tag(Tab.schedule)
                Text("Assets").tag(Tab.assets)
                Text("Settings").tag(Tab.settings)
                Text("Reports").tag(Tab.reports)
            }.pickerStyle(.segmented)
                .padding(.top, 8)

            Group {
                switch tab {
                case .overview:
                    OverviewView(event: event)
                case .attendees:
                    AttendeesView(event: event)
                case .schedule:
                    PlaceholderView(title: "Schedule")
                case .assets:
                    PlaceholderView(title: "Assets")
                case .settings:
                    EventSettingsView(event: event)
                case .reports:
                    ReportsView(event: event)
            }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(12)
        .sheet(isPresented: $showEdit) { EventSettingsView(event: event) }
        .alert("Duplicate Failed", isPresented: Binding(get: { duplicateError != nil }, set: { if !$0 { duplicateError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(duplicateError ?? "") }
    }
}

private struct BackToEventsButton: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Button(action: { dismiss() }) {
            HStack(spacing: 4) { Image(systemName: "chevron.left"); Text("Back to Events") }
        }
        .buttonStyle(.plain)
        .foregroundColor(.accentColor)
    }
}

private extension EventDetailView {
    func duplicateEvent() {
        do {
            let newId = try EDPCore.shared.createEvent(
                id: nil,
                name: "Copy of \(event.name)",
                startsAt: event.startsAt,
                endsAt: event.endsAt,
                location: event.location,
                capacity: event.capacity ?? 0,
                status: event.status,
                timezone: event.timezone,
                description: event.description
            )
            Analytics.emit("event_duplicate", payload: ["sourceId": event.id, "newId": newId])
        } catch {
            duplicateError = EDPCore.shared.lastError() ?? "Could not duplicate event"
        }
    }
}

private struct OverviewView: View {
    let event: EDPCore.EventDTO
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details").font(.headline)
            if let desc = event.description { Text(desc) }
            if let tz = event.timezone { Text("Timezone: \(tz)").foregroundColor(.secondary) }
            Spacer()
        }
        .padding(.top, 8)
    }
}
