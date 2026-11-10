import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_farm/data/crop_profile_catalog.dart';
import 'package:smart_farm/models/crop_profile.dart';
import 'package:smart_farm/models/crop_profile_draft.dart';
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
        if (profile.referenceClimate.hasTemperatureRange) {
          expect(profile.sourceReferences,
              contains(profile.referenceClimate.sourceUrl));
          expect(profile.referenceClimate.sourceUrl, startsWith('https://'));
          expect(profile.referenceClimate.temperatureMinC!,
              lessThan(profile.referenceClimate.temperatureMaxC!));
        } else {
          expect(profile.sourceReferences, isEmpty, reason: profile.id);
        }
        expect(profile.canApplyToController, isFalse, reason: profile.id);
      }
    });

    test('customized crop keeps source identity and reset restores plain label', () {
      final source = CropProfileCatalog.byId('water_spinach')!;
      const edited = CropProfileDraft(
        cropId: 'water_spinach',
        temperatureMinC: 22,
        note: 'ทดลองในโรงเรือน',
      );
      const reset = CropProfileDraft(cropId: 'water_spinach');
      expect(edited.isCustomized(source), isTrue);
      expect(edited.displayName(source, isThai: true),
          'ผักบุ้งจีน (มีการปรับแต่ง)');
      expect(edited.displayName(source, isThai: false),
          'Water spinach (Customized)');
      expect(reset.isCustomized(source), isFalse);
      expect(reset.displayName(source, isThai: true), 'ผักบุ้งจีน');
      expect(source.targets.isUnconfigured, isTrue);
      expect(CropProfileCatalog.byId('water_spinach'), same(source));
    });

    test('selected crop prefills verified reference values like an EQ preset', () {
      final lettuce = CropProfileCatalog.byId('lettuce')!;
      final recommended = CropProfileDraft.fromRecommendation(lettuce);
      expect(lettuce.referenceClimate.hasTemperatureRange, isTrue);
      expect(recommended.temperatureMinC, 10);
      expect(recommended.temperatureMaxC, 20);
      expect(recommended.humidityMinPercent, isNull);
      expect(recommended.isCustomized(lettuce), isFalse);

      const edited = CropProfileDraft(
        cropId: 'lettuce',
        temperatureMinC: 13,
        temperatureMaxC: 20,
      );
      expect(edited.isCustomized(lettuce), isTrue);
      expect(edited.displayName(lettuce, isThai: true),
          'ผักสลัด / ผักกาดหอม (มีการปรับแต่ง)');
      expect(CropProfileDraft.fromRecommendation(lettuce)
          .isCustomized(lettuce), isFalse);
      expect(lettuce.targets.isUnconfigured, isTrue);
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

    await tester.scrollUntilVisible(
      find.byKey(const Key('crop-apply-disabled')),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    final apply = tester.widget<FilledButton>(
      find.byKey(const Key('crop-apply-disabled')),
    );
    expect(apply.onPressed, isNull);
    expect(find.textContaining('ยังไม่กำหนด'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
