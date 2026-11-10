import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/irrigation_zone_plan.dart';
import 'crop_draft_repository.dart';

/// Independent, phone-local draft. Never used to create relay profiles.
class IrrigationZoneRepository {
  static const storageKey = 'irrigation_zone_plan_preview_v1';

  Future<IrrigationPlan> load() async {
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(storageKey);
    if (text != null) {
      try {
        final value = jsonDecode(text);
        if (value is Map) {
          return IrrigationPlan.fromJson(
            Map<String, Object?>.from(value),
          );
        }
      } on FormatException {
        // Do not erase the original if storage is malformed.
      } on TypeError {
        // Keep the legacy app data untouched.
      }
    }
    final selected = await CropDraftRepository().loadSelectedCropId();
    return IrrigationPlan.firstUse(cropId: selected ?? 'water_spinach');
  }

  Future<bool> save(IrrigationPlan draft) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(storageKey, jsonEncode(draft.toJson()));
  }
}
