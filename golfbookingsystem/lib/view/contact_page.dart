import 'package:flutter/material.dart';

import '../model/feedback_message.dart';
import '../model/user_profile.dart';
import '../services/app_data_service.dart';
import 'widgets/info_tile.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({
    super.key,
    required this.profile,
    required this.contactSettings,
    required this.onFeedbackSubmitted,
  });

  final UserProfile profile;
  final ContactSettings contactSettings;
  final ValueChanged<FeedbackMessage> onFeedbackSubmitted;

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
      const SnackBar(content: Text('Feedback submitted to the administrator.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Contact & Feedback',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        const Text(
          'Contact us directly or send feedback through the form below.',
        ),
        const SizedBox(height: 14),
        InfoTile(
          icon: Icons.phone_rounded,
          title: 'Phone number',
          description: widget.contactSettings.phone,
        ),
        const SizedBox(height: 12),
        InfoTile(
          icon: Icons.email_rounded,
          title: 'Email',
          description: widget.contactSettings.email,
        ),
        const SizedBox(height: 12),
        InfoTile(
          icon: Icons.location_on_rounded,
          title: 'Address',
          description: widget.contactSettings.address,
        ),
        const SizedBox(height: 12),
        InfoTile(
          icon: Icons.access_time_rounded,
          title: 'Operating hours',
          description: widget.contactSettings.operatingHours,
        ),
        const SizedBox(height: 24),
        Text('Send Feedback', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_rounded),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'Enter your email';
                  if (!email.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Feedback category',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'General Feedback',
                    child: Text('General Feedback'),
                  ),
                  DropdownMenuItem(
                    value: 'Booking Issue',
                    child: Text('Booking Issue'),
                  ),
                  DropdownMenuItem(
                    value: 'Payment Issue',
                    child: Text('Payment Issue'),
                  ),
                  DropdownMenuItem(
                    value: 'Suggestion',
                    child: Text('Suggestion'),
                  ),
                  DropdownMenuItem(
                    value: 'Complaint',
                    child: Text('Complaint'),
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
                decoration: const InputDecoration(
                  labelText: 'Feedback message',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.feedback_rounded),
                ),
                validator: _required,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitFeedback,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Submit Feedback'),
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
        ? 'This field is required'
        : null;
  }
}
