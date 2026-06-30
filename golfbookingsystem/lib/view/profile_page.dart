import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../model/user_profile.dart';
import '../services/account_service.dart';
import '../services/app_language.dart';
import 'widgets/info_tile.dart';
import 'widgets/profile_image.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.profile,
    required this.currentPassword,
    required this.onPasswordChanged,
    required this.onProfileUpdated,
    required this.onLogout,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.language,
    required this.onLanguageChanged,
  });

  final UserProfile profile;
  final String currentPassword;
  final ValueChanged<String> onPasswordChanged;
  final ValueChanged<UserProfile> onProfileUpdated;
  final VoidCallback onLogout;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  String _text(String english, String malay) {
    return language == AppLanguage.malay ? malay : english;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Row(
          children: [
            ProfileImage(imagePath: profile.imagePath),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    _text(
                      'Logged in with ${profile.loginProvider}',
                      'Log masuk melalui ${profile.loginProvider}',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        InfoTile(
          icon: Icons.email_rounded,
          title: _text('Email', 'Emel'),
          description: profile.email,
        ),
        const SizedBox(height: 12),
        InfoTile(
          icon: Icons.cake_rounded,
          title: _text('Age and birthday', 'Umur dan tarikh lahir'),
          description: _text(
            '${profile.age} years old - ${profile.birthday.day}/${profile.birthday.month}/${profile.birthday.year}',
            '${profile.age} tahun - ${profile.birthday.day}/${profile.birthday.month}/${profile.birthday.year}',
          ),
        ),
        const SizedBox(height: 12),
        InfoTile(
          icon: Icons.phone_rounded,
          title: _text('Phone number', 'Nombor telefon'),
          description: profile.phoneNumber,
        ),
        const SizedBox(height: 12),
        InfoTile(
          icon: Icons.home_rounded,
          title: _text('Address', 'Alamat'),
          description: profile.address,
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.translate_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _text('Language', 'Bahasa'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                SegmentedButton<AppLanguage>(
                  segments: const [
                    ButtonSegment(
                      value: AppLanguage.english,
                      label: Text('EN'),
                    ),
                    ButtonSegment(value: AppLanguage.malay, label: Text('BM')),
                  ],
                  selected: {language},
                  onSelectionChanged: (selection) {
                    onLanguageChanged(selection.first);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: SwitchListTile(
            value: isDarkMode,
            onChanged: onThemeChanged,
            secondary: const Icon(Icons.dark_mode_rounded),
            title: Text(_text('Dark Mode', 'Mod Gelap')),
            subtitle: Text(
              _text(
                'Use the darker admin-style app theme',
                'Gunakan tema aplikasi yang lebih gelap',
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => _showEditProfileSheet(context),
          icon: const Icon(Icons.edit_rounded),
          label: Text(_text('Edit Personal Info', 'Edit Maklumat Peribadi')),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _showChangePasswordSheet(context),
          icon: const Icon(Icons.password_rounded),
          label: Text(_text('Change Password', 'Tukar Kata Laluan')),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
          label: Text(_text('Log Out', 'Log Keluar')),
        ),
      ],
    );
  }

  Future<void> _showChangePasswordSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _ChangePasswordForm(
          currentPassword: currentPassword,
          onSaved: (newPassword) {
            onPasswordChanged(newPassword);
            Navigator.of(sheetContext).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password changed for the current app session.'),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showEditProfileSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _EditProfileForm(
          profile: profile,
          onSaved: (updatedProfile) {
            onProfileUpdated(updatedProfile);
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }
}

class _EditProfileForm extends StatefulWidget {
  const _EditProfileForm({required this.profile, required this.onSaved});

  final UserProfile profile;
  final ValueChanged<UserProfile> onSaved;

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _ChangePasswordForm extends StatefulWidget {
  const _ChangePasswordForm({
    required this.currentPassword,
    required this.onSaved,
  });

  final String currentPassword;
  final ValueChanged<String> onSaved;

  @override
  State<_ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<_ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      widget.onSaved(_newController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              'Change Password',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'This prototype stores the changed password only for the current app session.',
            ),
            const SizedBox(height: 14),
            _PasswordField(
              controller: _currentController,
              label: 'Current password',
              visible: _showCurrent,
              onToggleVisibility: () {
                setState(() => _showCurrent = !_showCurrent);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter your current password';
                }
                if (value != widget.currentPassword) {
                  return 'Current password is incorrect';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _PasswordField(
              controller: _newController,
              label: 'New password',
              visible: _showNew,
              onToggleVisibility: () => setState(() => _showNew = !_showNew),
              validator: (value) {
                if (value == null || value.length < 8) {
                  return 'Use at least 8 characters';
                }
                if (value == widget.currentPassword) {
                  return 'New password must be different';
                }
                if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
                    !RegExp(r'[0-9]').hasMatch(value)) {
                  return 'Include at least one letter and one number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _PasswordField(
              controller: _confirmController,
              label: 'Confirm new password',
              visible: _showConfirm,
              onToggleVisibility: () {
                setState(() => _showConfirm = !_showConfirm);
              },
              validator: (value) => value != _newController.text
                  ? 'Passwords do not match'
                  : null,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.lock_reset_rounded),
              label: const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.visible,
    required this.onToggleVisibility,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool visible;
  final VoidCallback onToggleVisibility;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      enableSuggestions: false,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_rounded),
        suffixIcon: IconButton(
          tooltip: visible ? 'Hide password' : 'Show password',
          onPressed: onToggleVisibility,
          icon: Icon(
            visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          ),
        ),
      ),
      validator: validator,
    );
  }
}

class _EditProfileFormState extends State<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _ageController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late DateTime _birthday;
  String? _imagePath;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _emailController = TextEditingController(text: widget.profile.email);
    _ageController = TextEditingController(text: widget.profile.age);
    _addressController = TextEditingController(text: widget.profile.address);
    _phoneController = TextEditingController(text: widget.profile.phoneNumber);
    _imagePath = widget.profile.imagePath;
    _birthday = widget.profile.birthday;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthday = picked);
    }
  }

  Future<void> _chooseProfilePhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final imageUrl = await AccountService().uploadProfileImage(
        bytes: await picked.readAsBytes(),
        fileName: picked.name,
      );
      if (!mounted) return;
      setState(() => _imagePath = imageUrl);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not upload profile photo: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    widget.onSaved(
      widget.profile.copyWith(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        age: _ageController.text.trim(),
        birthday: _birthday,
        address: _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        imagePath: _imagePath,
        clearImagePath: _imagePath == null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text('Edit Profile', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            Center(child: ProfileImage(imagePath: _imagePath, radius: 48)),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isUploadingImage ? null : _chooseProfilePhoto,
              icon: Icon(
                _isUploadingImage
                    ? Icons.hourglass_top_rounded
                    : Icons.photo_library_rounded,
              ),
              label: Text(
                _isUploadingImage ? 'Uploading Photo...' : 'Choose Photo',
              ),
            ),
            if (_imagePath != null && _imagePath!.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() => _imagePath = null),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Remove Photo'),
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickBirthday,
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text(
                '${_birthday.day}/${_birthday.month}/${_birthday.year}',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Address'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
              validator: _required,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty
        ? 'This field is required'
        : null;
  }
}
