import 'package:flutter_test/flutter_test.dart';
import 'package:smart_farm/main.dart';
import 'package:smart_farm/stores/settings_store.dart';

void main() {
  testWidgets('Smart Farm+ starts successfully', (tester) async {
    final store = SettingsStore();

    await tester.pumpWidget(SmartFarmApp(settingsStore: store));
    await tester.pump();

    expect(find.text('Smart Farm+'), findsOneWidget);
  });
}
