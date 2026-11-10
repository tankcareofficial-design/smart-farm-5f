import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_farm/data/crop_profile_catalog.dart';
import 'package:smart_farm/models/crop_profile.dart';
import 'package:smart_farm/screens/crop_profiles_screen.dart';

void main() {
  group('Crop Profile v1 preview safety', () {
    test('11 named vegetables plus Custom are available offline', () {
      expect(CropProfileCatalog.profiles, hasLength(12));
      expect(CropProfileCatalog.profiles.map((p) => p.id).toSet(), hasLength(12));
      expect(CropProfileCatalog.byId('water_spinach')?.nameTh, 'ผักบุ้งจีน');
      expect(CropProfileCatalog.byId('custom')?.group, CropGroup.custom);
      expect(CropProfileCatalog.byId('missing'), isNull);
    });

    test('all presets have no fabricated thresholds or controller apply', () {
      for (final profile in CropProfileCatalog.profiles) {
        expect(profile.schemaVersion, 1);
        expect(profile.targets.isUnconfigured, isTrue, reason: profile.id);
        expect(profile.sourceReferences, isEmpty, reason: profile.id);
        expect(profile.canApplyToController, isFalse, reason: profile.id);
      }
    });

    test('search matches Thai and English without touching controller', () {
      expect(CropProfileCatalog.search('มะเขือเทศ').single.id, 'tomato');
      expect(CropProfileCatalog.search('BASIL'), hasLength(2));
      expect(CropProfileCatalog.search('   '), hasLength(12));
      expect(CropProfileCatalog.search('impossible crop'), isEmpty);
    });
  });

  testWidgets('crop browser can open a preset but cannot apply it', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: CropProfilesScreen()),
    );
    expect(find.byKey(const Key('crop-profile-search')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('crop-profile-search')),
      'มะเขือเทศ',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('crop-profile-tomato')), findsOneWidget);
    expect(find.byKey(const Key('crop-profile-lettuce')), findsNothing);

    await tester.tap(find.byKey(const Key('crop-profile-tomato')));
    await tester.pumpAndSettle();

    final apply = tester.widget<FilledButton>(
      find.byKey(const Key('crop-apply-disabled')),
    );
    expect(apply.onPressed, isNull);
    expect(find.textContaining('ยังไม่กำหนด'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
