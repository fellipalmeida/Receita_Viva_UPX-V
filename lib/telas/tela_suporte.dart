import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tema/tema_app.dart';

class TelaSuporte extends StatefulWidget {
  const TelaSuporte({super.key});

  @override
  State<TelaSuporte> createState() => _TelaSuporteState();
}

class _TelaSuporteState extends State<TelaSuporte> {
  int? _expandido;
  final _msgCtrl = TextEditingController();
  bool _enviado = false;

  static const _faqs = [
    {
      'q': 'Como o Chef IA cria receitas?',
      'a':
          'O Chef IA usa inteligência artificial para combinar ingredientes disponíveis com suas preferências alimentares, alergias e histórico de receitas para criar sugestões personalizadas.',
    },
    {
      'q': 'Posso usar o app sem internet?',
      'a':
          'Algumas receitas salvas ficam disponíveis offline. O Chat com o Chef IA e a Comunidade precisam de conexão com a internet.',
    },
    {
      'q': 'Como altero minhas alergias?',
      'a':
          'Acesse Perfil → Editar Perfil → seção Alergias alimentares. As mudanças são aplicadas imediatamente às sugestões do Chef IA.',
    },
    {
      'q': 'Como excluo minha conta?',
      'a':
          'Vá em Configurações → Conta → Excluir conta. Atenção: essa ação é irreversível e apaga todos os seus dados.',
    },
    {
      'q': 'O app é gratuito?',
      'a':
          'Sim! O Receita Viva é totalmente gratuito. No futuro, pode haver um plano premium com funcionalidades extras.',
    },
  ];

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
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
                      decoration: const BoxDecoration(
                        color: AppColors.chipBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 16,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Suporte',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.text,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '🤝',
                            style: TextStyle(fontSize: 48),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Como podemos ajudar?',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Estamos aqui para tornar sua experiência incrível',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xD9FFFFFF),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Contato rápido',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _BotaoContato(
                            icone: '💬',
                            label: 'Chat',
                            sub: 'Resposta em 5 min',
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: Text(
                                  '💬 Chat ao vivo',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                                ),
                                content: Text(
                                  'Nosso chat está disponível de segunda a sexta, das 9h às 18h.\n\nWhatsApp: (11) 99999-0000\n\nResponderemos em até 5 minutos durante o horário comercial.',
                                  style: GoogleFonts.poppins(fontSize: 13, height: 1.6),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Fechar', style: GoogleFonts.poppins(color: AppColors.primary)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _BotaoContato(
                            icone: '📧',
                            label: 'E-mail',
                            sub: 'até 24h',
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: Text(
                                  '📧 Enviar e-mail',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                                ),
                                content: Text(
                                  'Envie sua dúvida para:\n\nsuporte@receitaviva.com.br\n\nOu use o formulário abaixo para nos escrever diretamente. Respondemos em até 24 horas úteis.',
                                  style: GoogleFonts.poppins(fontSize: 13, height: 1.6),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Fechar', style: GoogleFonts.poppins(color: AppColors.primary)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Perguntas frequentes',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: List.generate(_faqs.length, (i) {
                        final aberto = _expandido == i;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0D000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () => setState(
                                  () => _expandido = aberto ? null : i,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    14,
                                    16,
                                    14,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _faqs[i]['q']!,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.text,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      AnimatedRotation(
                                        turns: aberto ? 0.5 : 0,
                                        duration:
                                            const Duration(milliseconds: 200),
                                        child: const Icon(
                                          Icons.keyboard_arrow_down,
                                          color: AppColors.textMuted,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              AnimatedCrossFade(
                                duration: const Duration(milliseconds: 200),
                                crossFadeState: aberto
                                    ? CrossFadeState.showFirst
                                    : CrossFadeState.showSecond,
                                firstChild: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    14,
                                  ),
                                  child: Text(
                                    _faqs[i]['a']!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: AppColors.textMuted,
                                      height: 1.7,
                                    ),
                                  ),
                                ),
                                secondChild: const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Enviar mensagem',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _enviado
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0D000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  '✅',
                                  style: TextStyle(fontSize: 44),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Mensagem enviada!',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: AppColors.text,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Nossa equipe responderá em até 24h',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              TextField(
                                controller: _msgCtrl,
                                maxLines: 4,
                                onChanged: (_) => setState(() {}),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.text,
                                ),
                                decoration: const InputDecoration(
                                  hintText:
                                      'Descreva sua dúvida ou problema...',
                                ),
                              ),
                              const SizedBox(height: 12),
                              AnimatedBuilder(
                                animation: _msgCtrl,
                                builder: (_, __) {
                                  final ativo =
                                      _msgCtrl.text.trim().isNotEmpty;
                                  return Container(
                                    width: double.infinity,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: ativo
                                          ? AppColors.primaryGradient
                                          : null,
                                      color:
                                          ativo ? null : AppColors.border,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      boxShadow: ativo
                                          ? const [
                                              BoxShadow(
                                                color: Color(0x44D4623A),
                                                blurRadius: 20,
                                                offset: Offset(0, 6),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        onTap: ativo
                                            ? () => setState(
                                                  () => _enviado = true,
                                                )
                                            : null,
                                        child: Center(
                                          child: Text(
                                            'Enviar mensagem',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: ativo
                                                  ? Colors.white
                                                  : AppColors.textMuted,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
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

class _BotaoContato extends StatelessWidget {
  final String icone;
  final String label;
  final String sub;
  final VoidCallback onTap;

  const _BotaoContato({
    required this.icone,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(icone, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.text,
              ),
            ),
            Text(
              sub,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
