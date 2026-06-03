import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/integrate api services/shu/shu_api_constant.dart';

class SocialHealthRegisterScreen extends StatefulWidget {
  const SocialHealthRegisterScreen({
    super.key,
  });

  static const String routeName = '/social-health-register';

  @override
  State<SocialHealthRegisterScreen> createState() =>
      _SocialHealthRegisterScreenState();
}

class _SocialHealthRegisterScreenState
    extends State<SocialHealthRegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSaving = false;
  bool _acceptedTerms = false;

  static const String _registerMutation = r'''
mutation RegisterUser($fullName: String!, $email: String!, $password: String!) {
  register(fullName: $fullName, email: $email, password: $password) {
    token
    user {
      id
      fullName
      email
      status
    }
  }
}
''';

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      _showError(
        'Please confirm that your registration information is correct.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final http.Response response = await http
          .post(
            Uri.parse(ShuApiConstants.graphql),
            headers: const <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(<String, dynamic>{
              'query': _registerMutation,
              'variables': <String, dynamic>{
                'fullName': _fullNameController.text.trim(),
                'email': _emailController.text.trim(),
                'password': _passwordController.text.trim(),
              },
            }),
          )
          .timeout(const Duration(seconds: 25));

      debugPrint('SHU REGISTER URL: ${ShuApiConstants.graphql}');
      debugPrint('SHU REGISTER STATUS: ${response.statusCode}');
      debugPrint('SHU REGISTER BODY: ${response.body}');

      final Map<String, dynamic> decoded = _decodeResponse(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final String message = _readString(
          decoded,
          <String>['message', 'error'],
          fallback: 'Unable to create account.',
        );

        throw Exception(message);
      }

      _throwIfGraphqlHasErrors(decoded);

      final Map<String, dynamic> registerData = _readRegisterData(decoded);

      if (registerData.isEmpty) {
        throw Exception('Registration response is missing account data.');
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Public user account created. Please login.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );

      Navigator.of(context).pop();
    } on TimeoutException {
      if (!mounted) {
        return;
      }

      _showError('The request took too long. Please try again.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Map<String, dynamic> _decodeResponse(String body) {
    final String cleanBody = body.trim();

    if (cleanBody.isEmpty) {
      return <String, dynamic>{};
    }

    if (cleanBody.startsWith('<!DOCTYPE html') ||
        cleanBody.startsWith('<html')) {
      throw Exception(
        'Backend returned HTML instead of JSON. Please check if the app is calling the correct /graphql endpoint.',
      );
    }

    try {
      final dynamic decoded = jsonDecode(cleanBody);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return <String, dynamic>{};
    } catch (_) {
      throw Exception('Invalid backend response. Expected JSON.');
    }
  }

  void _throwIfGraphqlHasErrors(Map<String, dynamic> json) {
    final dynamic errors = json['errors'];

    if (errors is List && errors.isNotEmpty) {
      final dynamic firstError = errors.first;

      if (firstError is Map<String, dynamic>) {
        final dynamic message = firstError['message'];

        if (message != null && message.toString().trim().isNotEmpty) {
          throw Exception(message.toString());
        }
      }

      throw Exception('Unable to create account.');
    }
  }

  Map<String, dynamic> _readRegisterData(Map<String, dynamic> json) {
    final dynamic data = json['data'];

    if (data is Map<String, dynamic>) {
      final dynamic register = data['register'];

      if (register is Map<String, dynamic>) {
        return register;
      }

      final dynamic registerUser = data['registerUser'];

      if (registerUser is Map<String, dynamic>) {
        return registerUser;
      }

      final dynamic socialHealthRegister = data['socialHealthRegister'];

      if (socialHealthRegister is Map<String, dynamic>) {
        return socialHealthRegister;
      }
    }

    return <String, dynamic>{};
  }

  String _readString(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final String key in keys) {
      final dynamic value = json[key];

      if (value == null) {
        continue;
      }

      final String text = value.toString().trim();

      if (text.isNotEmpty && text != 'null') {
        return text;
      }
    }

    return fallback;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
  }

  String? _requiredValidator(String? value, String fieldName) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) {
      return '$fieldName is required.';
    }

    return null;
  }

  String? _emailValidator(String? value) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Email is required.';
    }

    final bool isValidEmail = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    ).hasMatch(text);

    if (!isValidEmail) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? _passwordValidator(String? value) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Password is required.';
    }

    if (text.length < 8) {
      return 'Password must be at least 8 characters.';
    }

    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Please confirm your password.';
    }

    if (text != _passwordController.text.trim()) {
      return 'Passwords do not match.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        title: const Text(
          'Create Public Account',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 520,
              ),
              child: Column(
                children: <Widget>[
                  const _RegisterHeader(),
                  const SizedBox(height: 18),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: const BorderSide(
                        color: Color(0xFFBAE6FD),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: <Widget>[
                            TextFormField(
                              controller: _fullNameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Full name',
                                hintText: 'Example: Ahmad Sali',
                                prefixIcon: Icon(Icons.person_rounded),
                              ),
                              validator: (String? value) {
                                return _requiredValidator(value, 'Full name');
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                                hintText: 'example@email.com',
                                prefixIcon: Icon(Icons.email_rounded),
                              ),
                              validator: _emailValidator,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Contact number optional',
                                hintText: 'Example: 09123456789',
                                prefixIcon: Icon(Icons.phone_rounded),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Minimum 8 characters',
                                prefixIcon: const Icon(Icons.lock_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                  ),
                                ),
                              ),
                              validator: _passwordValidator,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Confirm password',
                                prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                  ),
                                ),
                              ),
                              validator: _confirmPasswordValidator,
                            ),
                            const SizedBox(height: 18),
                            _ConfirmationBox(
                              value: _acceptedTerms,
                              onChanged: _isSaving
                                  ? null
                                  : (bool? value) {
                                      setState(() {
                                        _acceptedTerms = value ?? false;
                                      });
                                    },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                    ),
                    onPressed: _isSaving ? null : _handleRegister,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.person_add_alt_1_rounded),
                    label: Text(
                      _isSaving ? 'Creating Account...' : 'Create Account',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () {
                            Navigator.of(context).pop();
                          },
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Already have an account? Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF0EA5E9),
            Color(0xFF0284C7),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: const Row(
        children: <Widget>[
          Icon(
            Icons.health_and_safety_rounded,
            color: Colors.white,
            size: 42,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Public User Registration',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Create an account to apply for appointments and receive QR notifications.',
                  style: TextStyle(
                    color: Color(0xFFE0F2FE),
                    height: 1.4,
                    fontWeight: FontWeight.w600,
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

class _ConfirmationBox extends StatelessWidget {
  const _ConfirmationBox({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: value ? const Color(0xFF16A34A) : const Color(0xFFE5E7EB),
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        title: const Text(
          'I confirm my information is correct.',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: const Text(
          'This account will be used for RHU appointments, messages, and QR notifications.',
        ),
      ),
    );
  }
}