import Foundation
import SwiftUI
import EventDeskCoreBindings

final class RegistrationSyncService: ObservableObject {
    @AppStorage("apiBase") private var apiBase: String = ""
    private var timer: Timer?
    private var lastSync: Date = Date(timeIntervalSince1970: 0)

    func start(eventId: String, interval: TimeInterval = 12.0) {
        stop()
        // Kick once immediately
        pull(eventId: eventId)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.pull(eventId: eventId)
        }
    }

    func stop() {
        timer?.invalidate(); timer = nil
    }

    private func pull(eventId: String) {
        guard !apiBase.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let since = Int(lastSync.timeIntervalSince1970)
        guard let url = URL(string: "\(apiBase)/api/events/\(eventId)/registrations?since=\(since)") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: req) { data, rsp, _ in
            guard let data = data, let http = rsp as? HTTPURLResponse, http.statusCode == 200 else { return }
            // Expected schema: array of rows with at least email, first_name, last_name, company
            guard let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }
            if arr.isEmpty { self.lastSync = Date(); return }
            var csv = "email,firstname,lastname,company,status\n"
            for r in arr {
                let email = (r["email"] as? String) ?? ""
                let first = (r["first_name"] as? String) ?? ""
                let last  = (r["last_name"] as? String) ?? ""
                let company = (r["company"] as? String) ?? ""
                csv += "\(email),\(first),\(last),\(company),preregistered\n"
            }
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    _ = try EDPCore.shared.csvCommit(eventId: eventId, csvText: csv)
                    self.lastSync = Date()
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .edpEventCountsShouldRefresh, object: nil, userInfo: ["eventId": eventId])
                    }
                } catch {
                    // Swallow errors for now
                }
            }
        }
        task.resume()
    }
}
