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

  // ── Notifications ──────────────────────────────────────────
  Future<int> getUnreadNotifCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_notifCountKey) ?? 3;
  }

  Future<void> clearNotifCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_notifCountKey, 0);
  }
}
