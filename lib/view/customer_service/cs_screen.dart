import 'package:flutter/material.dart';
import 'package:flutter_supabase_chat_core/flutter_supabase_chat_core.dart';
import 'src/pages/CSHome.dart';
class CsScreen extends StatelessWidget {
  const CsScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) =>  const UserOnlineStateObserver(
    child: CSHomePage(),
  );
}
