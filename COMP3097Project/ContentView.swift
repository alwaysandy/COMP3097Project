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

    func fetchTopStories(limit: Int = 20) async throws -> [HNStory] {
        let ids = try await fetchTopStoryIDs(limit: limit)
        return try await withThrowingTaskGroup(of: HNStory?.self) { group in
            for id in ids {
                group.addTask { try? await self.fetchStory(id: id) }
            }
            var stories: [HNStory] = []
            for try await story in group {
                if let story { stories.append(story) }
            }
            // flip to [storyid:rank]
            let idOrder = Dictionary(uniqueKeysWithValues: ids.enumerated().map { ($1, $0) })
            return stories.sorted { (idOrder[$0.id] ?? 0) < (idOrder[$1.id] ?? 0) }
        }
    }

     func fetchComments(ids: [Int]) async throws -> [HNComment] {
        try await withThrowingTaskGroup(of: HNComment?.self) { group in
            for id in ids {
                group.addTask { try? await self.fetchComment(id: id) }
            }
            var comments: [HNComment] = []
            for try await comment in group {
                if let comment, comment.isVisible { comments.append(comment) }
            }
            let idOrder = Dictionary(uniqueKeysWithValues: ids.enumerated().map { ($1, $0) })
            return comments.sorted { (idOrder[$0.id] ?? 0) < (idOrder[$1.id] ?? 0) }
        }
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

// MARK: - Articles

@MainActor
class ArticlesViewModel: ObservableObject {
    @Published var stories: [HNStory] = []
    @Published var selectedDestination: WebDestination?

    func load() async {
        stories = (try? await HackerNewsService.shared.fetchTopStories()) ?? []
    }

    func selectStory(_ story: HNStory) {
        selectedDestination = WebDestination(url: story.articleURL ?? story.hackerNewsURL)
    }
}

struct ArticlesView: View {
    @StateObject private var vm = ArticlesViewModel()

    var body: some View {
        NavigationStack {
            List(vm.stories) { story in
                ArticleRow(story: story, onTap: { vm.selectStory(story) })
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .navigationTitle("Hacker News")
            .refreshable { await vm.load() }
            .fullScreenCover(item: $vm.selectedDestination) { dest in
                SafariView(url: dest.url).ignoresSafeArea()
            }
            .task { await vm.load() }
        }
    }
}

struct ArticleRow: View {
    let story: HNStory
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(story.title).font(.headline)
            HStack {
                Text("\(story.score) pts · \(story.by)").foregroundStyle(.secondary).font(.caption)
                Spacer()
                NavigationLink {
                    CommentsView(story: story)
                } label: {
                    Image(systemName: "bubble.right")
                        .font(.caption)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
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
