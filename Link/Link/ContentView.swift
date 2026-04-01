import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "link")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Link")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
