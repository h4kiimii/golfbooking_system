import 'package:flutter/material.dart';

import '../model/feedback_message.dart';
import '../model/user_profile.dart';
import '../services/app_data_service.dart';
import '../services/app_language.dart';
import 'widgets/info_tile.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({
    super.key,
    required this.profile,
    required this.contactSettings,
    required this.onFeedbackSubmitted,
    required this.language,
  });

  final UserProfile profile;
  final ContactSettings contactSettings;
  final ValueChanged<FeedbackMessage> onFeedbackSubmitted;
  final AppLanguage language;

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _messageController = TextEditingController();
  String _category = 'General Feedback';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _emailController = TextEditingController(text: widget.profile.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    if (!_formKey.currentState!.validate()) return;

    widget.onFeedbackSubmitted(
      FeedbackMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        category: _category,
        message: _messageController.text.trim(),
        submittedAt: DateTime.now(),
      ),
    );

    _messageController.clear();
    setState(() => _category = 'General Feedback');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _text(
            'Feedback submitted to the administrator.',
            'Maklum balas telah dihantar kepada pentadbir.',
          ),
        ),
      ),
    );
  }

  String _text(String english, String malay) {
    return widget.language == AppLanguage.malay ? malay : english;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          _text('Contact & Feedback', 'Hubungi & Maklum Balas'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          _text(
            'Contact us directly or send feedback through the form below.',
            'Hubungi kami secara terus atau hantar maklum balas melalui borang di bawah.',
          ),
        ),
        const SizedBox(height: 14),
        InfoTile(
          icon: Icons.phone_rounded,
          title: _text('Phone number', 'Nombor telefon'),
          description: widget.contactSettings.phone,
        ),
        const SizedBox(height: 12),
        InfoTile(
          icon: Icons.email_rounded,
          title: _text('Email', 'Emel'),
          description: widget.contactSettings.email,
        ),
        const SizedBox(height: 12),
        InfoTile(
          icon: Icons.location_on_rounded,
          title: _text('Address', 'Alamat'),
          description: widget.contactSettings.address,
        ),
        const SizedBox(height: 12),
        InfoTile(
          icon: Icons.access_time_rounded,
          title: _text('Operating hours', 'Waktu operasi'),
          description: widget.contactSettings.operatingHours,
        ),
        const SizedBox(height: 24),
        Text(
          _text('Send Feedback', 'Hantar Maklum Balas'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: _text('Name', 'Nama'),
                  prefixIcon: const Icon(Icons.person_rounded),
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: _text('Email', 'Emel'),
                  prefixIcon: const Icon(Icons.mail_rounded),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) {
                    return _text('Enter your email', 'Masukkan emel anda');
                  }
                  if (!email.contains('@')) {
                    return _text(
                      'Enter a valid email',
                      'Masukkan emel yang sah',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: _text(
                    'Feedback category',
                    'Kategori maklum balas',
                  ),
                  prefixIcon: const Icon(Icons.category_rounded),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'General Feedback',
                    child: Text(_text('General Feedback', 'Maklum Balas Umum')),
                  ),
                  DropdownMenuItem(
                    value: 'Booking Issue',
                    child: Text(_text('Booking Issue', 'Isu Tempahan')),
                  ),
                  DropdownMenuItem(
                    value: 'Payment Issue',
                    child: Text(_text('Payment Issue', 'Isu Pembayaran')),
                  ),
                  DropdownMenuItem(
                    value: 'Suggestion',
                    child: Text(_text('Suggestion', 'Cadangan')),
                  ),
                  DropdownMenuItem(
                    value: 'Complaint',
                    child: Text(_text('Complaint', 'Aduan')),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: _text('Feedback message', 'Mesej maklum balas'),
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.feedback_rounded),
                ),
                validator: _required,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitFeedback,
                  icon: const Icon(Icons.send_rounded),
                  label: Text(_text('Submit Feedback', 'Hantar Maklum Balas')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty
        ? _text('This field is required', 'Medan ini diperlukan')
        : null;
  }
}
