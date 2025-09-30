import 'package:flutter_test/flutter_test.dart';

import 'package:mgm_app/main.dart';

void main() {
  testWidgets('Exibe tela de cadastro ao iniciar', (tester) async {
    await tester.pumpWidget(const MgmApp());
    await tester.pumpAndSettle();

    expect(find.text('Programa Indique e Ganhe'), findsOneWidget);
    expect(
      find.text('Cadastre-se para participar do Member-Get-Member'),
      findsOneWidget,
    );
  });
}
