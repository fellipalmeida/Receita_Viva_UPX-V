import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../tema/tema_app.dart';
import '../modelos/perfil_usuario.dart';
import '../servicos/servico_armazenamento.dart';
import 'tela_foto_picker.dart';

class TelaEditarPerfil extends StatefulWidget {
  const TelaEditarPerfil({super.key});

  @override
  State<TelaEditarPerfil> createState() => _TelaEditarPerfilState();
}

class _TelaEditarPerfilState extends State<TelaEditarPerfil> {
  final _storage = StorageService();
  final _nomeCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  int? _avatarIndex;
  bool _salvando = false;
  UserProfile? _perfilOriginal;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final perfil = await _storage.getProfile();
    if (perfil != null && mounted) {
      _perfilOriginal = perfil;
      setState(() {
        _nomeCtrl.text = perfil.name;
        _usernameCtrl.text =
            perfil.email.isNotEmpty ? perfil.email.split('@').first : '';
        _avatarIndex = perfil.avatarIndex;
      });
    }
  }

  Future<void> _abrirFotoPicker() async {
    final index = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => const TelaFotoPicker()),
    );
    if (index != null && mounted) {
      setState(() => _avatarIndex = index);
    }
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    setState(() => _salvando = true);
    final atualizado = UserProfile(
      name: _nomeCtrl.text.trim().isEmpty
          ? (_perfilOriginal?.name ?? 'Chef')
          : _nomeCtrl.text.trim(),
      email: _perfilOriginal?.email ?? '',
      bio: _perfilOriginal?.bio ?? '',
      alergias: _perfilOriginal?.alergias ?? [],
      dietas: _perfilOriginal?.dietas ?? [],
      cozinhas: _perfilOriginal?.cozinhas ?? [],
      avatarIndex: _avatarIndex,
    );
    await _storage.saveProfile(atualizado);
    if (mounted) {
      setState(() => _salvando = false);
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _alterarSenha() async {
    final senhaAtualCtrl = TextEditingController();
    final novaSenhaCtrl = TextEditingController();
    final confirmarCtrl = TextEditingController();

    bool verAtual = false;
    bool verNova = false;
    bool verConfirmar = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
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
                      width: 36, height: 4,
                      decoration: BoxDecoration(color: context.borderColor, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Alterar senha',
                      style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: context.textColor)),
                  const SizedBox(height: 20),
                  _SenhaField(label: 'Senha atual', controller: senhaAtualCtrl, mostrar: verAtual,
                      onToggle: () => setSheet(() => verAtual = !verAtual)),
                  const SizedBox(height: 14),
                  _SenhaField(label: 'Nova senha', controller: novaSenhaCtrl, mostrar: verNova,
                      onToggle: () => setSheet(() => verNova = !verNova)),
                  const SizedBox(height: 14),
                  _SenhaField(label: 'Confirmar nova senha', controller: confirmarCtrl, mostrar: verConfirmar,
                      onToggle: () => setSheet(() => verConfirmar = !verConfirmar)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        // erros mostrados dentro do sheet (ctx ainda está ativo)
                        void snackErro(String msg) {
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ));
                        }

                        if (senhaAtualCtrl.text.isEmpty) {
                          snackErro('Informe a senha atual');
                          return;
                        }
                        if (novaSenhaCtrl.text.length < 6) {
                          snackErro('Nova senha deve ter pelo menos 6 caracteres');
                          return;
                        }
                        if (novaSenhaCtrl.text != confirmarCtrl.text) {
                          snackErro('Senhas não coincidem');
                          return;
                        }
                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) { snackErro('Usuário não autenticado'); return; }
                          final cred = EmailAuthProvider.credential(
                            email: user.email!, password: senhaAtualCtrl.text);
                          await user.reauthenticateWithCredential(cred);
                          await user.updatePassword(novaSenhaCtrl.text);
                          // fecha o sheet antes de mostrar o snackbar de sucesso
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Senha alterada com sucesso!',
                                  style: GoogleFonts.poppins(fontSize: 13)),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ));
                          }
                        } on FirebaseAuthException catch (e) {
                          final msg = switch (e.code) {
                            'wrong-password' || 'invalid-credential' => 'Senha atual incorreta',
                            'too-many-requests' => 'Muitas tentativas. Aguarde alguns minutos e tente novamente.',
                            'network-request-failed' => 'Sem conexão. Verifique sua internet.',
                            _ => 'Erro: ${e.code}',
                          };
                          snackErro(msg);
                        } catch (_) {
                          snackErro('Erro inesperado. Tente novamente.');
                        }
                      },
                      child: Text('Salvar',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
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

  String get _iniciais {
    final nome = _nomeCtrl.text.trim();
    final partes = nome.split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nome.isNotEmpty ? nome[0].toUpperCase() : 'C';
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
                        'Editar Perfil',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: context.textColor,
                        ),
                      ),
                    ),
                  ),
                  _salvando
                      ? const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : GestureDetector(
                          onTap: _salvar,
                          child: Text(
                            'Salvar',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: _abrirFotoPicker,
                                child: Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    gradient: _avatarIndex != null
                                        ? LinearGradient(
                                            colors: [
                                              TelaFotoPicker.fotos[_avatarIndex!][0] as Color,
                                              TelaFotoPicker.fotos[_avatarIndex!][1] as Color,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : AppColors.primaryGradient,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: _avatarIndex != null
                                      ? Text(
                                          TelaFotoPicker.fotos[_avatarIndex!][2] as String,
                                          style: const TextStyle(fontSize: 40),
                                        )
                                      : AnimatedBuilder(
                                          animation: _nomeCtrl,
                                          builder: (_, __) => Text(
                                            _iniciais,
                                            style: GoogleFonts.poppins(
                                              fontSize: 36,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _abrirFotoPicker,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: context.appBg,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _abrirFotoPicker,
                            child: Text(
                              'Alterar foto',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _Campo(label: 'Nome', controller: _nomeCtrl),
                    const SizedBox(height: 16),
                    _Campo(label: 'Nome de usuário', controller: _usernameCtrl),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _alterarSenha,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.borderColor),
                          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(color: context.chipColor, borderRadius: BorderRadius.circular(10)),
                              alignment: Alignment.center,
                              child: const Text('🔒', style: TextStyle(fontSize: 18)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text('Alterar senha',
                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: context.textColor)),
                            ),
                            Icon(Icons.chevron_right, color: context.mutedColor, size: 20),
                          ],
                        ),
                      ),
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

class _SenhaField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool mostrar;
  final VoidCallback onToggle;

  const _SenhaField({required this.label, required this.controller, required this.mostrar, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600,
                color: context.mutedColor, letterSpacing: 0.8)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: !mostrar,
          style: GoogleFonts.poppins(fontSize: 13, color: context.textColor),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            suffixIcon: GestureDetector(
              onTap: onToggle,
              child: Icon(mostrar ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18, color: context.mutedColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _Campo extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _Campo({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: context.mutedColor, letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: GoogleFonts.poppins(fontSize: 13, color: context.textColor),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 14),
          ),
        ),
      ],
    );
  }
}
