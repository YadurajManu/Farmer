import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift // Required for Codable support
import FirebaseAuth

// --- Data Models ---

// Conforms to Codable for easy conversion to/from Firestore
// Identifiable so it can be used in SwiftUI Lists
struct ForumPost: Codable, Identifiable, Hashable {
    @DocumentID var id: String? // Firestore document ID, maps to 'id'
    let userID: String
    let userDisplayName: String
    let userPhotoURL: String?
    var title: String
    var content: String
    var category: String?
    let timestamp: Timestamp // Firestore Timestamp
    var upvotes: Int = 0
    var commentCount: Int = 0 // To be updated via transactions or cloud functions ideally
    var tags: [String]?

    // Computed property for displayable date
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp.dateValue())
    }
}

struct ForumComment: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    let postID: String
    let userID: String
    let userDisplayName: String
    let userPhotoURL: String?
    var content: String
    let timestamp: Timestamp

    // Computed property for displayable date
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp.dateValue())
    }
}

// --- ViewModel ---

@MainActor // Ensures UI updates are on the main thread
class ForumViewModel: ObservableObject {
    @Published var forumPosts: [ForumPost] = []
    @Published var commentsForPost: [ForumComment] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private var db = Firestore.firestore()
    private var auth = Auth.auth()

    // --- Post Management ---

    func fetchPosts(category: String? = nil) {
        self.isLoading = true
        self.errorMessage = nil
        var query: Query = db.collection("forum_posts").order(by: "timestamp", descending: true)

        if let category = category, !category.isEmpty {
            query = query.whereField("category", isEqualTo: category)
        }

        query.addSnapshotListener { querySnapshot, error in
            self.isLoading = false
            if let error = error {
                self.errorMessage = "Error fetching posts: \(error.localizedDescription)"
                print(self.errorMessage!)
                return
            }

            guard let documents = querySnapshot?.documents else {
                self.errorMessage = "No posts found."
                print(self.errorMessage!)
                self.forumPosts = []
                return
            }

            self.forumPosts = documents.compactMap { document -> ForumPost? in
                try? document.data(as: ForumPost.self)
            }
        }
    }

    func createPost(title: String, content: String, category: String?, tags: [String]?, completion: @escaping (Bool, Error?) -> Void) {
        guard let currentUser = auth.currentUser else {
            completion(false, NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }
        self.isLoading = true
        self.errorMessage = nil

        let newPost = ForumPost(
            userID: currentUser.uid,
            userDisplayName: currentUser.displayName ?? "Anonymous",
            userPhotoURL: currentUser.photoURL?.absoluteString,
            title: title,
            content: content,
            category: category,
            timestamp: Timestamp(date: Date()), // Current time
            upvotes: 0,
            commentCount: 0,
            tags: tags
        )

        do {
            _ = try db.collection("forum_posts").addDocument(from: newPost) { error in
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Error creating post: \(error.localizedDescription)"
                    print(self.errorMessage!)
                    completion(false, error)
                } else {
                    completion(true, nil)
                }
            }
        } catch {
            self.isLoading = false
            self.errorMessage = "Error encoding post: \(error.localizedDescription)"
            print(self.errorMessage!)
            completion(false, error)
        }
    }

    // --- Comment Management ---

    func fetchComments(forPostID postID: String) {
        guard !postID.isEmpty else {
            self.commentsForPost = []
            return
        }
        self.isLoading = true
        self.errorMessage = nil
        db.collection("forum_comments")
            .whereField("postID", isEqualTo: postID)
            .order(by: "timestamp", descending: false) // Show oldest comments first, or true for newest
            .addSnapshotListener { querySnapshot, error in
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Error fetching comments: \(error.localizedDescription)"
                    print(self.errorMessage!)
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    self.errorMessage = "No comments found for this post."
                    print(self.errorMessage!)
                    self.commentsForPost = []
                    return
                }

                self.commentsForPost = documents.compactMap { document -> ForumComment? in
                    try? document.data(as: ForumComment.self)
                }
            }
    }

    func addComment(toPostID postID: String, content: String, completion: @escaping (Bool, Error?) -> Void) {
        guard let currentUser = auth.currentUser else {
            completion(false, NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }
        guard !postID.isEmpty else {
            completion(false, NSError(domain: "InputError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Post ID cannot be empty"]))
            return
        }
        self.isLoading = true
        self.errorMessage = nil

        let newComment = ForumComment(
            postID: postID,
            userID: currentUser.uid,
            userDisplayName: currentUser.displayName ?? "Anonymous",
            userPhotoURL: currentUser.photoURL?.absoluteString,
            content: content,
            timestamp: Timestamp(date: Date())
        )

        do {
            _ = try db.collection("forum_comments").addDocument(from: newComment) { error in
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Error adding comment: \(error.localizedDescription)"
                    print(self.errorMessage!)
                    completion(false, error)
                } else {
                    // Also update commentCount on the post
                    self.updateCommentCount(forPostID: postID, increment: true)
                    completion(true, nil)
                }
            }
        } catch {
            self.isLoading = false
            self.errorMessage = "Error encoding comment: \(error.localizedDescription)"
            print(self.errorMessage!)
            completion(false, error)
        }
    }

    // --- Utility / Updates ---

    func updateCommentCount(forPostID postID: String, increment: Bool) {
        let postRef = db.collection("forum_posts").document(postID)
        db.runTransaction { (transaction, errorPointer) -> Any? in
            let postDocument: DocumentSnapshot
            do {
                try postDocument = transaction.getDocument(postRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            guard var commentCount = postDocument.data()?["commentCount"] as? Int else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Unable to retrieve comment count from snapshot \(postDocument)"
                ])
                errorPointer?.pointee = error
                return nil
            }

            commentCount += increment ? 1 : -1
            if commentCount < 0 { commentCount = 0 } // Ensure it doesn't go negative

            transaction.updateData(["commentCount": commentCount], forDocument: postRef)
            return nil
        } completion: { (object, error) in
            if let error = error {
                print("Transaction failed to update comment count: \(error.localizedDescription)")
            } else {
                print("Comment count updated successfully for post \(postID).")
            }
        }
    }

    // Placeholder for upvote functionality
    func upvotePost(postID: String) {
        // This would involve a transaction to increment the 'upvotes' field on the ForumPost.
        // It should also handle preventing multiple upvotes from the same user if desired,
        // which might involve storing upvoted posts in the user's document or a subcollection.
        print("Upvote functionality for post \(postID) to be implemented.")

        let postRef = db.collection("forum_posts").document(postID)
        db.runTransaction { (transaction, errorPointer) -> Any? in
            let postDocument: DocumentSnapshot
            do {
                try postDocument = transaction.getDocument(postRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            guard var upvotes = postDocument.data()?["upvotes"] as? Int else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Unable to retrieve upvotes from snapshot \(postDocument)"
                ])
                errorPointer?.pointee = error
                return nil
            }

            upvotes += 1
            transaction.updateData(["upvotes": upvotes], forDocument: postRef)
            return nil
        } completion: { (object, error) in
            if let error = error {
                self.errorMessage = "Error upvoting post: \(error.localizedDescription)"
                print("Transaction failed to upvote post: \(error.localizedDescription)")
            } else {
                print("Post \(postID) upvoted successfully.")
                // Optionally, refresh the specific post or the list to reflect the change immediately
                // For simplicity here, the snapshot listener on fetchPosts will eventually update it.
            }
        }
    }

    // Add other functions as needed (e.g., editPost, deletePost, editComment, deleteComment)
    // Remember to handle permissions for these operations in your Firestore rules.
}
