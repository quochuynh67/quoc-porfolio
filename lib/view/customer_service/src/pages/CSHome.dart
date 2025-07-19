import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_supabase_chat_core/flutter_supabase_chat_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth.dart';
import 'rooms.dart';
import 'users.dart';

class CSHomePage extends StatefulWidget {
  const CSHomePage({super.key});

  @override
  State<CSHomePage> createState() => _CSHomePageState();
}

class _CSHomePageState extends State<CSHomePage> {
  bool _error = false;
  bool _initialized = false;
  User? _user;

  @override
  void initState() {
    initializeSupabase();
    super.initState();
  }

  SupabaseChatCoreConfig config = const SupabaseChatCoreConfig(
    'public',
    'rooms',
    'rooms_l',
    'messages',
    'messages_l',
    'users',
    'online-user-',
    //online-user-${uid}
    'chat-user-typing-',
    //chat-user-typing-${room_id}
    'chats_assets',
  );

  void initializeSupabase() async {
    SupabaseChatCore.instance.setConfig(config);
    try {
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        setState(() {
          _user = data.session?.user;
        });
      });
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      setState(() {
        _error = true;
      });
    }
  }

  void logout() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container();
    }

    if (!_initialized) {
      return Container();
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add,
            ),
            onPressed: _user == null
                ? null
                : () {
                    // Navigator.of(context).push(
                    //   MaterialPageRoute(
                    //     builder: (context) => const UsersPage(),
                    //   ),
                    // );
                    showDialog(
                      context: context,
                      builder: (context) {
                        return const AlertDialog(
                          backgroundColor: Colors.transparent,
                          content: UsersPage(),
                          contentPadding: EdgeInsets.all(0),
                        );
                      },
                    );
                  },
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _user == null ? null : logout,
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text('Rooms',
            style: TextStyle(fontSize: 20, color: Colors.white)),
      ),
      body: _user == null
          ? Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.only(
                bottom: 200,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Not authenticated'),
                  TextButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return const AlertDialog(
                              backgroundColor: Colors.transparent,
                              content: AuthScreen(),
                              contentPadding: EdgeInsets.all(0),
                            );
                          });
                    },
                    child: const Text('Login'),
                  ),
                ],
              ),
            )
          : RoomsPage(),
    );
  }
}
