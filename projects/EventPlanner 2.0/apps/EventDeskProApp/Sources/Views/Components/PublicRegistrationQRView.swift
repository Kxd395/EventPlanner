import SwiftUI
import CryptoKit
import AppKit
import CoreImage

private func signedEventURL(host: String = "https://r.eventdesk.pro",
                            eventId: String,
                            secret: String,
                            ttlMinutes: Int = 1440) -> URL? {
    let exp = Int64(Date().addingTimeInterval(TimeInterval(ttlMinutes * 60)).timeIntervalSince1970)
    let message = "\(eventId)|\(exp)"
    let key = SymmetricKey(data: Data(secret.utf8))
    let sig = HMAC<SHA256>.authenticationCode(for: Data(message.utf8), using: key)
    let token = Data(sig).base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
    var c = URLComponents(string: "\(host)/e/\(eventId)")!
    c.queryItems = [
        URLQueryItem(name: "t", value: token),
        URLQueryItem(name: "exp", value: String(exp))
    ]
    return c.url
}

private func qrImage(from string: String, size: CGFloat = 512) -> NSImage? {
    guard let data = string.data(using: .utf8),
          let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
    filter.setValue(data, forKey: "inputMessage")
    filter.setValue("M", forKey: "inputCorrectionLevel")
    guard let ci = filter.outputImage?
        .transformed(by: CGAffineTransform(scaleX: size/31, y: size/31)) else { return nil }
    let rep = NSCIImageRep(ciImage: ci)
    let img = NSImage(size: rep.size)
    img.addRepresentation(rep)
    return img
}

struct PublicRegistrationQRView: View {
    let eventId: String
    let eventSecret: String
    var host: String = "https://r.eventdesk.pro"
    var ttlMinutes: Int = 1440

    @State private var link: URL?
    @State private var code: NSImage?

    var body: some View {
        VStack(spacing: 14) {
            Group {
                if let code {
                    Image(nsImage: code)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 256, height: 256)
                } else {
                    ProgressView().onAppear(perform: regenerate)
                }
            }
            if let s = link?.absoluteString {
                Text(s).font(.footnote).lineLimit(3).multilineTextAlignment(.center)
            }
            HStack {
                Button("Copy Link", action: copyLink)
                Button("Save PNG", action: savePNG)
                Button("Regenerate", action: regenerate)
            }
        }
        .padding()
        .onAppear(perform: regenerate)
    }

    private func regenerate() {
        let url = signedEventURL(host: host, eventId: eventId, secret: eventSecret, ttlMinutes: ttlMinutes)
        link = url
        code = url.flatMap { qrImage(from: $0.absoluteString, size: 512) }
    }

    private func copyLink() {
        guard let s = link?.absoluteString else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(s, forType: .string)
    }

    private func savePNG() {
        guard let img = code,
              let tiff = img.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .png, properties: [:]) else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "event-qr.png"
        panel.begin { resp in
            if resp == .OK, let url = panel.url {
                try? data.write(to: url)
            }
        }
    }
}

