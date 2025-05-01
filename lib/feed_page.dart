import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Connect'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No posts available.'));
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostCard(
                username: post['username'],
                profilePicture: post['profilePicture'],
                imageUrl: post['imageUrl'],
                caption: post['caption'],
                likes: post['likes'],
                postId: post.id,
                uploaderId: (post.data() as Map<String, dynamic>).containsKey('userId')
                    ? post['userId']
                    : 'unknownUserId',
                likedBy: List<String>.from(post['likedBy'] ?? []),
              );
            },
          );
        },
      ),
    );
  }
}

class PostCard extends StatefulWidget {
  final String username;
  final String profilePicture;
  final String imageUrl;
  final String caption;
  final int likes;
  final String postId;
  final String uploaderId; // Added uploader's UID
  final List<String> likedBy;

  const PostCard({
    super.key,
    required this.username,
    required this.profilePicture,
    required this.imageUrl,
    required this.caption,
    required this.likes,
    required this.postId,
    required this.uploaderId,
    required this.likedBy,
  });

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isLiked = false;
  bool isAnimating = false;
  int likeCount = 0;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && widget.likedBy.contains(currentUser.uid)) {
      isLiked = true;
    }
    likeCount = widget.likes;
  }

  /// Function to handle like/unlike
  Future<void> toggleLike() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    setState(() {
      isAnimating = true;
    });

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);

      if (!snapshot.exists) return;

      final List<String> likedBy = List<String>.from(snapshot['likedBy'] ?? []);
      int currentLikes = snapshot['likes'] ?? 0;

      if (likedBy.contains(currentUser.uid)) {
        // Unlike the post
        likedBy.remove(currentUser.uid);
        currentLikes--;
      } else {
        // Like the post
        likedBy.add(currentUser.uid);
        currentLikes++;
      }

      transaction.update(postRef, {
        'likedBy': likedBy,
        'likes': currentLikes,
      });

      setState(() {
        isLiked = likedBy.contains(currentUser.uid);
        likeCount = currentLikes;
      });
    });

    setState(() {
      isAnimating = false;
    });
  }

  /// Function to handle Direct DM navigation
  Future<void> handleDirectDM(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final conversationRef = FirebaseFirestore.instance.collection('conversations');

    try {
      // Query to check if a conversation already exists
      final existingConversation = await conversationRef
          .where('participants', arrayContains: currentUser.uid)
          .get();

      String conversationId = '';

      for (var doc in existingConversation.docs) {
        final participants = List<String>.from(doc['participants']);
        if (participants.contains(widget.uploaderId)) {
          conversationId = doc.id;
          break;
        }
      }

      // If conversation does not exist, create one
      if (conversationId.isEmpty) {
        final newConversationRef = conversationRef.doc();
        await newConversationRef.set({
          'participants': [currentUser.uid, widget.uploaderId],
          'lastMessage': '',
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
        });
        conversationId = newConversationRef.id;
      }

      // Navigate to Messages Page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            conversationId: conversationId,
            otherUserId: widget.uploaderId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error navigating to DM: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(widget.profilePicture),
            ),
            title: Text(widget.username, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Image.network(widget.imageUrl),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(widget.caption),
          ),
          Row(
            children: [
              AnimatedScale(
                scale: isAnimating ? 1.5 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey,
                  ),
                  onPressed: toggleLike,
                ),
              ),
              Text('$likeCount likes'),
              IconButton(
                icon: const Icon(Icons.message),
                onPressed: () => handleDirectDM(context),
              ),
              const Text('Direct DM'),
            ],
          ),
        ],
      ),
    );
  }
}
