import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  Map<String, dynamic>? selectedUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Users'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search by userid',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('username', isGreaterThanOrEqualTo: searchQuery)
                  .where('username', isLessThanOrEqualTo: "$searchQuery\uf8ff")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No users found'));
                }
                final users = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(user['DP'] ?? ''),
                        child: user['DP'] == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(user['username'] ?? 'N/A'),
                      subtitle: Text(user['name'] ?? 'N/A'),
                      onTap: () {
                        setState(() {
                          selectedUser = user.data() as Map<String, dynamic>;
                          selectedUser!['userId'] = user.id;
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfilePage(
                              userData: selectedUser!,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class UserProfilePage extends StatelessWidget {
  final Map<String, dynamic> userData;

  const UserProfilePage({required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userData['username'] ?? 'User Profile'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(userData['DP'] ?? ''),
                child: userData['DP'] == null ? const Icon(Icons.person, size: 50) : null,
              ),
            ),
            const SizedBox(height: 16),
            Text('Name: ${userData['name'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Username: ${userData['username'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Email: ${userData['email'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('LinkedIn: ${userData['linkedin'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
            const Spacer(),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _handleSendMessage(context, userData['userId']),
                icon: const Icon(Icons.message),
                label: const Text('Send Message'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSendMessage(BuildContext context, String receiverId) async {
    final currentUserId = "currentUserId"; // Replace with the logged-in user's ID
    final existingChat = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: [currentUserId, receiverId])
        .get();

    if (existingChat.docs.isNotEmpty) {
      // Chat exists, navigate to chat page
      final chatId = existingChat.docs.first.id;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(chatId: chatId),
        ),
      );
    } else {
      // Create a new chat
      final newChat = await FirebaseFirestore.instance.collection('chats').add({
        'participants': [currentUserId, receiverId],
        'createdAt': FieldValue.serverTimestamp(),
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(chatId: newChat.id),
        ),
      );
    }
  }
}

class ChatPage extends StatelessWidget {
  final String chatId;

  const ChatPage({required this.chatId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Center(
        child: Text('Chat ID: $chatId'),
      ),
    );
  }
}
