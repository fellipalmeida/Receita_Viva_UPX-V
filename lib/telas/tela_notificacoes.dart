import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tema/tema_app.dart';
import '../servicos/servico_armazenamento.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _storage = StorageService();
  List<Map<String, dynamic>> _notifs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notifs = await _storage.getRealNotifications();
    if (mounted) setState(() { _notifs = notifs; _loading = false; });
  }

  Future<void> _markRead(int i) async {
    setState(() => _notifs[i]['unread'] = false);
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Limpar notificações',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Deseja apagar todas as notificações?',
            style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar',
                style: GoogleFonts.poppins(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Limpar',
                style: GoogleFonts.poppins(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _storage.clearAllNotifications();
      if (mounted) setState(() => _notifs = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          if (_notifs.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: Text(
                'Limpar',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _notifs.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  itemCount: _notifs.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: context.borderColor, height: 1),
                  itemBuilder: (_, i) {
                    final n = _notifs[i];
                    final unread = n['unread'] as bool? ?? false;
                    return GestureDetector(
                      onTap: () => _markRead(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        color: unread
                            ? const Color(0x0AD4623A)
                            : Colors.transparent,
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0x22D4623A),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(n['icon'] as String,
                                  style: const TextStyle(fontSize: 20)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n['text'] as String,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: context.textColor,
                                      fontWeight: unread
                                          ? FontWeight.w500
                                          : FontWeight.w400,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    n['time'] as String,
                                    style: GoogleFonts.poppins(
                                        fontSize: 11, color: context.mutedColor),
                                  ),
                                ],
                              ),
                            ),
                            if (unread)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔔', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 20),
          Text(
            'Sem notificações',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Use o Chef IA ou publique uma receita\npara receber notificações aqui.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 13, color: context.mutedColor),
          ),
        ],
      ),
    );
  }
}
