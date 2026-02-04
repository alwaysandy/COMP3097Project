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

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct WebDestination: Identifiable {
    let id = UUID()
    let url: URL
}

// Placeholder Views
struct HomeView: View {
    @State private var selectedDestination: WebDestination? = nil
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("Hacker News Client")
                    .font(.title)
                Article(
                    title: "Reddit",
                    points: 20,
                    articleURL: URL(string: ("https://www.reddit.com/"))!,
                    selectedDestination: $selectedDestination
                )
                Article(
                    title: "Ebay",
                    points: 5000,
                    articleURL: URL(string: ("https://www.ebay.com/"))!,
                    selectedDestination: $selectedDestination
                )
                Spacer()
            }
            .padding()
            .sheet(item: $selectedDestination) { destination in
                SafariView(url: destination.url)
                    .ignoresSafeArea()
                    .interactiveDismissDisabled(false)
            }
        }
    }
}

struct ReadingListView: View {
    var body: some View {
        VStack {
            Text("Saved links for later.")
            Spacer()
        }
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Configure your settings.")
    }
}

struct Article: View {
    var title: String
    var points: Int
    var articleURL: URL
    @Binding var selectedDestination: WebDestination?
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(String(points))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            NavigationLink("Comments") {
                CommentsView()
            }
            .padding(.leading, 8)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
        .onTapGesture {
            selectedDestination = WebDestination(url: articleURL)
        }
    }
}

struct CommentsView: View {
    var body: some View {
        Text("Comments.")
    }
}

#Preview {
    ContentView()
}
