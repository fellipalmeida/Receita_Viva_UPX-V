import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tema/tema_app.dart';
import '../dados/dados_mock.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<Map<String, dynamic>> _notifs;

  @override
  void initState() {
    super.initState();
    _notifs = mockNotifications.map((n) => Map<String, dynamic>.from(n)).toList();
  }

  void _markAllRead() {
    setState(() {
      for (final n in _notifs) {
        n['unread'] = false;
      }
    });
  }

  void _markRead(int i) {
    setState(() => _notifs[i]['unread'] = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          TextButton(
            onPressed: _markAllRead,
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
      body: ListView.separated(
        itemCount: _notifs.length,
        separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
        itemBuilder: (_, i) {
          final n = _notifs[i];
          final unread = n['unread'] as bool;
          return GestureDetector(
            onTap: () => _markRead(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: unread ? const Color(0x0AD4623A) : Colors.transparent,
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0x22D4623A),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(n['icon'] as String, style: const TextStyle(fontSize: 20)),
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
                            color: AppColors.text,
                            fontWeight: unread ? FontWeight.w500 : FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          n['time'] as String,
                          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (unread)
                    Container(
                      width: 8, height: 8,
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
}
