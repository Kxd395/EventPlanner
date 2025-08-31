import SwiftUI
import Security
import EventDeskCoreBindings

struct EventDetailView: View {
    let event: EDPCore.EventDTO
    @State private var tab: Tab = .attendees
    @State private var showEdit = false
    @State private var duplicateError: String? = nil
    @State private var showPublicQR = false

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
                Button("Public Registration") { showPublicQR = true }
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
        .sheet(isPresented: $showPublicQR) {
            PublicRegistrationScaffold(event: event)
        }
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

// MARK: - Public Registration (QR) wrapper with per-event secret management
private struct PublicRegistrationScaffold: View {
    let event: EDPCore.EventDTO
    @Environment(\.dismiss) private var dismiss
    @State private var secret: String? = nil
    @State private var ttlMinutes: Int = 24 * 60

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Public Registration").font(.title3).bold()
            Text("Generate and share a QR code that links to a small registration form. The link is signed with a per-event secret stored locally.")
                .font(.caption)
                .foregroundColor(.secondary)

            if let s = secret {
                PublicRegistrationQRView(eventId: event.id, eventSecret: s, ttlMinutes: ttlMinutes)
                HStack {
                    Stepper("Expires in \(ttlMinutes) minutes", value: $ttlMinutes, in: 10...7*24*60, step: 30)
                    Spacer()
                    Button("Regenerate Secret", role: .destructive) { regenerateSecret() }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Public registration is disabled for this event.")
                    HStack {
                        Button("Enable & Generate Secret") { enable() }
                        Button("Close") { dismiss() }
                    }
                }
            }
        }
        .padding(16)
        .onAppear { secret = loadSecret() }
    }

    private func loadSecret() -> String? {
        if let s = keychainGet(eventId: event.id) { return s }
        // Fallback for older versions that used UserDefaults
        let key = "eventPublicSecret_\(event.id)"
        return UserDefaults.standard.string(forKey: key)
    }

    private func enable() {
        let s = generateSecret()
        if !keychainSet(eventId: event.id, secret: s) {
            // Fallback
            let key = "eventPublicSecret_\(event.id)"
            UserDefaults.standard.set(s, forKey: key)
        }
        secret = s
    }

    private func regenerateSecret() {
        let s = generateSecret()
        if !keychainSet(eventId: event.id, secret: s) {
            let key = "eventPublicSecret_\(event.id)"
            UserDefaults.standard.set(s, forKey: key)
        }
        secret = s
    }

    private func generateSecret() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let data = Data(bytes)
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    // MARK: - Keychain helpers
    private func keychainGet(eventId: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.eventdesk.public.secret",
            kSecAttrAccount as String: eventId,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    @discardableResult
    private func keychainSet(eventId: String, secret: String) -> Bool {
        let data = Data(secret.utf8)
        // Try update
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.eventdesk.public.secret",
            kSecAttrAccount as String: eventId
        ]
        let attrs: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
        if updateStatus == errSecSuccess { return true }
        if updateStatus == errSecItemNotFound {
            var add = query
            add[kSecValueData as String] = data
            let addStatus = SecItemAdd(add as CFDictionary, nil)
            return addStatus == errSecSuccess
        }
        return false
    }
}
