import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  Future<Map<String, dynamic>> fetchUserData(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return doc.data() ?? {};
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return {};
    }
  }

  Future<void> _startNewConversation(BuildContext context) async {
    TextEditingController userIdController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Start a New Conversation'),
          content: TextField(
            controller: userIdController,
            decoration: const InputDecoration(
              labelText: 'Enter User ID',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String otherUserId = userIdController.text.trim();
                Navigator.pop(context);
                if (otherUserId.isEmpty) return;

                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) return;

                try {
                  // Check for an existing conversation
                  final querySnapshot = await FirebaseFirestore.instance
                      .collection('conversations')
                      .where('participants', arrayContains: currentUser.uid)
                      .get();

                  DocumentSnapshot? existingConversation;
                  for (var doc in querySnapshot.docs) {
                    List participants = doc['participants'] ?? [];
                    if (participants.contains(otherUserId)) {
                      existingConversation = doc;
                      break;
                    }
                  }

                  if (existingConversation != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          conversationId: existingConversation!.id,
                          otherUserId: otherUserId,
                        ),
                      ),
                    );
                  } else {
                    // Create a new conversation
                    final newConversation =
                        await FirebaseFirestore.instance.collection('conversations').add({
                      'participants': [currentUser.uid, otherUserId],
                      'lastMessage': '',
                      'lastMessageTimestamp': FieldValue.serverTimestamp(),
                    });

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          conversationId: newConversation.id,
                          otherUserId: otherUserId,
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  print('Error starting conversation: $e');
                }
              },
              child: const Text('Start'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(
        child: Text('You need to log in to view messages.'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _startNewConversation(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('conversations')
            .where('participants', arrayContains: currentUser.uid)
            .orderBy('lastMessageTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No conversations yet.'));
          }

          final conversations = snapshot.data!.docs;

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final participants =
                  List<String>.from(conversation['participants'] ?? []);

              final otherUserId = participants.firstWhere(
                (id) => id != currentUser.uid,
                orElse: () => 'UnknownUser',
              );

              if (otherUserId == 'UnknownUser') {
                return const ListTile(
                  title: Text('Unknown user'),
                );
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey,
                      ),
                      title: Text('Loading...'),
                    );
                  }

                  final otherUserData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: otherUserData['profilePicture'] != null
                          ? NetworkImage(otherUserData['profilePicture'])
                          : null,
                      backgroundColor: Colors.grey[300],
                    ),
                    title: Text(otherUserData['username'] ?? 'Unknown User'),
                    subtitle: Text(conversation['lastMessage'] ?? ''),
                    trailing: Text(
                      conversation['lastMessageTimestamp'] != null
                          ? (conversation['lastMessageTimestamp'] as Timestamp)
                              .toDate()
                              .toLocal()
                              .toString()
                              .substring(0, 16)
                          : '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            conversationId: conversation.id,
                            otherUserId: otherUserId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
