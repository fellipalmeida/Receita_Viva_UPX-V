import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../tema/tema_app.dart';
import '../main.dart';

class TelaConfiguracoes extends StatefulWidget {
  const TelaConfiguracoes({super.key});

  @override
  State<TelaConfiguracoes> createState() => _TelaConfiguracoesState();
}

class _TelaConfiguracoesState extends State<TelaConfiguracoes> {
  bool _notifReceitas = true;
  bool _notifComunidade = true;
  bool _notifChef = false;

  bool get _modoEscuro => themeNotifier.value == ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notifReceitas = prefs.getBool('notif_receitas') ?? true;
        _notifComunidade = prefs.getBool('notif_comunidade') ?? true;
        _notifChef = prefs.getBool('notif_chef') ?? false;
      });
    }
  }

  Future<void> _salvar(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _toggleDark(bool v) {
    themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
    setState(() {});
  }

  Future<void> _alterarSenha() async {
    final senhaAtualCtrl = TextEditingController();
    final novaSenhaCtrl = TextEditingController();
    final confirmarCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          bool verAtual = false;
          bool verNova = false;
          bool verConfirmar = false;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Alterar senha',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SenhaField(
                    label: 'Senha atual',
                    controller: senhaAtualCtrl,
                    mostrar: verAtual,
                    onToggle: () => setSheet(() => verAtual = !verAtual),
                  ),
                  const SizedBox(height: 14),
                  _SenhaField(
                    label: 'Nova senha',
                    controller: novaSenhaCtrl,
                    mostrar: verNova,
                    onToggle: () => setSheet(() => verNova = !verNova),
                  ),
                  const SizedBox(height: 14),
                  _SenhaField(
                    label: 'Confirmar nova senha',
                    controller: confirmarCtrl,
                    mostrar: verConfirmar,
                    onToggle: () => setSheet(() => verConfirmar = !verConfirmar),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final senhaArmazenada = prefs.getString('senha_usuario') ?? '';

                        if (senhaArmazenada.isNotEmpty &&
                            senhaAtualCtrl.text != senhaArmazenada) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Senha atual incorreta',
                                    style: GoogleFonts.poppins(fontSize: 13)),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                          return;
                        }
                        if (novaSenhaCtrl.text.length < 6) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Nova senha deve ter pelo menos 6 caracteres',
                                    style: GoogleFonts.poppins(fontSize: 13)),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                          return;
                        }
                        if (novaSenhaCtrl.text != confirmarCtrl.text) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Senhas não coincidem',
                                    style: GoogleFonts.poppins(fontSize: 13)),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                          return;
                        }
                        await prefs.setString('senha_usuario', novaSenhaCtrl.text);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Senha alterada com sucesso!',
                                  style: GoogleFonts.poppins(fontSize: 13)),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Salvar',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    senhaAtualCtrl.dispose();
    novaSenhaCtrl.dispose();
    confirmarCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: context.chipColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 16,
                        color: context.textColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Configurações',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: context.textColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  children: [
                    _Secao(
                      titulo: 'Aparência',
                      filhos: [
                        _Linha(
                          icone: '🌙',
                          label: 'Modo escuro',
                          sub: _modoEscuro ? 'Ativado' : 'Desativado',
                          direita: _Toggle(
                            valor: _modoEscuro,
                            onChange: _toggleDark,
                          ),
                        ),
                        _Linha(
                          icone: '🌐',
                          label: 'Idioma',
                          sub: 'Português (Brasil)',
                          direita: Icon(
                            Icons.chevron_right,
                            color: context.mutedColor,
                            size: 20,
                          ),
                          onTap: () {},
                        ),
                        _Linha(
                          icone: '📏',
                          label: 'Unidades de medida',
                          sub: 'g, kg, ml, L, °C (padrão brasileiro)',
                          borda: false,
                        ),
                      ],
                    ),
                    _Secao(
                      titulo: 'Notificações',
                      filhos: [
                        _Linha(
                          icone: '🍳',
                          label: 'Novas receitas',
                          sub: 'Receitas recomendadas para você',
                          direita: _Toggle(
                            valor: _notifReceitas,
                            onChange: (v) {
                              setState(() => _notifReceitas = v);
                              _salvar('notif_receitas', v);
                            },
                          ),
                        ),
                        _Linha(
                          icone: '👥',
                          label: 'Comunidade',
                          sub: 'Curtidas, comentários e seguidores',
                          direita: _Toggle(
                            valor: _notifComunidade,
                            onChange: (v) {
                              setState(() => _notifComunidade = v);
                              _salvar('notif_comunidade', v);
                            },
                          ),
                        ),
                        _Linha(
                          icone: '🤖',
                          label: 'Chef IA',
                          sub: 'Sugestões personalizadas',
                          direita: _Toggle(
                            valor: _notifChef,
                            onChange: (v) {
                              setState(() => _notifChef = v);
                              _salvar('notif_chef', v);
                            },
                          ),
                          borda: false,
                        ),
                      ],
                    ),
                    _Secao(
                      titulo: 'Privacidade e segurança',
                      filhos: [
                        _Linha(
                          icone: '🔒',
                          label: 'Alterar senha',
                          direita: Icon(Icons.chevron_right, color: context.mutedColor, size: 20),
                          onTap: _alterarSenha,
                        ),
                        _Linha(
                          icone: '👁️',
                          label: 'Quem pode ver meu perfil',
                          sub: 'Todos',
                          direita: Icon(Icons.chevron_right, color: context.mutedColor, size: 20),
                          onTap: () {},
                        ),
                        _Linha(
                          icone: '🚫',
                          label: 'Usuários bloqueados',
                          sub: '0 bloqueados',
                          direita: Icon(Icons.chevron_right, color: context.mutedColor, size: 20),
                          onTap: () {},
                          borda: false,
                        ),
                      ],
                    ),
                    _Secao(
                      titulo: 'Dados',
                      filhos: [
                        _Linha(
                          icone: '📦',
                          label: 'Exportar meus dados',
                          sub: 'Baixar receitas e histórico',
                          direita: Icon(Icons.chevron_right, color: context.mutedColor, size: 20),
                          onTap: () {},
                        ),
                        _Linha(
                          icone: '🗑️',
                          label: 'Limpar cache',
                          sub: 'Liberar espaço no dispositivo',
                          direita: Icon(Icons.chevron_right, color: context.mutedColor, size: 20),
                          onTap: () {},
                          borda: false,
                        ),
                      ],
                    ),
                    _Secao(
                      titulo: 'Sobre',
                      filhos: [
                        _Linha(icone: 'ℹ️', label: 'Versão do app', sub: 'Receita Viva 1.0.0'),
                        _Linha(
                          icone: '📄',
                          label: 'Termos de uso',
                          direita: Icon(Icons.chevron_right, color: context.mutedColor, size: 20),
                          onTap: () {},
                        ),
                        _Linha(
                          icone: '🔐',
                          label: 'Política de privacidade',
                          direita: Icon(Icons.chevron_right, color: context.mutedColor, size: 20),
                          onTap: () {},
                          borda: false,
                        ),
                      ],
                    ),
                    _Secao(
                      titulo: 'Conta',
                      filhos: [
                        _Linha(
                          icone: '⚠️',
                          label: 'Excluir conta',
                          perigo: true,
                          borda: false,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool valor;
  final ValueChanged<bool> onChange;

  const _Toggle({required this.valor, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChange(!valor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: valor ? AppColors.primary : context.borderColor,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: valor ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  final String titulo;
  final List<Widget> filhos;

  const _Secao({required this.titulo, required this.filhos});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            titulo.toUpperCase(),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: context.mutedColor,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(children: filhos),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SenhaField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool mostrar;
  final VoidCallback onToggle;

  const _SenhaField({
    required this.label,
    required this.controller,
    required this.mostrar,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: context.mutedColor,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: !mostrar,
          style: GoogleFonts.poppins(fontSize: 13, color: context.textColor),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            suffixIcon: GestureDetector(
              onTap: onToggle,
              child: Icon(
                mostrar ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
                color: context.mutedColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Linha extends StatelessWidget {
  final String icone;
  final String label;
  final String? sub;
  final Widget? direita;
  final bool perigo;
  final bool borda;
  final VoidCallback? onTap;

  const _Linha({
    required this.icone,
    required this.label,
    this.sub,
    this.direita,
    this.perigo = false,
    this.borda = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: borda
              ? Border(
                  bottom: BorderSide(color: context.borderColor),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: perigo
                    ? const Color(0x22EF4444)
                    : context.chipColor,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(icone, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: perigo
                          ? const Color(0xFFEF4444)
                          : context.textColor,
                    ),
                  ),
                  if (sub != null)
                    Text(
                      sub!,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: context.mutedColor,
                      ),
                    ),
                ],
              ),
            ),
            if (direita != null) direita!,
          ],
        ),
      ),
    );
  }
}
