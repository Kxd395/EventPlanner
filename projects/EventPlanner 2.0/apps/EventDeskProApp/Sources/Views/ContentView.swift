import SwiftUI
#if os(macOS)
import AppKit
#endif
import EventDeskCoreBindings

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var error: String?
    @State private var showShortcuts = false
    @State private var showSettings = false
    @State private var showCommandPalette = false
    @State private var showNewEvent = false
    @State private var tab: AppTab = .events
    enum AppTab { case events, members }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppHeader(title: "EventDeskPro", onNewEvent: { showNewEvent = true }, onOpenSettings: { showSettings = true }, onShowShortcuts: { showShortcuts = true })
                TopTabs(tab: $tab, showCommandPalette: $showCommandPalette, openLogs: openLogs)
                Divider()
                TabContent(tab: tab)
                Divider()
                AppFooter(version: appState.version)
            }
            .sheet(isPresented: $showShortcuts) { ShortcutsOverlay().padding().frame(width: 420) }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showCommandPalette) { CommandPaletteView(onAction: { cmd in handleCommand(cmd); showCommandPalette = false }).frame(width: 520, height: 360) }
            .sheet(isPresented: $showNewEvent) { NewEventSheet(onCreate: { _ in showNewEvent = false }) }
            .onReceive(NotificationCenter.default.publisher(for: .edpOpenNewEventSheet)) { _ in
                showNewEvent = true
            }
        }
    }

    private func createSample() { }

    private func handleCommand(_ cmd: CommandPaletteView.Command) {
        switch cmd {
        case .newEvent: showNewEvent = true
        case .importCSV: break // scoped to event
        case .exportCSV: break // scoped to event
        case .walkIn: break // scoped to attendees
        case .search: break // handled within AttendeesView
        }
    }

    private func openLogs() {
        let fm = FileManager.default
        let support = (try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)) ?? fm.temporaryDirectory
        let analyticsURL = support.appendingPathComponent("EventDeskPro/analytics.jsonl")
        #if os(macOS)
        NSWorkspace.shared.open(analyticsURL)
        #endif
    }
}

private struct TopTabs: View {
    @Binding var tab: ContentView.AppTab
    @Binding var showCommandPalette: Bool
    let openLogs: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Picker("", selection: $tab) {
                Text("Events").tag(ContentView.AppTab.events)
                Text("Members").tag(ContentView.AppTab.members)
            }.pickerStyle(.segmented)
            Spacer()
            Button(action: { showCommandPalette.toggle() }) { Label("Command", systemImage: "command") }
                .keyboardShortcut("P", modifiers: [.command, .shift])
            Button(action: openLogs) { Label("View Logs", systemImage: "doc.text.magnifyingglass") }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

private struct TabContent: View {
    let tab: ContentView.AppTab
    var body: some View {
        Group {
            switch tab {
            case .events:
                EventsListView()
            case .members:
                MembersListView()
            }
        }
    }
}

private struct ShortcutsOverlay: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Keyboard Shortcuts").font(.headline)
            Group {
                HStack { Text("/  Focus Search"); Spacer() }
                HStack { Text("N  New Event"); Spacer() }
                HStack { Text("A  Add Attendee"); Spacer() }
                HStack { Text("W  Walk-in"); Spacer() }
                HStack { Text("Esc  Close Panel"); Spacer() }
            }.font(.caption)
            HStack { Spacer(); Button("Close") { dismiss() }.keyboardShortcut(.cancelAction) }
        }
        .padding(16)
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View { ContentView().environmentObject(AppState()) }
}
#endif
