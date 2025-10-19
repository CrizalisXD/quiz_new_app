import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kCurrentUser = 'auth.current_user';

final currentUserProvider =
    StateNotifierProvider<CurrentUserController, String>((ref) {
  return CurrentUserController()..load();
});

class CurrentUserController extends StateNotifier<String> {
  CurrentUserController() : super('guest');

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    state = p.getString(_kCurrentUser) ?? 'guest';
  }

  Future<void> switchTo(String userId) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kCurrentUser, userId);
    state = userId;
  }

  Future<void> logoutToGuest() => switchTo('guest');
}
