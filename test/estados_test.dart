// * Testes dos ecrãs vazios e do esqueleto de loading (ecrãs 04, 05, 25, 26).
// * Confirmam que aparecem as mensagens certas e que nada sai do ecrã
// * (o Flutter dá erro de "overflow" se um Row/Column não couber).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/data/frigorifico.dart';
import 'package:app/screens/homepage.dart';
import 'package:app/screens/inventario.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/widgets/estados.dart';

// ? Põe o widget numa app com o tema verdadeiro, do tamanho de um telemóvel
// ! largura maior só no Início: nos testes cada letra é um quadrado (fonte
// ! Ahem), muito mais larga do que a Montserrat, e o "Tudo bem" + "Ver foto"
// ! do cartão de cima passava 17 px dos 393 (com a fonte real cabe)
Future<void> _abrir(
  WidgetTester tester,
  Widget ecra, {
  double largura = 393,
}) async {
  tester.view.physicalSize = Size(largura, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(theme: appTheme, home: Scaffold(body: ecra)),
  );
}

void main() {
  test('o frigorifico começa sem alimentos', () {
    expect(frigorifico.totalEmCasa, 0);
  });

  testWidgets('esqueleto do Início cabe no ecrã', (tester) async {
    await _abrir(tester, const EsqueletoInicio());
    expect(find.text('A expirar'), findsOneWidget);
    expect(find.text('Cozinha isto hoje'), findsOneWidget);
    expect(find.text('Usei'), findsNWidgets(3));
  });

  testWidgets('Início vazio mostra a mensagem', (tester) async {
    await _abrir(tester, const Homepage(), largura: 430);
    expect(find.text('O frigorífico está vazio!'), findsOneWidget);
    // ? sem alimentos, as secções de baixo não aparecem
    expect(find.text('Cozinha isto hoje'), findsNothing);
  });

  testWidgets('Inventário vazio mostra a mensagem', (tester) async {
    await _abrir(tester, const Inventario());
    expect(find.text('O frigorífico está vazio!'), findsOneWidget);
  });
}
