import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tema/tema_app.dart';
import '../servicos/servico_armazenamento.dart';

const _cats = {
  'hortifruti': {'label': 'Hortifrúti', 'emoji': '🥬'},
  'mercearia': {'label': 'Mercearia', 'emoji': '🍞'},
  'acougue': {'label': 'Açougue', 'emoji': '🥩'},
  'laticinios': {'label': 'Laticínios', 'emoji': '🥛'},
};

class TelaListaCompras extends StatefulWidget {
  const TelaListaCompras({super.key});

  @override
  State<TelaListaCompras> createState() => _TelaListaComprasState();
}

class _TelaListaComprasState extends State<TelaListaCompras> {
  final _storage = StorageService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _showAdd = false;
  String? _editingId;
  final _addCtrl = TextEditingController();
  final _editNameCtrl = TextEditingController();
  final _editQtyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _addCtrl.dispose();
    _editNameCtrl.dispose();
    _editQtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _storage.getListaCompras();
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  Future<void> _save() async => _storage.saveListaCompras(_items);

  void _toggle(String id) {
    setState(() {
      final i = _items.indexWhere((it) => it['id'] == id);
      if (i != -1) _items[i] = {..._items[i], 'checked': !(_items[i]['checked'] as bool)};
    });
    _save();
  }

  void _remove(String id) {
    setState(() => _items.removeWhere((it) => it['id'] == id));
    _save();
  }

  void _clearChecked() {
    setState(() => _items.removeWhere((it) => it['checked'] as bool));
    _save();
  }

  void _addItem() {
    if (_addCtrl.text.trim().isEmpty) return;
    final newItem = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'cat': 'mercearia',
      'name': _addCtrl.text.trim(),
      'qty': '',
      'from': 'Manual',
      'checked': false,
    };
    setState(() { _items.add(newItem); _showAdd = false; });
    _addCtrl.clear();
    _save();
  }

  void _startEdit(Map<String, dynamic> item) {
    _editNameCtrl.text = item['name'] as String;
    _editQtyCtrl.text = item['qty'] as String? ?? '';
    setState(() => _editingId = item['id'] as String);
  }

  void _confirmEdit(String id) {
    setState(() {
      final i = _items.indexWhere((it) => it['id'] == id);
      if (i != -1) {
        _items[i] = {
          ..._items[i],
          'name': _editNameCtrl.text.trim(),
          'qty': _editQtyCtrl.text.trim(),
        };
      }
      _editingId = null;
    });
    _save();
  }

  int get _checkedCount => _items.where((it) => it['checked'] as bool).length;
  double get _progress => _items.isEmpty ? 0 : _checkedCount / _items.length;

  List<Map<String, dynamic>> _itemsForCat(String catId) =>
      _items.where((it) => it['cat'] == catId).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                if (!_loading) _buildProgress(),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : _buildList(),
                ),
              ],
            ),
            if (!_showAdd)
              Positioned(
                bottom: 24,
                right: 20,
                child: _buildFab(),
              ),
            if (_showAdd)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildAddBar(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hasChecked = _checkedCount > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
              child: Text('Lista de compras',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: context.textColor)),
            ),
          ),
          GestureDetector(
            onTap: hasChecked ? _clearChecked : null,
            child: Text('Limpar',
                style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: hasChecked ? AppColors.primary : context.borderColor,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x1AD4623A), blurRadius: 12, offset: Offset(0, 2))],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SEU PROGRESSO',
                        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: context.mutedColor, letterSpacing: 0.8)),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: '$_checkedCount',
                          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: context.textColor, letterSpacing: -0.5),
                        ),
                        TextSpan(
                          text: ' / ${_items.length} itens',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: context.mutedColor),
                        ),
                      ]),
                    ),
                  ],
                ),
                const Spacer(),
                Text('${(_progress * 100).round()}%',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: context.borderColor,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🛒', style: TextStyle(fontSize: 54)),
            const SizedBox(height: 12),
            Text('Lista vazia',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: context.textColor)),
            const SizedBox(height: 4),
            Text('Toque no + para adicionar itens',
                style: GoogleFonts.poppins(fontSize: 12, color: context.mutedColor)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      children: [
        for (final catId in _cats.keys)
          if (_itemsForCat(catId).isNotEmpty)
            _buildCategory(catId),
      ],
    );
  }

  Widget _buildCategory(String catId) {
    final cat = _cats[catId]!;
    final items = _itemsForCat(catId);
    final remaining = items.where((it) => !(it['checked'] as bool)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            Text(cat['emoji']!, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(cat['label']!,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13, color: context.textColor)),
            const Spacer(),
            Text('$remaining restantes',
                style: GoogleFonts.poppins(fontSize: 11, color: context.mutedColor)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Color(0x1AD4623A), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final idx = e.key;
              final item = e.value;
              return Column(
                children: [
                  if (idx > 0) Divider(height: 1, color: context.borderColor),
                  _buildItem(item),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(Map<String, dynamic> item) {
    final id = item['id'] as String;
    final checked = item['checked'] as bool;
    final isEditing = _editingId == id;
    final from = item['from'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: isEditing ? null : () => _toggle(id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: checked ? null : Border.all(color: context.borderColor, width: 2),
                color: checked ? AppColors.primary : Colors.transparent,
              ),
              child: checked
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: isEditing
                ? Column(
                    children: [
                      TextField(
                        controller: _editNameCtrl,
                        style: GoogleFonts.poppins(fontSize: 13, color: context.textColor),
                        decoration: InputDecoration(
                          hintText: 'Nome do item',
                          hintStyle: GoogleFonts.poppins(fontSize: 13, color: context.mutedColor),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _editQtyCtrl,
                        style: GoogleFonts.poppins(fontSize: 11, color: context.textColor),
                        decoration: InputDecoration(
                          hintText: 'Quantidade (ex: 500g)',
                          hintStyle: GoogleFonts.poppins(fontSize: 11, color: context.mutedColor),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: context.borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: context.borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                          isDense: true,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: checked ? context.mutedColor : context.textColor,
                          decoration: checked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if ((item['qty'] as String?)?.isNotEmpty == true || from.isNotEmpty)
                        Text(
                          [
                            if ((item['qty'] as String?)?.isNotEmpty == true) item['qty'] as String,
                            if (from.isNotEmpty && from != 'Manual') 'de $from',
                            if (from == 'Manual') 'adicionado por você',
                          ].join(' · '),
                          style: GoogleFonts.poppins(fontSize: 10, color: context.mutedColor),
                        ),
                    ],
                  ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => isEditing ? _confirmEdit(id) : _startEdit(item),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isEditing ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: isEditing
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Icon(Icons.edit_outlined, size: 14, color: context.mutedColor),
            ),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: () => _remove(id),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.close, size: 14, color: context.mutedColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: () => setState(() => _showAdd = true),
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(102), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildAddBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 14,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(top: BorderSide(color: context.borderColor)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _addCtrl,
              autofocus: true,
              style: GoogleFonts.poppins(fontSize: 13, color: context.textColor),
              decoration: InputDecoration(
                hintText: 'Adicionar item...',
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: context.mutedColor),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                isDense: true,
              ),
              onSubmitted: (_) => _addItem(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () { setState(() => _showAdd = false); _addCtrl.clear(); },
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: context.chipColor, borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.close, color: context.textColor, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _addItem,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: _addCtrl.text.trim().isNotEmpty ? AppColors.primaryGradient : null,
                color: _addCtrl.text.trim().isEmpty ? context.borderColor : null,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text('Adicionar',
                  style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: _addCtrl.text.trim().isNotEmpty ? Colors.white : context.mutedColor,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}
