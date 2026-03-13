import SwiftUI
import SafariServices

// MARK: - Models

struct HNStory: Identifiable, Decodable {
    let id: Int
    let title: String
    let url: String?
    let score: Int
    let by: String
    let kids: [Int]?

    var articleURL: URL? {
        guard let urlString = url else { return nil }
        return URL(string: urlString)
    }

    var hackerNewsURL: URL {
        URL(string: "https://news.ycombinator.com/item?id=\(id)")!
    }
}

struct HNComment: Identifiable, Decodable {
    let id: Int
    let by: String?
    let text: String?
    let kids: [Int]?
    let deleted: Bool?
    let dead: Bool?

    var isVisible: Bool {
        deleted != true && dead != true && text != nil && by != nil
    }

    
    var cleanText: String {
        guard let text = text else { return "" }
        var result = text
        result = result.replacingOccurrences(of: "<p>", with: "\n\n")
        result = result.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: "&gt;", with: ">")
        result = result.replacingOccurrences(of: "&lt;", with: "<")
        result = result.replacingOccurrences(of: "&amp;", with: "&")
        result = result.replacingOccurrences(of: "&#x27;", with: "'")
        result = result.replacingOccurrences(of: "&quot;", with: "\"")
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Services

@MainActor
class HackerNewsService: ObservableObject{
    static let shared = HackerNewsService()
    private let baseURL = "https://hacker-news.firebaseio.com/v0"

    private func fetchTopStoryIDs(limit: Int) async throws -> [Int] {
        let url = URL(string: "\(baseURL)/topstories.json")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try Array(JSONDecoder().decode([Int].self, from: data).prefix(limit))
    }

    private func fetchStory(id: Int) async throws -> HNStory {
        let url = URL(string: "\(baseURL)/item/\(id).json")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(HNStory.self, from: data)
    }

    private func fetchComment(id: Int) async throws -> HNComment {
        let url = URL(string: "\(baseURL)/item/\(id).json")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(HNComment.self, from: data)
    }
}


// MARK: - Root

struct ContentView: View {
    var body: some View {
        TabView {
            ArticlesView()
                .tabItem {
                    Label("Articles", systemImage: "newspaper.fill")
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

// MARK: - Safari

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
struct ArticlesView: View {
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
            .fullScreenCover(item: $selectedDestination) { destination in
                SafariView(url: destination.url)
            }
        }
    }
}

struct ReadingListView: View {
    var body: some View {
        VStack {
            Text("Reading List")
                .font(.title)
            Spacer()
        }
    }
}

// MARK: - Settings

struct SettingsView: View {
    @State private var agreed = false
    @State private var dark = false

    var body: some View {
        VStack {
            Text("Settings")
                .font(.title)
            HStack {
                Toggle("I agree to the terms and conditions", isOn: $agreed)
                    .padding()
            }
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
            HStack {
                Toggle("Toggle Dark Mode", isOn: $dark)
                    .padding()
            }
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
            Spacer()
            Spacer()
        }
        .padding()
    }
}

// MARK: - Articles

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
                CommentsView(title: title)
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

// MARK: - Comments

struct CommentsView: View {
    var title: String
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            Text("This is a comment!")
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 16)
    }
}

#Preview {
    ContentView()
}
