import SwiftUI

struct ForumPostDetailView: View {
    let post: ForumPost // The post to display
    @ObservedObject var viewModel: ForumViewModel // Passed from ForumHomeView or created if independent
    @State private var newCommentContent: String = ""
    @State private var isCommenting: Bool = false // To focus the text field

    // Access authentication manager to get current user info
    @EnvironmentObject var authManager: AuthenticationManager


    init(post: ForumPost, viewModel: ForumViewModel) {
        self.post = post
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // MARK: - Post Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(post.title)
                        .font(.title)
                        .fontWeight(.bold)

                    HStack {
                        if let photoURLString = post.userPhotoURL, let url = URL(string: photoURLString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable()
                                         .aspectRatio(contentMode: .fill)
                                         .frame(width: 30, height: 30)
                                         .clipShape(Circle())
                                case .failure(_):
                                    Image(systemName: "person.circle.fill").resizable().frame(width: 30, height: 30).foregroundColor(.gray)
                                default:
                                    ProgressView().frame(width: 30, height: 30)
                                }
                            }
                        } else {
                            Image(systemName: "person.circle.fill").resizable().frame(width: 30, height: 30).foregroundColor(.gray)
                        }
                        Text("By \(post.userDisplayName) on \(post.displayDate)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let category = post.category, !category.isEmpty {
                        Text("Category: \(category)")
                            .font(.caption)
                            .padding(4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }

                    Divider()

                    Text(post.content)
                        .font(.body)
                        .lineSpacing(5)

                    HStack {
                        Button {
                            viewModel.upvotePost(postID: post.id ?? "")
                        } label: {
                            Label("\(post.upvotes) Upvotes", systemImage: "arrow.up.circle")
                        }
                        .buttonStyle(.borderless) // Use borderless or plain for subtle buttons in a list

                        Spacer()
                        // Add other actions like share or report later
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(Color(UIColor.systemBackground)) // Adapts to light/dark mode
                .cornerRadius(12)
                .shadow(radius: 3, x: 1, y: 1)

                // MARK: - Comments Section
                Text("Comments (\(viewModel.commentsForPost.count))")
                    .font(.headline)
                    .padding(.horizontal)

                if viewModel.isLoading && viewModel.commentsForPost.isEmpty {
                    ProgressView("Loading comments...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if viewModel.commentsForPost.isEmpty {
                    Text("No comments yet. Be the first to comment!")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.commentsForPost) { comment in
                            CommentRow(comment: comment)
                                .padding(.horizontal)
                        }
                    }
                }

                Spacer(minLength: 20) // Space before comment input

            } // Main VStack
            .padding(.vertical)

        } // ScrollView
        .safeAreaInset(edge: .bottom) {
            // MARK: - Add Comment Input Field (Stays at bottom)
            addCommentField
        }
        .navigationTitle("Post") // Or post.title if short enough
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let postID = post.id {
                viewModel.fetchComments(forPostID: postID)
            }
        }
        .onDisappear {
            // Optional: Clear comments when view disappears if memory is a concern
            // or if you want fresh data each time. Listener will detach if not strong ref.
            // viewModel.commentsForPost = []
        }
    }

    private var addCommentField: some View {
        HStack(spacing: 8) {
            if let user = authManager.user, let photoURL = user.photoURL {
                AsyncImage(url: photoURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                             .frame(width: 36, height: 36).clipShape(Circle())
                    default:
                        Image(systemName: "person.circle.fill").resizable()
                             .frame(width: 36, height: 36).foregroundColor(.gray)
                    }
                }
            } else {
                 Image(systemName: "person.circle.fill").resizable()
                    .frame(width: 36, height: 36).foregroundColor(.gray)
            }

            TextField("Add a comment...", text: $newCommentContent, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(8)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(18) // Rounded corners for the text field
                .lineLimit(1...5) // Allow multiple lines up to 5

            if !newCommentContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button {
                    submitComment()
                } label: {
                    Image(systemName: "paperplane.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color("AccentColor")) // Use app's accent color
                }
                .disabled(viewModel.isLoading) // Disable while submitting
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.thinMaterial) // Adds a nice blur effect, adapting to light/dark mode
    }

    func submitComment() {
        guard let postID = post.id, !newCommentContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        viewModel.addComment(toPostID: postID, content: newCommentContent) { success, error in
            if success {
                newCommentContent = "" // Clear input field
                // Optionally hide keyboard: UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                isCommenting = false // To manage focus if needed
            } else {
                // Handle error (e.g., show an alert)
                print("Error submitting comment: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}

struct CommentRow: View {
    let comment: ForumComment

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if let photoURLString = comment.userPhotoURL, let url = URL(string: photoURLString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                             .aspectRatio(contentMode: .fill)
                             .frame(width: 30, height: 30)
                             .clipShape(Circle())
                    case .failure(_):
                        Image(systemName: "person.circle.fill").resizable().frame(width: 30, height: 30).foregroundColor(.gray)
                    default:
                        ProgressView().frame(width: 30, height: 30)
                    }
                }
            } else {
                Image(systemName: "person.circle.fill").resizable().frame(width: 30, height: 30).foregroundColor(.gray)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.userDisplayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("· \(comment.displayDate)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Text(comment.content)
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading) // Ensure it takes full width for background if needed
    }
}

struct ForumPostDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockViewModel = ForumViewModel()
        let samplePost = ForumPost(
            id: "1",
            userID: "user123",
            userDisplayName: "Farmer Joe",
            userPhotoURL: nil, // Add a URL string here for preview if you have one
            title: "Best time to plant corn in Zone 7?",
            content: "Hey everyone, I'm planning to plant corn this season in Zone 7. What's the ideal soil temperature and date range you'd recommend? Any tips for soil preparation would also be appreciated! I'm thinking about using a no-till method this year but I'm open to suggestions. Last year the yield was a bit disappointing so I'm trying to optimize everything.",
            category: "Corn",
            timestamp: Timestamp(date: Date()),
            upvotes: 15,
            commentCount: 2
        )

        let sampleComment1 = ForumComment(
            id: "c1",
            postID: "1",
            userID: "user456",
            userDisplayName: "Gardener Sue",
            userPhotoURL: nil,
            content: "For Zone 7, I usually aim for late April to early May, once the soil is consistently above 55°F. No-till can be great for moisture retention!",
            timestamp: Timestamp(date: Date(timeIntervalSinceNow: -3600*2)) // 2 hours ago
        )

        let sampleComment2 = ForumComment(
            id: "c2",
            postID: "1",
            userID: "user789",
            userDisplayName: "AgriPro",
            userPhotoURL: nil,
            content: "Make sure to check your soil pH too. Corn prefers slightly acidic to neutral soil. Good luck!",
            timestamp: Timestamp(date: Date(timeIntervalSinceNow: -3600*1)) // 1 hour ago
        )
        mockViewModel.commentsForPost = [sampleComment1, sampleComment2]
        mockViewModel.forumPosts = [samplePost] // Add post to VM if detail view tries to access it via VM state

        let authManager = AuthenticationManager() // Create a mock authManager
        // Simulate a logged-in user for preview if needed
        // authManager.user = User(uid: "previewUser", displayName: "Preview User", email: "preview@example.com", photoURL: nil)


        return NavigationView { // Embed in NavigationView for previewing navigation bar items
            ForumPostDetailView(post: samplePost, viewModel: mockViewModel)
                .environmentObject(authManager) // Provide the mock authManager
        }
    }
}
