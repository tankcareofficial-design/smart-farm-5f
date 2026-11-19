import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_farm/models/farm_state.dart';
import 'package:smart_farm/widgets/dashboard/dashboard_data_widgets.dart';
import 'package:smart_farm/widgets/dashboard/dashboard_overview_widgets.dart';

void main() {
  Widget host(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(width: 360, child: child),
        ),
      ),
    );
  }

  testWidgets('energy card never invents battery or solar values', (tester) async {
    await tester.pumpWidget(
      host(const DashboardEnergyCard(state: FarmState.empty)),
    );

    expect(find.text('แบตเตอรี่'), findsOneWidget);
    expect(find.text('โซลาร์เซลล์'), findsOneWidget);
    expect(find.text('ไม่มีข้อมูล'), findsNWidgets(2));
    expect(find.text('91%'), findsNothing);
    expect(find.text('13.7 V'), findsNothing);
  });

  testWidgets('dashboard hero renders disconnected empty state safely',
      (tester) async {
    await tester.pumpWidget(
      host(const DashboardHeroCard(state: FarmState.empty)),
    );

    expect(find.text('ระบบควบคุมฟาร์ม'), findsOneWidget);
    expect(find.text('ออฟไลน์'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
