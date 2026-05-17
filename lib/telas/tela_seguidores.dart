import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tema/tema_app.dart';

const _usuariosMock = [
  {'name': 'Bruno Costa', 'handle': '@brunoc', 'bio': 'Chef profissional · SP', 'following': true},
  {'name': 'Ana Paula', 'handle': '@anap', 'bio': 'Doces & confeitaria 🍰', 'following': false},
  {'name': 'Ricardo Souza', 'handle': '@ricsouza', 'bio': 'Cozinha italiana caseira', 'following': true},
  {'name': 'Júlia Lima', 'handle': '@juliali', 'bio': 'Comida saudável & fit', 'following': false},
  {'name': 'Pedro Henrique', 'handle': '@pedrohc', 'bio': 'Churrasqueiro de fim de semana', 'following': true},
  {'name': 'Larissa Mendes', 'handle': '@larim', 'bio': 'Massas frescas artesanais', 'following': false},
  {'name': 'Felipe Andrade', 'handle': '@felipean', 'bio': 'Cozinheiro amador apaixonado', 'following': true},
  {'name': 'Camila Rocha', 'handle': '@camir', 'bio': 'Vegetariana criativa 🥬', 'following': false},
];

class TelaSeguidores extends StatefulWidget {
  final String titulo;
  final bool modoSeguindo;

  const TelaSeguidores({
    super.key,
    required this.titulo,
    this.modoSeguindo = false,
  });

  @override
  State<TelaSeguidores> createState() => _TelaSeguidoresState();
}

class _TelaSeguidoresState extends State<TelaSeguidores> {
  late Map<String, bool> _following;

  @override
  void initState() {
    super.initState();
    _following = {
      for (final u in _usuariosMock)
        u['handle'] as String: widget.modoSeguindo ? true : u['following'] as bool,
    };
  }

  List<Map<String, dynamic>> get _lista {
    if (widget.modoSeguindo) {
      return _usuariosMock.where((u) => _following[u['handle']] == true).toList();
    }
    return List.from(_usuariosMock);
  }

  String _iniciais(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final lista = _lista;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: context.chipColor, shape: BoxShape.circle),
                      child: Icon(Icons.arrow_back_ios_new, size: 16, color: context.textColor),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(widget.titulo,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: context.textColor)),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            Expanded(
              child: lista.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('👥', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            widget.modoSeguindo ? 'Você não segue ninguém ainda' : 'Nenhum seguidor ainda',
                            style: GoogleFonts.poppins(fontSize: 14, color: context.mutedColor),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                      itemCount: lista.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: context.borderColor),
                      itemBuilder: (_, i) => _buildItem(lista[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> u) {
    final handle = u['handle'] as String;
    final isFollowing = _following[handle] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              _iniciais(u['name'] as String),
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u['name'] as String,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: context.textColor)),
                Text(
                  '${u['handle']} · ${u['bio']}',
                  style: GoogleFonts.poppins(fontSize: 11, color: context.mutedColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _following[handle] = !isFollowing),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isFollowing ? Colors.transparent : AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                border: isFollowing ? Border.all(color: context.borderColor, width: 1.5) : null,
              ),
              alignment: Alignment.center,
              child: Text(
                isFollowing ? 'Seguindo' : 'Seguir',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isFollowing ? context.textColor : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
