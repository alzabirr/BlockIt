import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../storage/hive_storage.dart';
import '../themes/app_theme.dart';
import '../widgets/ambient_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final HiveStorage _storage = HiveStorage();
  late String _profileName;
  late String _workspaceName;
  late bool _notificationsEnabled;
  late bool _cloudSyncEnabled;
  late bool _hapticFeedbackEnabled;

  @override
  void initState() {
    super.initState();
    _profileName = _storage.getSetting('profileName', 'Starter User') as String;
    _workspaceName =
        _storage.getSetting('workspaceName', 'Personal workspace') as String;
    _notificationsEnabled =
        _storage.getSetting('notificationsEnabled', true) as bool;
    _cloudSyncEnabled = _storage.getSetting('cloudSyncEnabled', false) as bool;
    _hapticFeedbackEnabled =
        _storage.getSetting('hapticFeedbackEnabled', true) as bool;
  }

  Future<void> _saveBool(String key, bool value) async {
    await _storage.saveSetting(key, value);
  }

  Future<void> _updateNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await _saveBool('notificationsEnabled', value);
  }

  Future<void> _updateCloudSync(bool value) async {
    setState(() => _cloudSyncEnabled = value);
    await _saveBool('cloudSyncEnabled', value);
    if (!mounted) return;
    _showInfoDialog(
      title: value ? 'Cloud sync on' : 'Cloud sync off',
      message: value
          ? 'Your data will be backed up when cloud sync is connected.'
          : 'Your data will stay local on this device.',
    );
  }

  Future<void> _updateHapticFeedback(bool value) async {
    setState(() => _hapticFeedbackEnabled = value);
    await _saveBool('hapticFeedbackEnabled', value);
  }

  Future<void> _showEditProfileDialog() async {
    final nameController = TextEditingController(text: _profileName);
    final workspaceController = TextEditingController(text: _workspaceName);

    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Edit profile'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                CupertinoTextField(
                  controller: nameController,
                  placeholder: 'Name',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 10),
                CupertinoTextField(
                  controller: workspaceController,
                  placeholder: 'Workspace',
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                final name = nameController.text.trim().isEmpty
                    ? 'Starter User'
                    : nameController.text.trim();
                final workspace = workspaceController.text.trim().isEmpty
                    ? 'Personal workspace'
                    : workspaceController.text.trim();

                setState(() {
                  _profileName = name;
                  _workspaceName = workspace;
                });
                await _storage.saveSetting('profileName', name);
                await _storage.saveSetting('workspaceName', workspace);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    workspaceController.dispose();
  }

  void _showInfoDialog({required String title, required String message}) {
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    _showInfoDialog(
      title: 'Privacy',
      message:
          'Data is stored locally on this device.',
    );
  }

  void _showAboutDialog() {
    _showInfoDialog(
      title: 'About Starter Kit',
      message: 'Starter Kit 1.0.0\nA beautiful flutter boilerplate.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) {
    return Scaffold(
      backgroundColor: bgLight,
      body: AmbientBackground(
        child: SafeArea(
          child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                physics: const BouncingScrollPhysics(),
                children: [
                  Row(
                    children: [
                      if (Navigator.of(context).canPop()) ...[
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(44, 44),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Icon(
                            CupertinoIcons.chevron_left,
                            color: textDark,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        'Settings',
                        style: headingStyle(
                          fontSize: 18,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _ProfileHeader(
                    name: _profileName,
                    workspaceName: _workspaceName,
                    onTap: _showEditProfileDialog,
                  ),
                  const SizedBox(height: 18),
                  _SettingsGroup(
                    title: 'Profile',
                    children: [
                      _ActionSetting(
                        icon: CupertinoIcons.person_crop_circle,
                        title: 'Edit profile',
                        subtitle: 'Name, photo and personal details',
                        onTap: _showEditProfileDialog,
                      ),
                      _Divider(),
                      _SwitchSetting(
                        title: 'Notifications',
                        value: _notificationsEnabled,
                        onChanged: _updateNotifications,
                      ),
                      _Divider(),
                      _SwitchSetting(
                        title: 'Cloud sync',
                        value: _cloudSyncEnabled,
                        onChanged: _updateCloudSync,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SettingsGroup(
                    title: 'App',
                    children: [
                      _SwitchSetting(
                        title: 'Dark Mode',
                        value: isDarkMode,
                        onChanged: (val) async {
                          await _storage.saveSetting('darkMode', val);
                          darkModeNotifier.value = val;
                          setState(() {});
                        },
                      ),
                      _Divider(),
                      _SwitchSetting(
                        title: 'Haptic feedback',
                        value: _hapticFeedbackEnabled,
                        onChanged: _updateHapticFeedback,
                      ),
                      _Divider(),
                      _ActionSetting(
                        icon: CupertinoIcons.lock_shield,
                        title: 'Privacy',
                        subtitle: 'Manage local data and permissions',
                        onTap: _showPrivacyDialog,
                      ),
                      _Divider(),
                      _ActionSetting(
                        icon: CupertinoIcons.info_circle,
                        title: 'About',
                        subtitle: 'Version 1.0.0',
                        onTap: _showAboutDialog,
                      ),
                    ],
                  ),
                ],
          ),
        ),
      ),
    );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String workspaceName;
  final VoidCallback onTap;

  const _ProfileHeader({
    required this.name,
    required this.workspaceName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: textDark.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primary, accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                CupertinoIcons.person_fill,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: headingStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    workspaceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bodyStyle(
                      color: textMid,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
             Icon(
              CupertinoIcons.chevron_forward,
              color: textMid,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: textDark.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: bodyStyle(
              fontSize: 13,
              color: textMid,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _ActionSetting extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionSetting({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bodyStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bodyStyle(
                    fontSize: 13,
                    color: textMid,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
           Icon(CupertinoIcons.chevron_forward, color: textMid, size: 18),
        ],
      ),
    );
  }
}

class _SwitchSetting extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchSetting({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: bodyStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        CupertinoSwitch(
          value: value,
          activeTrackColor: primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Container(height: 1, color: textDark.withValues(alpha: 0.07)),
    );
  }
}
