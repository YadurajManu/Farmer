import SwiftUI

struct ForumHomeView: View {
    @StateObject private var viewModel = ForumViewModel()
    @State private var showingCreatePostView = false
    @State private var selectedPost: ForumPost? = nil // For navigation to detail view

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading && viewModel.forumPosts.isEmpty {
                    ProgressView("Loading posts...")
                        .padding()
                } else if let errorMessage = viewModel.errorMessage, !viewModel.forumPosts.isEmpty {
                    // Show error but still show stale data if available
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                    List {
                        postListContent
                    }
                }
                else if let errorMessage = viewModel.errorMessage {
                     // Show error and no data
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("Failed to load posts")
                            .font(.title2)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            viewModel.fetchPosts()
                        }
                        .padding(.horizontal)
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
                else if viewModel.forumPosts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No Forum Posts Yet")
                            .font(.title2)
                        Text("Be the first to start a discussion!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button {
                            showingCreatePostView = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create New Post")
                            }
                        }
                        .padding(.horizontal)
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    List {
                        postListContent
                    }
                    .refreshable {
                        viewModel.fetchPosts()
                    }
                }

                // NavigationLink for post detail view (activated by selectedPost)
                // This is a more robust way to handle programmatic navigation in lists
                if let post = selectedPost {
                     NavigationLink(destination: ForumPostDetailView(post: post, viewModel: viewModel),
                                   tag: post,
                                   selection: $selectedPost) {
                        EmptyView() // Link is invisible, activated by setting selectedPost
                    }
                }
            }
            .navigationTitle("Forum")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreatePostView = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                        Text("New Post")
                    }
                }
            }
            .sheet(isPresented: $showingCreatePostView) {
                // Pass the viewModel if CreateForumPostView needs it,
                // otherwise, it can create its own or use environment object
                CreateForumPostView()
                    .environmentObject(viewModel) // Option 1: Pass as environment object
            }
            .onAppear {
                viewModel.fetchPosts()
            }
        }
        // Use .navigationViewStyle(.stack) if issues with master-detail on iPad,
        // but for a simple list-to-detail, this should be fine.
    }

    // Extracted content for the list to keep the body cleaner
    private var postListContent: some View {
        ForEach(viewModel.forumPosts) { post in
            ForumPostRow(post: post)
                .contentShape(Rectangle()) // Makes the whole row tappable
                .onTapGesture {
                    self.selectedPost = post // Trigger navigation
                }
        }
    }
}

struct ForumPostRow: View {
    let post: ForumPost

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(post.title)
                .font(.headline)
                .lineLimit(2)

            Text(post.content)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(3)

            HStack(spacing: 16) {
                Label("\(post.upvotes)", systemImage: "arrow.up.circle")
                    .font(.caption)
                    .foregroundColor(.blue)

                Label("\(post.commentCount)", systemImage: "bubble.left.and.bubble.right")
                    .font(.caption)
                    .foregroundColor(.green)

                Spacer()

                Text("By: \(post.userDisplayName)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Text(post.displayDate)
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.top, 2)
        }
        .padding(.vertical, 8)
    }
}

struct ForumHomeView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock ViewModel for preview
        let mockViewModel = ForumViewModel()
        // Populate with mock data for preview if desired
        let samplePost1 = ForumPost(
            id: "1",
            userID: "user123",
            userDisplayName: "Farmer Joe",
            userPhotoURL: nil,
            title: "Best time to plant corn?",
            content: "Hey everyone, I'm planning to plant corn this season in Zone 7. What's the ideal soil temperature and date range you'd recommend? Any tips for soil preparation would also be appreciated!",
            category: "Corn",
            timestamp: Timestamp(date: Date()),
            upvotes: 15,
            commentCount: 4,
            tags: ["corn", "planting", "season"]
        )
        let samplePost2 = ForumPost(
            id: "2",
            userID: "user456",
            userDisplayName: "Gardener Sue",
            userPhotoURL: nil,
            title: "Dealing with aphids on cotton",
            content: "I've noticed a significant aphid infestation on my young cotton plants. Looking for organic or effective chemical solutions that have worked well for others. Help!",
            category: "Cotton",
            timestamp: Timestamp(date: Date(timeIntervalSinceNow: -3600*24)), // Yesterday
            upvotes: 22,
            commentCount: 8,
            tags: ["cotton", "pests", "aphids"]
        )
        mockViewModel.forumPosts = [samplePost1, samplePost2]

        return ForumHomeView()
            .environmentObject(mockViewModel) // For preview
    }
}
