import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/crop_profile_catalog.dart';
import '../models/crop_profile_draft.dart';

/// Phone-local preview drafts only. No connection to the ESP32, DeviceStore or
/// AutomationEngine; never apply these fields to a real relay.
class CropDraftRepository {
  static const storageKey = 'crop_profile_drafts_v1';
  static const selectedCropKey = 'crop_selected_reference_v1';

  /// Only the chosen in-app reference; never an ESP32 rule or profile.
  Future<String?> loadSelectedCropId() async {
    final prefs = await SharedPreferences.getInstance();
    final cropId = prefs.getString(selectedCropKey);
    return cropId != null && CropProfileCatalog.byId(cropId) != null
        ? cropId
        : null;
  }

  Future<bool> saveSelectedCropId(String cropId) async {
    if (CropProfileCatalog.byId(cropId) == null) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(selectedCropKey, cropId);
  }


  Future<Map<String, CropProfileDraft>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return <String, CropProfileDraft>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, CropProfileDraft>{};
      final result = <String, CropProfileDraft>{};
      for (final entry in decoded.entries) {
        final key = entry.key.toString();
        if (CropProfileCatalog.byId(key) == null || entry.value is! Map) {
          continue;
        }
        try {
          final draft = CropProfileDraft.fromJson(
            Map<String, Object?>.from(entry.value as Map),
          );
          if (draft.cropId == key) result[key] = draft;
        } on FormatException {
          // Preserve other crops when one local draft is corrupt.
        } on TypeError {
          // Treat only the affected draft as unreadable.
        }
      }
      return result;
    } on FormatException {
      return <String, CropProfileDraft>{};
    }
  }

  Future<bool> save(
    Map<String, CropProfileDraft> drafts,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = <String, Object?>{};
    for (final entry in drafts.entries) {
      if (CropProfileCatalog.byId(entry.key) != null &&
          entry.value.cropId == entry.key) {
        serialized[entry.key] = entry.value.toJson();
      }
    }
    return prefs.setString(storageKey, jsonEncode(serialized));
  }
}
