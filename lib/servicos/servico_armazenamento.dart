import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/receita.dart';
import '../modelos/perfil_usuario.dart';

class StorageService {
  static const _favoritesKey = 'favorites';
  static const _historyKey = 'history';
  static const _communityKey = 'community';
  static const _profileKey = 'user_profile';
  static const _likedPostsKey = 'liked_posts';
  static const _onboardingKey = 'onboarding_done';
  static const _notifCountKey = 'notif_unread_count';
  static const _passwordKey = 'user_password';
  static const _realNotificationsKey = 'real_notifications';
  static const _listaComprasKey = 'lista_compras';

  // ── Onboarding ─────────────────────────────────────────────
  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  // ── User Profile ───────────────────────────────────────────
  Future<UserProfile?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_profileKey);
    if (str == null) return null;
    try {
      return UserProfile.fromJsonString(str);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, profile.toJsonString());
  }

  // ── Favoritos ──────────────────────────────────────────────
  Future<List<Recipe>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_favoritesKey) ?? [];
    return list.map(Recipe.fromJsonString).toList().reversed.toList();
  }

  Future<void> addFavorite(Recipe recipe) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_favoritesKey) ?? [];
    list.removeWhere((s) => Recipe.fromJsonString(s).id == recipe.id);
    list.add(recipe.toJsonString());
    await prefs.setStringList(_favoritesKey, list);
  }

  Future<void> removeFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_favoritesKey) ?? [];
    list.removeWhere((s) => Recipe.fromJsonString(s).id == id);
    await prefs.setStringList(_favoritesKey, list);
  }

  Future<bool> isFavorite(String id) async {
    final favorites = await getFavorites();
    return favorites.any((r) => r.id == id);
  }

  // ── Histórico ──────────────────────────────────────────────
  Future<List<Recipe>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_historyKey) ?? [];
    return list.map(Recipe.fromJsonString).toList().reversed.toList();
  }

  Future<void> addToHistory(Recipe recipe) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_historyKey) ?? [];
    list.removeWhere((s) => Recipe.fromJsonString(s).query == recipe.query);
    list.add(recipe.toJsonString());
    if (list.length > 50) list.removeAt(0);
    await prefs.setStringList(_historyKey, list);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  // ── Comunidade ─────────────────────────────────────────────
  Future<List<Recipe>> getCommunityRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_communityKey) ?? [];
    return list.map(Recipe.fromJsonString).toList().reversed.toList();
  }

  Future<void> publishRecipe(Recipe recipe) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_communityKey) ?? [];
    list.add(recipe.toJsonString());
    await prefs.setStringList(_communityKey, list);
  }

  Future<void> deleteFromCommunity(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_communityKey) ?? [];
    list.removeWhere((s) => Recipe.fromJsonString(s).id == id);
    await prefs.setStringList(_communityKey, list);
  }

  // ── Liked Posts ────────────────────────────────────────────
  Future<Set<String>> getLikedPosts() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_likedPostsKey) ?? []).toSet();
  }

  Future<void> toggleLikedPost(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final liked = (prefs.getStringList(_likedPostsKey) ?? []).toSet();
    if (liked.contains(postId)) {
      liked.remove(postId);
    } else {
      liked.add(postId);
    }
    await prefs.setStringList(_likedPostsKey, liked.toList());
  }

  // ── Password ───────────────────────────────────────────────
  Future<void> savePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_passwordKey, password);
  }

  Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_passwordKey);
  }

  // ── Notifications ──────────────────────────────────────────
  Future<int> getUnreadNotifCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_notifCountKey) ?? 0;
  }

  Future<void> clearNotifCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_notifCountKey, 0);
    final list = prefs.getStringList(_realNotificationsKey) ?? [];
    final updated = list.map((s) {
      final m = Map<String, dynamic>.from(jsonDecode(s) as Map);
      m['unread'] = false;
      return jsonEncode(m);
    }).toList();
    await prefs.setStringList(_realNotificationsKey, updated);
  }

  Future<void> addNotification({required String icon, required String text}) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_realNotificationsKey) ?? [];
    final notif = jsonEncode({'icon': icon, 'text': text, 'time': 'Agora', 'unread': true});
    list.insert(0, notif);
    if (list.length > 20) list.removeLast();
    await prefs.setStringList(_realNotificationsKey, list);
    final count = prefs.getInt(_notifCountKey) ?? 0;
    await prefs.setInt(_notifCountKey, count + 1);
  }

  Future<List<Map<String, dynamic>>> getRealNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_realNotificationsKey) ?? [];
    return list
        .map((s) => Map<String, dynamic>.from(jsonDecode(s) as Map))
        .toList();
  }

  Future<void> clearAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_realNotificationsKey);
    await prefs.setInt(_notifCountKey, 0);
  }

  // ── Lista de Compras ───────────────────────────────────────
  Future<List<Map<String, dynamic>>> getListaCompras() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_listaComprasKey) ?? [];
    return list
        .map((s) => Map<String, dynamic>.from(jsonDecode(s) as Map))
        .toList();
  }

  Future<void> saveListaCompras(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _listaComprasKey,
      items.map(jsonEncode).toList(),
    );
  }
}
