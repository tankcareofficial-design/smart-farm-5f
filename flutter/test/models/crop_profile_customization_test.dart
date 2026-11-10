import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_farm/data/crop_profile_catalog.dart';
import 'package:smart_farm/models/crop_profile_draft.dart';
import 'package:smart_farm/screens/crop_profiles_screen.dart';
import 'package:smart_farm/services/crop_draft_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('unmodified original displays plain crop name in Thai/English', () {
    final crop = CropProfileCatalog.byId('water_spinach')!;
    const draft = CropProfileDraft(cropId: 'water_spinach');
    expect(draft.isCustomized(crop), false);
    expect(draft.displayName(crop, isThai: true), 'ผักบุ้งจีน');
    expect(draft.displayName(crop, isThai: false), 'Water spinach');
  });

  test('changed values show customized label without changing source', () {
    final crop = CropProfileCatalog.byId('water_spinach')!;
    const changed = CropProfileDraft(
      cropId: 'water_spinach',
      temperatureMinC: 24,
      humidityMaxPercent: 75,
    );
    expect(changed.isCustomized(crop), true);
    expect(
      changed.displayName(crop, isThai: true),
      'ผักบุ้งจีน (มีการปรับแต่ง)',
    );
    expect(
      changed.displayName(crop, isThai: false),
      'Water spinach (Customized)',
    );
    expect(crop.targets.isUnconfigured, isTrue);
    expect(crop.canApplyToController, isFalse);
  });

  test('reset removes customization suffix and stays preview-only', () {
    final crop = CropProfileCatalog.byId('water_spinach')!;
    const changed = CropProfileDraft(cropId: 'water_spinach', note: 'ระเบียง');
    const reset = CropProfileDraft(cropId: 'water_spinach');
    expect(changed.isCustomized(crop), true);
    expect(reset.isCustomized(crop), false);
    expect(reset.displayName(crop, isThai: true), 'ผักบุ้งจีน');
  });

  test('drafts persist locally, without modifying original catalog', () async {
    final store = CropDraftRepository();
    const changed = CropProfileDraft(
      cropId: 'water_spinach',
      temperatureMaxC: 29.5,
      note: 'ปลูกในกระถาง',
    );
    expect(await store.save(<String, CropProfileDraft>{
      'water_spinach': changed,
    }), isTrue);
    final fromDisk = (await CropDraftRepository().load())['water_spinach'];
    expect(fromDisk, isNotNull);
    expect(fromDisk!.displayName(
      CropProfileCatalog.byId('water_spinach')!,
      isThai: true,
    ), 'ผักบุ้งจีน (มีการปรับแต่ง)');
    expect(fromDisk.temperatureMaxC, 29.5);
    expect(CropProfileCatalog.byId('water_spinach')!.targets.isUnconfigured,
        isTrue);
  });

  testWidgets('edited profile label updates in details and crop list', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: CropProfilesScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('crop-profile-water_spinach')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('crop-customize-button')),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('crop-customize-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('crop-custom-note')),
      'ปลูกในกระถาง',
    );
    await tester.ensureVisible(find.byKey(const Key('crop-draft-save')));
    await tester.tap(find.byKey(const Key('crop-draft-save')));
    await tester.pumpAndSettle();

    expect(find.textContaining('ผักบุ้งจีน (มีการปรับแต่ง)'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('ผักบุ้งจีน (มีการปรับแต่ง)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
