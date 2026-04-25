import 'package:flutter_test/flutter_test.dart';
import 'package:receita_viva_upx_v/main.dart';

void main() {
  testWidgets('App inicia corretamente', (WidgetTester tester) async {
    await tester.pumpWidget(const ReceitaVivaApp());
    expect(find.text('ReceitaViva'), findsWidgets);
  });
}
