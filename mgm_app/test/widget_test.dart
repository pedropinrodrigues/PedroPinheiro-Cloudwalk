import 'package:flutter_test/flutter_test.dart';

import 'package:mgm_app/main.dart';

void main() {
  testWidgets('Exibe tela de cadastro ao iniciar', (tester) async {
    await tester.pumpWidget(const MgmApp());
    await tester.pumpAndSettle();

    expect(find.text('Crie sua conta'), findsOneWidget);
    expect(
      find.text('Ganhe pontos com seu código de indicação.'),
      findsOneWidget,
    );
  });
}
