import 'package:flutter_test/flutter_test.dart';
import 'package:smart_farm/main.dart';
import 'package:smart_farm/stores/settings_store.dart';

void main() {
  testWidgets('Smartfarm+ starts successfully', (tester) async {
    final store = SettingsStore();

    await tester.pumpWidget(SmartFarmApp(settingsStore: store));
    await tester.pump();

    expect(find.text('Smartfarm+'), findsOneWidget);
  });
}
