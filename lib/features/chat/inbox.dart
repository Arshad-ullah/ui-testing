import 'package:flutter/material.dart';
import 'package:ui_testing/core/models/user_modeld.dart';
import 'package:ui_testing/core/services/api_service.dart';
import 'package:ui_testing/features/chat/chat_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<UserModel> users = [];
  bool loading = true;

  static const currentUserId = "6a33c96a07149162a1c676c2";

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    final response = await ApiService.getUsers();

    if (response.isSuccess) {
      users = response.data!.where((e) => e.id != currentUserId).toList();
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: users.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final user = users[index];

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(user.name[0].toUpperCase()),
                  ),
                  title: Text(user.name),
                  subtitle: Text(user.address),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          currentUserId: currentUserId,
                          userB: user.id,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
