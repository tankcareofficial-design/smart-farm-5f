import 'package:flutter/material.dart';

import '../controllers/smart_farm_controller.dart';
import '../core/app_info.dart';
import '../core/localization/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/controller_candidate.dart';
import '../pages/esp32_controller_page.dart';
import '../stores/settings_store.dart';
import '../widgets/settings_tile.dart';
import 'pair_controller_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.store,
    required this.controller,
  });

  final SettingsStore store;
  final SmartFarmController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingsStore get _store => widget.store;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.text('ตั้งค่า', 'Settings'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                context.l10n.text(
                  'จัดการสวน Controller เครือข่าย และแอป',
                  'Manage farm, controller, network and app',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        body: AnimatedBuilder(
          animation: _store,
          builder: (context, _) {
            final AppSettings settings = _store.settings;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
              children: [
                _SettingsHeader(settings: settings),
                const SizedBox(height: 20),
                _SettingsSectionTitle(
                  title: context.l10n.text(
                    'สวนและ Controller',
                    'Farm and Controller',
                  ),
                  subtitle: context.l10n.text(
                    'ข้อมูลหลักของระบบควบคุมสวน',
                    'Core farm control information',
                  ),
                ),
                const SizedBox(height: 10),
                SettingsTile(
                  icon: Icons.park_rounded,
                  title: context.l10n.text('ข้อมูลสวน', 'Farm information'),
                  subtitle: settings.farmName,
                  onTap: () => _editFarmName(settings.farmName),
                ),
                const SizedBox(height: 10),
                SettingsTile(
                  icon: Icons.badge_outlined,
                  title: context.l10n.text(
                    'ชื่อกล่องควบคุม',
                    'Controller name',
                  ),
                  subtitle: settings.controllerName,
                  onTap: () => _editControllerName(settings.controllerName),
                ),
                const SizedBox(height: 10),
                SettingsTile(
                  icon: Icons.developer_board_rounded,
                  title: context.l10n.text('Controller', 'Controller'),
                  subtitle: settings.controllerConfigured
                      ? '${settings.controllerName} • ${settings.wifiName ?? context.l10n.text('ยังไม่ทราบเครือข่าย', 'Network unknown')}'
                      : context.l10n.text(
                          'กดเพื่อเพิ่ม Controller',
                          'Tap to add a controller',
                        ),
                  iconColor: settings.controllerOnline
                      ? Theme.of(context).colorScheme.primary
                      : settings.controllerConfigured
                      ? Theme.of(context).colorScheme.tertiary
                      : Theme.of(context).colorScheme.secondary,
                  onTap: () => _openController(settings),
                ),
                const SizedBox(height: 18),
                _SettingsSectionTitle(
                  title: context.l10n.text('บริการ', 'Services'),
                  subtitle: context.l10n.text(
                    'บริการในอนาคต',
                    'Future services',
                  ),
                ),
                const SizedBox(height: 10),
                SettingsTile(
                  icon: Icons.cloud_outlined,
                  title: context.l10n.text(
                    'การเข้าถึงระยะไกลและบัญชี',
                    'Remote access and account',
                  ),
                  subtitle: settings.cloudSignedIn
                      ? context.l10n.text(
                          'เชื่อมต่อบัญชีแล้ว',
                          'Account connected',
                        )
                      : context.l10n.text('ใช้งานแบบออฟไลน์', 'Offline mode'),
                  onTap: () => _showComingSoon(
                    title: context.l10n.text(
                      'แผนการเข้าถึงระยะไกล',
                      'Remote-access roadmap',
                    ),
                    message: context.l10n.text(
                      'ระบบปัจจุบันทำงานผ่านเครือข่ายภายในและยังทำงานอัตโนมัติได้เมื่อแอปออฟไลน์ การเข้าถึงผ่านอินเทอร์เน็ต บัญชีผู้ใช้ และการยืนยันตัวตนที่ปลอดภัยจะเพิ่มในเวอร์ชันอนาคต',
                      'The current system uses the local network and continues automation while the app is offline. Internet access, user accounts, and secure authentication are planned for a future release',
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _SettingsSectionTitle(
                  title: context.l10n.text('ระบบ', 'System'),
                  subtitle: context.l10n.text(
                    'เวลา การแจ้งเตือน ภาษา และรูปแบบแอป',
                    'Time, notifications, language and appearance',
                  ),
                ),
                const SizedBox(height: 10),
                SettingsTile(
                  icon: Icons.schedule_rounded,
                  title: context.l10n.text('วันที่และเวลา', 'Date and time'),
                  subtitle: settings.useAutomaticTime
                      ? context.l10n.text(
                          'อัตโนมัติจากอุปกรณ์',
                          'Automatic from device',
                        )
                      : context.l10n.text('กำหนดด้วยตนเอง', 'Set manually'),
                  trailing: Switch(
                    value: settings.useAutomaticTime,
                    onChanged: (value) {
                      _store.setAutomaticTime(value);
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SettingsTile(
                  icon: Icons.notifications_active_rounded,
                  title: context.l10n.text('การแจ้งเตือน', 'Notifications'),
                  subtitle: settings.notificationsEnabled
                      ? context.l10n.text('เปิดใช้งาน', 'Enabled')
                      : context.l10n.text('ปิดใช้งาน', 'Disabled'),
                  trailing: Switch(
                    value: settings.notificationsEnabled,
                    onChanged: (value) {
                      _store.setNotificationsEnabled(value);
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SettingsTile(
                  icon: Icons.palette_outlined,
                  title: context.l10n.text('ธีม', 'Theme'),
                  subtitle: _themeLabel(context, settings.themeMode),
                  onTap: () => _selectTheme(settings.themeMode),
                ),
                const SizedBox(height: 10),
                SettingsTile(
                  icon: Icons.language_rounded,
                  title: context.l10n.text('ภาษา', 'Language'),
                  subtitle: settings.languageCode == 'th'
                      ? 'ภาษาไทย'
                      : 'English',
                  onTap: () => _selectLanguage(settings.languageCode),
                ),
                const SizedBox(height: 18),
                _SettingsSectionTitle(
                  title: context.l10n.text('เกี่ยวกับ', 'About'),
                  subtitle: context.l10n.text(
                    'ข้อมูลแอปและเครดิตโครงการ',
                    'App information and project credits',
                  ),
                ),
                const SizedBox(height: 10),
                SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: context.l10n.text(
                    'เกี่ยวกับ Smart Farm+',
                    'About Smart Farm+',
                  ),
                  subtitle: AppInfo.fullVersion,
                  onTap: _showAbout,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openController(AppSettings settings) async {
    widget.controller.setBaseUrl(settings.controllerBaseUrl);

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (pageContext) => Esp32ControllerPage(
          controller: widget.controller,
          autoConnectOnOpen:
              settings.controllerConfigured && settings.controllerAutoReconnect,
          onBaseUrlChanged: _store.setControllerBaseUrl,
          onConnectionChanged: _store.setControllerOnline,
          onAutoReconnectChanged: _store.setControllerAutoReconnect,
          onConfigureController: () => _configureController(settings),
        ),
      ),
    );

    if (!mounted || !widget.controller.connected) return;

    await _store.saveRealController(
      controllerId: widget.controller.deviceId ?? 'controller',
      controllerName: 'กล่องควบคุมฟาร์ม',
      wifiName: widget.controller.accessPointSsid ?? 'เครือข่ายกล่องควบคุม',
    );
  }

  Future<void> _configureController(AppSettings settings) async {
    final PairingResult? result = await Navigator.of(context)
        .push<PairingResult>(
          MaterialPageRoute<PairingResult>(
            builder: (pageContext) =>
                PairControllerScreen(languageCode: settings.languageCode),
          ),
        );

    if (!mounted || result == null) {
      return;
    }

    await _store.saveRealController(
      controllerId: result.controllerId,
      controllerName: result.controllerName,
      wifiName: result.wifiName,
      controllerBaseUrl: result.stationBaseUrl,
    );

    widget.controller.disconnect();
    widget.controller.setBaseUrl(result.stationBaseUrl);
    await _store.setControllerBaseUrl(result.stationBaseUrl);
  }

  Future<void> _editControllerName(String currentName) async {
    final String? result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _FarmNameDialog(
          initialName: currentName,
          title: context.l10n.text('ตั้งชื่อกล่องควบคุม', 'Name controller'),
          hintText: context.l10n.text(
            'เช่น กล่องโรงเรือน 1',
            'For example: Greenhouse controller 1',
          ),
        );
      },
    );

    if (!mounted || result == null) return;
    await _store.updateControllerName(result);
  }

  Future<void> _editFarmName(String currentName) async {
    final String? result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _FarmNameDialog(initialName: currentName);
      },
    );

    if (!mounted || result == null) {
      return;
    }

    await _store.updateFarmName(result);
  }

  Future<void> _selectTheme(AppThemeMode currentMode) async {
    final AppThemeMode? result = await showModalBottomSheet<AppThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: RadioGroup<AppThemeMode>(
            groupValue: currentMode,
            onChanged: (value) {
              if (value != null) {
                Navigator.of(sheetContext).pop(value);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.settings_suggest_outlined),
                  title: Text(sheetContext.l10n.text('ตามระบบ', 'System')),
                  trailing: const Radio<AppThemeMode>(
                    value: AppThemeMode.system,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.light_mode_outlined),
                  title: Text(
                    sheetContext.l10n.text('โหมดสว่าง', 'Light mode'),
                  ),
                  trailing: const Radio<AppThemeMode>(
                    value: AppThemeMode.light,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: Text(sheetContext.l10n.text('โหมดมืด', 'Dark mode')),
                  trailing: const Radio<AppThemeMode>(value: AppThemeMode.dark),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) {
      await _store.setThemeMode(result);
    }
  }

  Future<void> _selectLanguage(String currentLanguage) async {
    final String? result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: RadioGroup<String>(
            groupValue: currentLanguage,
            onChanged: (value) {
              if (value != null) {
                Navigator.of(sheetContext).pop(value);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                ListTile(
                  leading: Icon(Icons.translate_rounded),
                  title: Text('ภาษาไทย'),
                  trailing: Radio<String>(value: 'th'),
                ),
                ListTile(
                  leading: Icon(Icons.language_rounded),
                  title: Text('English'),
                  trailing: Radio<String>(value: 'en'),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) {
      await _store.setLanguage(result);
    }
  }

  Future<void> _showComingSoon({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.construction_rounded, size: 38),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(message, textAlign: TextAlign.center),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.text('รับทราบ', 'OK')),
            ),
          ],
        );
      },
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Smart Farm+',
      applicationVersion: '${AppInfo.version} • ${AppInfo.edition}',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          'assets/icon/app_icon.png',
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.eco_rounded, size: 52);
          },
        ),
      ),
      children: [
        Text(
          context.l10n.text(
            'ระบบควบคุมสวนอัจฉริยะ',
            'Smart farming control system',
          ),
        ),
        SizedBox(height: 12),
        Text('Developed by RTPM'),
        Text('ElecBI-CEC'),
        Text('AI-assisted by ChatGPT'),
      ],
    );
  }

  static String _themeLabel(BuildContext context, AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return context.l10n.text('ตามการตั้งค่าของอุปกรณ์', 'Follow system');
      case AppThemeMode.light:
        return context.l10n.text('โหมดสว่าง', 'Light mode');
      case AppThemeMode.dark:
        return context.l10n.text('โหมดมืด', 'Dark mode');
    }
  }
}

class _FarmNameDialog extends StatefulWidget {
  const _FarmNameDialog({required this.initialName, this.title, this.hintText});

  final String initialName;
  final String? title;
  final String? hintText;

  @override
  State<_FarmNameDialog> createState() => _FarmNameDialogState();
}

class _FarmNameDialogState extends State<_FarmNameDialog> {
  late final TextEditingController _controller;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final bool valid = _formKey.currentState?.validate() ?? false;

    if (!valid) {
      return;
    }

    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.title ?? context.l10n.text('ชื่อสวน', 'Farm name'),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: 40,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: context.l10n.text('ชื่อสวน', 'Farm name'),
            hintText:
                widget.hintText ??
                context.l10n.text(
                  'เช่น สวนทุเรียน RTPM',
                  'For example, RTPM Durian Farm',
                ),
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            final String name = value?.trim() ?? '';

            if (name.isEmpty) {
              return context.l10n.text(
                'กรุณากรอกชื่อสวน',
                'Please enter a farm name',
              );
            }

            return null;
          },
          onFieldSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.text('ยกเลิก', 'Cancel')),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(context.l10n.text('บันทึก', 'Save')),
        ),
      ],
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF163D24), Color(0xFF23723B), Color(0xFF3C9854)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/icon/app_icon.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.eco_rounded,
                    color: Color(0xFF2E7D32),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smart Farm+',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  settings.farmName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 7),
                Text(
                  context.l10n.text(
                    'ระบบพร้อมสำหรับการตั้งค่า Controller',
                    'Ready to configure the controller',
                  ),
                  style: const TextStyle(
                    color: Color(0xFF9BE7A9),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
