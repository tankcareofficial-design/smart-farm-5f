import 'package:flutter/material.dart';

import '../controllers/smart_farm_controller.dart';
import '../core/app_info.dart';
import '../core/localization/app_localizations.dart';

class Esp32ControllerPage extends StatefulWidget {
  const Esp32ControllerPage({
    required this.controller,
    required this.autoConnectOnOpen,
    required this.onBaseUrlChanged,
    required this.onConnectionChanged,
    required this.onAutoReconnectChanged,
    this.onConfigureController,
    super.key,
  });

  final SmartFarmController controller;
  final bool autoConnectOnOpen;
  final ValueChanged<String> onBaseUrlChanged;
  final ValueChanged<bool> onConnectionChanged;
  final ValueChanged<bool> onAutoReconnectChanged;
  final Future<void> Function()? onConfigureController;

  @override
  State<Esp32ControllerPage> createState() => _Esp32ControllerPageState();
}

class _Esp32ControllerPageState extends State<Esp32ControllerPage> {
  late bool _autoConnectOnOpen;

  SmartFarmController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _autoConnectOnOpen = widget.autoConnectOnOpen;
    if (_autoConnectOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || controller.connected || controller.requestInProgress) {
          return;
        }
        await controller.connect();
        if (!mounted) return;
        widget.onConnectionChanged(controller.connected);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final bool connected = controller.connected;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(context.l10n.text('Controller', 'Controller')),
                Text(
                  '${AppInfo.version} • ${AppInfo.edition}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          body: RefreshIndicator(
            onRefresh: connected ? controller.refreshNow : () async {},
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: <Widget>[
                _ConnectionHero(controller: controller),
                const SizedBox(height: 12),
                if (!connected)
                  _StandaloneSetupCard(
                    busy: controller.requestInProgress,
                    autoConnect: _autoConnectOnOpen,
                    onConfigure: widget.onConfigureController,
                    onAutoConnectChanged: (bool value) {
                      setState(() => _autoConnectOnOpen = value);
                      widget.onAutoReconnectChanged(value);
                    },
                    onConnect: () async {
                      await controller.connect();
                      if (!mounted) return;
                      widget.onConnectionChanged(controller.connected);
                    },
                  )
                else ...<Widget>[
                  _DeviceInfoCard(controller: controller),
                  const SizedBox(height: 12),
                  _NetworkSetupEntry(onTap: widget.onConfigureController),
                  const SizedBox(height: 12),
                  _AdvancedEntry(
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => _ControllerAdvancedPage(
                          controller: controller,
                          initialAutoReconnect: _autoConnectOnOpen,
                          onBaseUrlChanged: widget.onBaseUrlChanged,
                          onAutoReconnectChanged: (bool value) {
                            setState(() => _autoConnectOnOpen = value);
                            widget.onAutoReconnectChanged(value);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: controller.requestInProgress
                        ? null
                        : () {
                            controller.disconnect();
                            widget.onConnectionChanged(false);
                          },
                    icon: const Icon(Icons.link_off_rounded),
                    label: Text(
                      context.l10n.text('ตัดการเชื่อมต่อ', 'Disconnect'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ConnectionHero extends StatelessWidget {
  const _ConnectionHero({required this.controller});
  final SmartFarmController controller;

  @override
  Widget build(BuildContext context) {
    final bool connected = controller.connected;
    final Color color = connected ? Colors.green : Colors.orange;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: <Widget>[
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                connected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    connected
                        ? context.l10n.text('เชื่อมต่อแล้ว', 'Connected')
                        : context.l10n.text(
                            'ยังไม่ได้เชื่อมต่อ',
                            'Not connected',
                          ),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(controller.status),
                ],
              ),
            ),
            if (controller.requestInProgress)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}

class _StandaloneSetupCard extends StatelessWidget {
  const _StandaloneSetupCard({
    required this.busy,
    required this.autoConnect,
    required this.onConfigure,
    required this.onAutoConnectChanged,
    required this.onConnect,
  });

  final bool busy;
  final bool autoConnect;
  final Future<void> Function()? onConfigure;
  final ValueChanged<bool> onAutoConnectChanged;
  final Future<void> Function() onConnect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              context.l10n.text('ตั้งค่าแบบ Standalone', 'Standalone setup'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.text(
                'เชื่อมต่อมือถือกับ Wi-Fi ของ กล่องควบคุม ก่อน แล้วจึงกดเชื่อมต่อ Controller',
                'Connect your phone to the control box Wi-Fi first, then connect the controller.',
              ),
            ),
            const SizedBox(height: 14),
            if (onConfigure != null)
              FilledButton.icon(
                onPressed: busy ? null : onConfigure,
                icon: const Icon(Icons.format_list_numbered_rounded),
                label: Text(
                  context.l10n.text(
                    'เริ่มตั้งค่า Controller และ Wi-Fi',
                    'Start controller and Wi-Fi setup',
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              context.l10n.text(
                'Controller เคยตั้งค่า Wi-Fi แล้ว',
                'Controller was already configured',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: busy ? null : onConnect,
              icon: const Icon(Icons.link_rounded),
              label: Text(
                context.l10n.text(
                  'เชื่อมต่อ Controller ที่บันทึกไว้',
                  'Connect saved controller',
                ),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: autoConnect,
              onChanged: busy ? null : onAutoConnectChanged,
              title: Text(
                context.l10n.text(
                  'เชื่อมต่ออัตโนมัติเมื่อเปิดหน้านี้',
                  'Connect automatically when this page opens',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceInfoCard extends StatelessWidget {
  const _DeviceInfoCard({required this.controller});
  final SmartFarmController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.l10n.text('ข้อมูล Controller', 'Controller information'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Device ID', value: controller.deviceId ?? '—'),
            _InfoRow(
              label: 'Firmware',
              value: controller.firmwareVersion ?? '—',
            ),
            _InfoRow(
              label: context.l10n.text('เครือข่าย', 'Network'),
              value:
                  controller.accessPointSsid ??
                  controller.connectionMode ??
                  '—',
            ),
            _InfoRow(label: 'IP', value: controller.accessPointIp ?? '—'),
            _InfoRow(
              label: context.l10n.text('รีเลย์', 'Relays'),
              value: (controller.relayCount ?? controller.relays.length)
                  .toString(),
            ),
            _InfoRow(
              label: context.l10n.text('เวลาตอบสนอง', 'Response'),
              value: controller.lastResponseMs == null
                  ? '—'
                  : '${controller.lastResponseMs} ms',
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkSetupEntry extends StatelessWidget {
  const _NetworkSetupEntry({required this.onTap});
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.router_rounded),
        title: Text(
          context.l10n.text(
            'ตั้งค่า Controller และ Wi-Fi',
            'Controller and Wi-Fi setup',
          ),
        ),
        subtitle: Text(
          context.l10n.text(
            'เปลี่ยน Wi-Fi บ้านหรือฟาร์มได้ตลอด แม้ Controller เชื่อมต่ออยู่',
            'Change the home or farm Wi-Fi at any time, even while connected.',
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap == null ? null : () => onTap!(),
      ),
    );
  }
}

class _AdvancedEntry extends StatelessWidget {
  const _AdvancedEntry({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.tune_rounded),
        title: Text(
          context.l10n.text('ขั้นสูง', 'Advanced'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          context.l10n.text(
            'URL, API, เครือข่าย, Diagnostics และ Event Log',
            'URL, API, network, diagnostics and event log',
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _ControllerAdvancedPage extends StatefulWidget {
  const _ControllerAdvancedPage({
    required this.controller,
    required this.initialAutoReconnect,
    required this.onBaseUrlChanged,
    required this.onAutoReconnectChanged,
  });

  final SmartFarmController controller;
  final bool initialAutoReconnect;
  final ValueChanged<String> onBaseUrlChanged;
  final ValueChanged<bool> onAutoReconnectChanged;

  @override
  State<_ControllerAdvancedPage> createState() =>
      _ControllerAdvancedPageState();
}

class _ControllerAdvancedPageState extends State<_ControllerAdvancedPage> {
  late final TextEditingController _urlController;
  late bool _autoReconnect;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.controller.baseUrl);
    _autoReconnect = widget.initialAutoReconnect;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text(context.l10n.text('ขั้นสูง', 'Advanced'))),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        context.l10n.text('การเชื่อมต่อ', 'Connection'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _urlController,
                        enabled:
                            !widget.controller.connected &&
                            !widget.controller.requestInProgress,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'ที่อยู่กล่องควบคุม (URL)',
                          hintText: 'http://192.168.4.1',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.controller.connected
                                  ? null
                                  : () {
                                      widget.controller.resetBaseUrl();
                                      _urlController.text =
                                          widget.controller.baseUrl;
                                      widget.onBaseUrlChanged(
                                        widget.controller.baseUrl,
                                      );
                                    },
                              child: Text(
                                context.l10n.text('ค่าเริ่มต้น', 'Default'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              onPressed: widget.controller.connected
                                  ? null
                                  : () {
                                      widget.controller.setBaseUrl(
                                        _urlController.text,
                                      );
                                      _urlController.text =
                                          widget.controller.baseUrl;
                                      widget.onBaseUrlChanged(
                                        widget.controller.baseUrl,
                                      );
                                      FocusScope.of(context).unfocus();
                                    },
                              child: Text(
                                context.l10n.text('บันทึก URL', 'Save URL'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _autoReconnect,
                        onChanged: (bool value) {
                          setState(() => _autoReconnect = value);
                          widget.onAutoReconnectChanged(value);
                        },
                        title: Text(
                          context.l10n.text(
                            'เชื่อมต่อใหม่อัตโนมัติ',
                            'Automatic reconnect',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        context.l10n.text(
                          'API และการวินิจฉัยระบบ',
                          'API and diagnostics',
                        ),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        label: context.l10n.text('โปรโตคอล', 'Protocol'),
                        value:
                            widget.controller.protocolVersion?.toString() ??
                            '—',
                      ),
                      _InfoRow(
                        label: 'API',
                        value: widget.controller.apiVersion?.toString() ?? '—',
                      ),
                      _InfoRow(
                        label: context.l10n.text(
                          'ล้มเหลวต่อเนื่อง',
                          'Failures',
                        ),
                        value: widget.controller.consecutiveFailures.toString(),
                      ),
                      _InfoRow(
                        label: context.l10n.text('ไคลเอนต์', 'Clients'),
                        value:
                            widget.controller.wifiClientCount?.toString() ??
                            '—',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _LogCard(controller: widget.controller),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.router_outlined),
                  title: Text(
                    context.l10n.text(
                      'การเชื่อมต่อของกล่องควบคุม',
                      'Controller connectivity',
                    ),
                  ),
                  subtitle: Text(
                    context.l10n.text(
                      'เวอร์ชันนี้ควบคุมผ่านเครือข่ายภายใน โดย กล่องควบคุม เป็นผู้ตัดสินใจและทำงานอัตโนมัติได้แม้แอปไม่ได้เชื่อมต่อ ส่วนการควบคุมผ่านอินเทอร์เน็ตจะเพิ่มผ่านเราเตอร์และบริการที่ปลอดภัยในเวอร์ชันอนาคต',
                      'This version uses local-network control. control box remains authoritative and continues automation when the app is disconnected. Secure internet access through the farm router and a remote service is planned for a future release.',
                    ),
                  ),
                  isThreeLine: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          SizedBox(width: 110, child: Text(label)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.controller});
  final SmartFarmController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    context.l10n.text(
                      'บันทึกเหตุการณ์และ HTTP',
                      'Event and HTTP log',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                TextButton(
                  onPressed: controller.logs.isEmpty
                      ? null
                      : controller.clearLogs,
                  child: Text(context.l10n.text('ล้าง', 'Clear')),
                ),
              ],
            ),
            const Divider(),
            if (controller.logs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    context.l10n.text('ยังไม่มีเหตุการณ์', 'No events yet'),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: controller.logs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 5),
                  itemBuilder: (_, int index) => SelectableText(
                    controller.logs[index],
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
