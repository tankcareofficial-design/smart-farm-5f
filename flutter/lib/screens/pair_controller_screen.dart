import 'package:flutter/material.dart';

import '../models/controller_candidate.dart';
import '../models/wifi_network.dart';
import '../stores/pairing_store.dart';
import '../widgets/pair_step_header.dart';

class PairControllerScreen extends StatefulWidget {
  const PairControllerScreen({super.key, required this.languageCode});

  final String languageCode;

  @override
  State<PairControllerScreen> createState() => _PairControllerScreenState();
}

class _PairControllerScreenState extends State<PairControllerScreen> {
  late final PairingStore _store;
  late final TextEditingController _passwordController;
  bool _hidePassword = true;

  bool get _isThai => widget.languageCode == 'th';

  @override
  void initState() {
    super.initState();
    _store = PairingStore();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_text('จับคู่ Controller', 'Pair Controller')),
        leading: IconButton(
          onPressed: _handleBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _store,
          builder: (context, _) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Padding(
                key: ValueKey<PairingStage>(_store.stage),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: _buildCurrentStage(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentStage() {
    switch (_store.stage) {
      case PairingStage.searching:
        return _buildSearching();
      case PairingStage.selectController:
        return _buildControllerSelection();
      case PairingStage.selectWifi:
        return _buildWifiSelection();
      case PairingStage.enterPassword:
        return _buildPasswordEntry();
      case PairingStage.connecting:
        return _buildConnecting();
      case PairingStage.success:
        return _buildSuccess();
    }
  }

  Widget _buildSearching() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PairStepHeader(
          step: 1,
          totalSteps: 4,
          title: _text(
            'เชื่อมต่อ Wi-Fi ของ Controller',
            'Connect to the controller Wi-Fi',
          ),
          subtitle: _text(
            'เปิด Controller แล้วเชื่อมโทรศัพท์เข้ากับ Wi-Fi SmartFarm-xxxxxx โดยใช้รหัสที่พิมพ์ไว้ข้างกล่อง',
            'Turn on the controller, then connect your phone to SmartFarm-xxxxxx using the password printed on the box.',
          ),
        ),
        const SizedBox(height: 24),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _PairInstructionRow(
                  number: 1,
                  text: _text(
                    'เปิดหน้า Wi-Fi ในโทรศัพท์',
                    'Open Wi-Fi settings on your phone',
                  ),
                ),
                const SizedBox(height: 16),
                _PairInstructionRow(
                  number: 2,
                  text: _text(
                    'เลือก SmartFarm-xxxxxx ให้ตรงกับรหัสข้างกล่อง',
                    'Select SmartFarm-xxxxxx matching the code on the box',
                  ),
                ),
                const SizedBox(height: 16),
                _PairInstructionRow(
                  number: 3,
                  text: _text(
                    'ใส่รหัส Wi-Fi ข้างกล่อง แล้วกลับมาที่แอป',
                    'Enter the Wi-Fi password on the box, then return to the app',
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_store.error != null) ...[
          const SizedBox(height: 16),
          Text(
            _store.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const Spacer(),
        FilledButton.icon(
          onPressed: _store.busy ? null : _store.startSearch,
          icon: _store.busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.wifi_find_rounded),
          label: Text(
            _text(
              'เชื่อมต่อและให้ กล่องควบคุม สแกน Wi-Fi',
              'Connect and ask control box to scan Wi-Fi',
            ),
          ),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
        ),
      ],
    );
  }

  Widget _buildControllerSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PairStepHeader(
          step: 1,
          totalSteps: 4,
          title: _text('ยังไม่พบ Controller', 'Controller not found'),
          subtitle: _text(
            'ตรวจสอบว่าโทรศัพท์เชื่อมอยู่กับ SmartFarm-xxxxxx ไม่ใช่ Wi-Fi บ้านหรืออินเทอร์เน็ตมือถือ',
            'Make sure the phone is connected to SmartFarm-xxxxxx, not home Wi-Fi or mobile data.',
          ),
        ),
        const SizedBox(height: 20),
        if (_store.error != null)
          Text(
            _store.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const Spacer(),
        FilledButton.icon(
          onPressed: _store.busy ? null : _store.startSearch,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(_text('ลองเชื่อมต่ออีกครั้ง', 'Try again')),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
        ),
      ],
    );
  }

  Widget _buildWifiSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PairStepHeader(
          step: 2,
          totalSteps: 4,
          title: _text('เลือก Wi-Fi', 'Choose Wi-Fi'),
          subtitle: _text(
            'Controller จะเชื่อมต่อเครือข่ายนี้หลังตั้งค่าเสร็จ',
            'The controller will connect to this network after setup.',
          ),
        ),
        const SizedBox(height: 18),
        if (_store.error != null) ...[
          Text(
            _store.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: ListView.separated(
            itemCount: _store.wifiNetworks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final WifiNetwork wifi = _store.wifiNetworks[index];

              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.wifi_rounded),
                  title: Text(
                    wifi.ssid,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    wifi.secure
                        ? _text(
                            'ปลอดภัย • ${wifi.rssi} dBm',
                            'Secured • ${wifi.rssi} dBm',
                          )
                        : _text(
                            'เครือข่ายเปิด • ${wifi.rssi} dBm',
                            'Open • ${wifi.rssi} dBm',
                          ),
                  ),
                  trailing: const Icon(Icons.lock_outline_rounded),
                  onTap: () => _store.selectWifi(wifi.ssid),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _store.busy ? null : _store.rescanWifi,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(_text('สแกน Wi-Fi ใหม่', 'Scan again')),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordEntry() {
    final String wifiName = _store.selectedWifi ?? '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PairStepHeader(
          step: 3,
          totalSteps: 4,
          title: _text('ใส่รหัสผ่าน Wi-Fi', 'Enter Wi-Fi password'),
          subtitle: _text(
            'กำลังตั้งค่าเครือข่าย $wifiName',
            'Configuring network $wifiName',
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _passwordController,
          obscureText: _hidePassword,
          textInputAction: TextInputAction.done,
          onChanged: _store.updatePassword,
          onSubmitted: (_) => _connectIfValid(),
          decoration: InputDecoration(
            labelText: _text('รหัสผ่าน', 'Password'),
            prefixIcon: const Icon(Icons.password_rounded),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _hidePassword = !_hidePassword;
                });
              },
              icon: Icon(
                _hidePassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
              ),
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _text(
            'ข้อมูลนี้จะถูกส่งตรงไปยัง Controller ในขั้นตอนของจริง',
            'This credential will be sent directly to the controller in the real setup.',
          ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: _connectIfValid,
          icon: const Icon(Icons.link_rounded),
          label: Text(_text('เชื่อมต่อ', 'Connect')),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
        ),
      ],
    );
  }

  Widget _buildConnecting() {
    return Column(
      children: [
        PairStepHeader(
          step: 4,
          totalSteps: 4,
          title: _text('กำลังตั้งค่า Controller', 'Setting up controller'),
          subtitle: _text(
            'กรุณาอย่าปิดแอปหรือ Controller',
            'Do not close the app or turn off the controller.',
          ),
        ),
        const Spacer(),
        Icon(
          Icons.developer_board_rounded,
          size: 86,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        LinearProgressIndicator(
          value: _store.progress,
          minHeight: 10,
          borderRadius: BorderRadius.circular(20),
        ),
        const SizedBox(height: 14),
        Text(
          '${(_store.progress * 100).round()}%',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          _text(
            'กำลังส่งค่า Wi-Fi และตรวจสอบการตอบกลับ',
            'Sending Wi-Fi settings and checking the response.',
          ),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildSuccess() {
    final PairingResult? result = _store.buildResult();

    return Column(
      children: [
        const Spacer(),
        Container(
          width: 116,
          height: 116,
          decoration: const BoxDecoration(
            color: Color(0xFFE4F5E7),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Color(0xFF2E7D32),
            size: 64,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _text('เชื่อมต่อสำเร็จ', 'Connected successfully'),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Text(
          result == null
              ? '-'
              : '${result.controllerName}\n${result.wifiName}\nIP: ${result.stationIp}\n\n${_text('กรุณาเปลี่ยนโทรศัพท์กลับไปเชื่อม Wi-Fi นี้ แล้วกดเสร็จสิ้น', 'Reconnect your phone to this Wi-Fi, then tap Finish')}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: result == null
              ? null
              : () => Navigator.of(context).pop(result),
          icon: const Icon(Icons.done_all_rounded),
          label: Text(_text('เสร็จสิ้น', 'Finish')),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
        ),
      ],
    );
  }

  void _connectIfValid() {
    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร',
              'Password must contain at least 8 characters.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    _store.connect();
  }

  void _handleBack() {
    if (_store.stage == PairingStage.searching ||
        _store.stage == PairingStage.selectController) {
      Navigator.of(context).pop();
      return;
    }

    if (_store.stage == PairingStage.connecting) {
      return;
    }

    _store.goBack();
  }

  String _text(String thai, String english) {
    return _isThai ? thai : english;
  }
}

class _PairInstructionRow extends StatelessWidget {
  const _PairInstructionRow({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            '$number',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
