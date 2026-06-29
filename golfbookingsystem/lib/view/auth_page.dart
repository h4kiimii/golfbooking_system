import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/auth_session.dart';
import '../model/user_profile.dart';
import '../services/account_service.dart';
import '../theme/app_theme.dart';
import 'widgets/app_background.dart';
import 'widgets/app_logo.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    this.backgroundUrl,
    required this.onAuthenticated,
  });

  final String? backgroundUrl;
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
                      _isSignUp ? 'Create User Account' : 'Welcome Back',
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
                if (_isSignUp)
                  _SignUpForm(onSubmit: _signUp)
                else
                  _LoginForm(
                    onSubmit: _login,
                    onPasswordResetRequested: _sendPasswordReset,
                  ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Log in'
                        : 'New user? Create an account',
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
    required this.onSubmit,
    required this.onPasswordResetRequested,
  });

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
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_rounded),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter your email';
              }
              if (!value.contains('@')) {
                return 'Enter a valid email';
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
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                tooltip: _showPassword ? 'Hide password' : 'Show password',
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
                ? 'Password must be at least 6 characters'
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
                  title: const Text('Remember me'),
                ),
              ),
              TextButton(
                onPressed: _isLoading ? null : _sendPasswordReset,
                child: const Text('Forgot Password?'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _login,
              icon: const Icon(Icons.login_rounded),
              label: Text(_isLoading ? 'Logging In...' : 'Log In'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter your email first.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onPasswordResetRequested(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email.')),
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
  const _SignUpForm({required this.onSubmit});

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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: 'Full name',
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
              prefixIcon: Icon(Icons.email_rounded),
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Enter your email';
              if (!text.contains('@')) return 'Enter a valid email';
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
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                tooltip: _showPassword ? 'Hide password' : 'Show password',
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
                ? 'Password must be at least 6 characters'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Age',
              prefixIcon: Icon(Icons.cake_rounded),
            ),
            validator: _required,
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _pickBirthday,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Birthday date',
                prefixIcon: Icon(Icons.calendar_month_rounded),
              ),
              child: Text(
                _birthday == null
                    ? 'Choose birthday'
                    : '${_birthday!.day}/${_birthday!.month}/${_birthday!.year}',
              ),
            ),
          ),
          if (_showBirthdayError)
            const Padding(
              padding: EdgeInsets.only(left: 12, top: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select your birthday date',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Address',
              prefixIcon: Icon(Icons.home_rounded),
            ),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              prefixIcon: Icon(Icons.phone_rounded),
            ),
            validator: _required,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _createAccount,
              icon: const Icon(Icons.person_add_rounded),
              label: Text(_isLoading ? 'Creating Account...' : 'Sign Up'),
            ),
          ),
        ],
      ),
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty
        ? 'This field is required'
        : null;
  }
}
