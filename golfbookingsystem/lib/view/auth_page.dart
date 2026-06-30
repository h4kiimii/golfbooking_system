import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/auth_session.dart';
import '../model/user_profile.dart';
import '../services/account_service.dart';
import '../services/app_language.dart';
import '../theme/app_theme.dart';
import 'widgets/app_background.dart';
import 'widgets/app_logo.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    this.backgroundUrl,
    required this.language,
    required this.onLanguageChanged,
    required this.onAuthenticated,
  });

  final String? backgroundUrl;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final ValueChanged<AuthSession> onAuthenticated;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isSignUp = false;

  AccountService? get _accountService {
    try {
      return AccountService();
    } catch (_) {
      return null;
    }
  }

  Future<void> _login(String email, String password) async {
    final service = _accountService;
    if (service == null) {
      widget.onAuthenticated(_localLoginSession(email, password));
      return;
    }

    final session = await service.signIn(email: email, password: password);
    widget.onAuthenticated(session);
  }

  Future<void> _signUp(UserProfile profile, String password) async {
    final service = _accountService;
    if (service == null) {
      widget.onAuthenticated(AuthSession(profile: profile, password: password));
      return;
    }

    final session = await service.signUp(profile: profile, password: password);
    widget.onAuthenticated(session);
  }

  Future<void> _sendPasswordReset(String email) async {
    final service = _accountService;
    if (service == null) {
      throw const AuthException('Supabase Auth is not available.');
    }
    await service.sendPasswordResetEmail(email: email);
  }

  AuthSession _localLoginSession(String email, String password) {
    return AuthSession(
      password: password,
      profile: UserProfile(
        fullName: 'Golf Member',
        email: email,
        age: '21',
        birthday: DateTime(2005, 1, 1),
        address: 'Kuala Lumpur, Malaysia',
        phoneNumber: '+60 12-345 6789',
        loginProvider: 'User Email',
      ),
    );
  }

  String _text(String english, String malay) {
    return widget.language == AppLanguage.malay ? malay : english;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        imageUrl: widget.backgroundUrl,
        forceDarkOverlay: true,
        child: Theme(
          data: AppTheme.darkTheme,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                const SizedBox(height: 18),
                const Center(
                  child: AppLogo(
                    width: 170,
                    height: 118,
                    backgroundColor: AppTheme.lightGreen,
                  ),
                ),
                const SizedBox(height: 18),
                Builder(
                  builder: (context) {
                    return Text(
                      _isSignUp
                          ? _text('Create User Account', 'Daftar Akaun')
                          : _text('Welcome Back', 'Selamat Kembali'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    );
                  },
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    return Text(
                      'UPSI Driving Range',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    );
                  },
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.center,
                  child: SegmentedButton<AppLanguage>(
                    segments: const [
                      ButtonSegment(
                        value: AppLanguage.english,
                        icon: Icon(Icons.language_rounded),
                        label: Text('English'),
                      ),
                      ButtonSegment(
                        value: AppLanguage.malay,
                        icon: Icon(Icons.translate_rounded),
                        label: Text('BM'),
                      ),
                    ],
                    selected: {widget.language},
                    onSelectionChanged: (selection) {
                      widget.onLanguageChanged(selection.first);
                    },
                  ),
                ),
                const SizedBox(height: 18),
                if (_isSignUp)
                  _SignUpForm(language: widget.language, onSubmit: _signUp)
                else
                  _LoginForm(
                    language: widget.language,
                    onSubmit: _login,
                    onPasswordResetRequested: _sendPasswordReset,
                  ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp
                        ? _text(
                            'Already have an account? Log in',
                            'Sudah ada akaun? Log masuk',
                          )
                        : _text(
                            'New user? Create an account',
                            'Pengguna baharu? Daftar akaun',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm({
    required this.language,
    required this.onSubmit,
    required this.onPasswordResetRequested,
  });

  final AppLanguage language;
  final Future<void> Function(String email, String password) onSubmit;
  final Future<void> Function(String email) onPasswordResetRequested;

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  static const _rememberEmailKey = 'remembered_login_email';
  static const _rememberPasswordKey = 'remembered_login_password';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedLogin();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onSubmit(
        _emailController.text.trim(),
        _passwordController.text,
      );
      await _saveRememberedLogin();
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not log in. ${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _text(String english, String malay) {
    return widget.language == AppLanguage.malay ? malay : english;
  }

  Future<void> _loadRememberedLogin() async {
    final preferences = await SharedPreferences.getInstance();
    final email = preferences.getString(_rememberEmailKey) ?? '';
    final password = preferences.getString(_rememberPasswordKey) ?? '';
    if (!mounted || email.isEmpty || password.isEmpty) return;

    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
      _rememberMe = true;
    });
  }

  Future<void> _saveRememberedLogin() async {
    final preferences = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await preferences.setString(
        _rememberEmailKey,
        _emailController.text.trim(),
      );
      await preferences.setString(
        _rememberPasswordKey,
        _passwordController.text,
      );
      return;
    }

    await preferences.remove(_rememberEmailKey);
    await preferences.remove(_rememberPasswordKey);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.email_rounded),
            ).copyWith(labelText: _text('Email', 'Emel')),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return _text('Enter your email', 'Masukkan emel anda');
              }
              if (!value.contains('@')) {
                return _text('Enter a valid email', 'Masukkan emel yang sah');
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: _text('Password', 'Kata laluan'),
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                tooltip: _showPassword
                    ? _text('Hide password', 'Sembunyikan kata laluan')
                    : _text('Show password', 'Papar kata laluan'),
                onPressed: () {
                  setState(() => _showPassword = !_showPassword);
                },
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
              ),
            ),
            validator: (value) => value == null || value.length < 6
                ? _text(
                    'Password must be at least 6 characters',
                    'Kata laluan mesti sekurang-kurangnya 6 aksara',
                  )
                : null,
          ),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() => _rememberMe = value ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(_text('Remember me', 'Ingat saya')),
                ),
              ),
              TextButton(
                onPressed: _isLoading ? null : _sendPasswordReset,
                child: Text(_text('Forgot Password?', 'Lupa Kata Laluan?')),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _login,
              icon: const Icon(Icons.login_rounded),
              label: Text(
                _isLoading
                    ? _text('Logging In...', 'Sedang Log Masuk...')
                    : _text('Log In', 'Log Masuk'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text('Enter your email first.', 'Masukkan emel anda dahulu.'),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onPasswordResetRequested(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Password reset email sent to $email.',
              'Emel tetapan semula kata laluan telah dihantar ke $email.',
            ),
          ),
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not send reset email. ${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _SignUpForm extends StatefulWidget {
  const _SignUpForm({required this.language, required this.onSubmit});

  final AppLanguage language;
  final Future<void> Function(UserProfile profile, String password) onSubmit;

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _birthday;
  bool _showBirthdayError = false;
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthday = picked;
        _showBirthdayError = false;
      });
    }
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate() || _birthday == null) {
      setState(() => _showBirthdayError = _birthday == null);
      return;
    }

    final profile = UserProfile(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      age: _ageController.text.trim(),
      birthday: _birthday!,
      address: _addressController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      loginProvider: 'Email Sign Up',
    );

    setState(() => _isLoading = true);
    try {
      await widget.onSubmit(profile, _passwordController.text);
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not create account. ${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _text(String english, String malay) {
    return widget.language == AppLanguage.malay ? malay : english;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _fullNameController,
            decoration: InputDecoration(
              labelText: _text('Full name', 'Nama penuh'),
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
              prefixIcon: const Icon(Icons.email_rounded),
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) {
                return _text('Enter your email', 'Masukkan emel anda');
              }
              if (!text.contains('@')) {
                return _text('Enter a valid email', 'Masukkan emel yang sah');
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: _text('Password', 'Kata laluan'),
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                tooltip: _showPassword
                    ? _text('Hide password', 'Sembunyikan kata laluan')
                    : _text('Show password', 'Papar kata laluan'),
                onPressed: () {
                  setState(() => _showPassword = !_showPassword);
                },
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
              ),
            ),
            validator: (value) => value == null || value.length < 6
                ? _text(
                    'Password must be at least 6 characters',
                    'Kata laluan mesti sekurang-kurangnya 6 aksara',
                  )
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _text('Age', 'Umur'),
              prefixIcon: const Icon(Icons.cake_rounded),
            ),
            validator: _required,
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _pickBirthday,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: _text('Birthday date', 'Tarikh lahir'),
                prefixIcon: const Icon(Icons.calendar_month_rounded),
              ),
              child: Text(
                _birthday == null
                    ? _text('Choose birthday', 'Pilih tarikh lahir')
                    : '${_birthday!.day}/${_birthday!.month}/${_birthday!.year}',
              ),
            ),
          ),
          if (_showBirthdayError)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _text('Select your birthday date', 'Pilih tarikh lahir anda'),
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: _text('Address', 'Alamat'),
              prefixIcon: const Icon(Icons.home_rounded),
            ),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: _text('Phone number', 'Nombor telefon'),
              prefixIcon: const Icon(Icons.phone_rounded),
            ),
            validator: _required,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _createAccount,
              icon: const Icon(Icons.person_add_rounded),
              label: Text(
                _isLoading
                    ? _text('Creating Account...', 'Sedang Mendaftar...')
                    : _text('Sign Up', 'Daftar'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty
        ? _text('This field is required', 'Medan ini diperlukan')
        : null;
  }
}
