import SwiftUI

struct PlaceholderView: View {
    let title: String
    var body: some View {
        VStack(spacing: 12) {
            Text(title).font(.headline)
            Text("Coming soon").foregroundColor(.secondary)
            Spacer()
        }.padding(16)
    }
}

