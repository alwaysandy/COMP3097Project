import SwiftUI
import SafariServices

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            ReadingListView()
                .tabItem {
                    Label("Reading List", systemImage: "house.fill")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear.circle.fill")
                }
        }
    }
}

// Placeholder Views
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        // Create and return the SFSafariViewController instance
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed for a basic implementation
    }
}

struct HomeView: View {
    @State private var showSafari: Bool = false
    let url = URL(string: "https://www.apple.com")!

    var body: some View {
        Button("Open Apple Website") {
            showSafari.toggle()
        }
        .fullScreenCover(isPresented: $showSafari) {
            SafariView(url: url)
                .ignoresSafeArea()
        }
    }
}

struct ReadingListView: View {
    var body: some View {
        Text("Saved links for later.")
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Configure your settings.")
    }
}

#Preview {
    ContentView()
}
