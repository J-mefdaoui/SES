import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import '../shell.dart';

enum _AuthTab { login, signup }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  _AuthTab _tab = _AuthTab.login;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;
  bool _agreedToTerms = false;
  String? _errorMessage;
  int _passwordStrength = 0;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _switchTab(_AuthTab tab) {
    HapticFeedback.selectionClick();
    setState(() {
      _tab = tab;
      _errorMessage = null;
      _passwordStrength = 0;
    });
  }

  void _updatePasswordStrength(String value) {
    int strength = 0;
    if (value.length >= 8) strength++;
    if (value.contains(RegExp(r'[A-Z]'))) strength++;
    if (value.contains(RegExp(r'[0-9]'))) strength++;
    if (value.contains(RegExp(r'[!@#\$%^&*]'))) strength++;
    setState(() => _passwordStrength = strength);
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _loading = true;
    });
    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    // Demo: wrong password triggers error
    if (_passwordCtrl.text == 'wrong') {
      setState(() {
        _loading = false;
        _errorMessage = 'Incorrect email or password. Please try again.';
      });
      return;
    }

    setState(() => _loading = false);
    _navigateToApp();
  }

  Future<void> _continueAsGuest() async {
    HapticFeedback.selectionClick();
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _loading = false);
    _navigateToApp();
  }

  void _navigateToApp() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AppShell(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NMColors.bg,
      body: Stack(
        children: [
          const _GridBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  const _Logo(),
                  const SizedBox(height: 8),
                  const Text(
                    'Document what gets ignored.',
                    style: TextStyle(color: NMColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 36),
                  _TabSwitcher(activeTab: _tab, onSwitch: _switchTab),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    _ErrorBanner(_errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  // Form fields
                  if (_tab == _AuthTab.signup) ...[
                    _buildFieldLabel('Display name'),
                    const SizedBox(height: 6),
                    _InputField(
                      controller: _nameCtrl,
                      hint: 'How you appear on the map',
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildFieldLabel('Email'),
                  const SizedBox(height: 6),
                  _InputField(
                    controller: _emailCtrl,
                    hint: 'your@email.com',
                    keyboardType: TextInputType.emailAddress,
                    hasError: _errorMessage != null,
                  ),
                  const SizedBox(height: 16),
                  _buildFieldLabel('Password'),
                  const SizedBox(height: 6),
                  _InputField(
                    controller: _passwordCtrl,
                    hint: _tab == _AuthTab.login
                        ? 'Enter your password'
                        : 'Min. 8 characters',
                    obscure: _obscurePassword,
                    hasError: _errorMessage != null,
                    onChanged: _tab == _AuthTab.signup
                        ? _updatePasswordStrength
                        : null,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: NMColors.muted,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  if (_tab == _AuthTab.signup) ...[
                    const SizedBox(height: 8),
                    _PasswordStrength(strength: _passwordStrength),
                  ],
                  const SizedBox(height: 12),
                  if (_tab == _AuthTab.login)
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(color: NMColors.muted, fontSize: 12),
                        ),
                      ),
                    ),
                  if (_tab == _AuthTab.signup) ...[
                    const SizedBox(height: 4),
                    _TermsCheckbox(
                      value: _agreedToTerms,
                      onChanged: (v) =>
                          setState(() => _agreedToTerms = v ?? false),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _PrimaryButton(
                    label: _tab == _AuthTab.login ? 'Log in' : 'Create account',
                    loading: _loading,
                    onTap: _submit,
                  ),
                  const SizedBox(height: 20),
                  const _Divider(),
                  const SizedBox(height: 20),
                  _SocialButton(
                    onTap: _continueAsGuest,
                    icon: const _GoogleIcon(),
                    label:
                        '${_tab == _AuthTab.login ? 'Continue' : 'Sign up'} with Google',
                  ),
                  if (_tab == _AuthTab.login) ...[
                    const SizedBox(height: 10),
                    _SocialButton(
                      onTap: _continueAsGuest,
                      icon: const _GuestIcon(),
                      label: 'Continue as guest',
                      dimmed: true,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Reports submitted as guest are still geotagged\nbut not linked to an account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF3D5C42), fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: NMColors.muted,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    ),
  );
}

// Grid background
class _GridBackground extends StatelessWidget {
  const _GridBackground();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _GridPainter());
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4ADE80).withOpacity(0.04)
      ..strokeWidth = 0.5;
    const step = 60.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: NMColors.green.withOpacity(0.45),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: NMColors.green,
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      const Text(
        'NeglectMap',
        style: TextStyle(
          color: NMColors.text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _TabSwitcher extends StatelessWidget {
  final _AuthTab activeTab;
  final ValueChanged<_AuthTab> onSwitch;
  const _TabSwitcher({required this.activeTab, required this.onSwitch});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          _Tab(
            label: 'Log in',
            active: activeTab == _AuthTab.login,
            onTap: () => onSwitch(_AuthTab.login),
          ),
          _Tab(
            label: 'Sign up',
            active: activeTab == _AuthTab.signup,
            onTap: () => onSwitch(_AuthTab.signup),
          ),
        ],
      ),
      Container(height: 0.5, color: NMColors.border),
    ],
  );
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, right: 24),
          child: Text(
            label,
            style: TextStyle(
              color: active ? NMColors.green : NMColors.muted,
              fontSize: 14,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Container(
          height: 1.5,
          color: active ? NMColors.green : Colors.transparent,
        ),
      ],
    ),
  );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final bool hasError;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  const _InputField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.hasError = false,
    this.keyboardType,
    this.onChanged,
    this.suffix,
  });
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: obscure,
    keyboardType: keyboardType,
    onChanged: onChanged,
    style: const TextStyle(color: NMColors.text, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      suffixIcon: suffix,
      filled: true,
      fillColor: NMColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: _border(hasError),
      enabledBorder: _border(hasError),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: hasError ? NMColors.red : NMColors.green.withOpacity(0.55),
          width: 1,
        ),
      ),
    ),
  );
  OutlineInputBorder _border(bool hasError) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(
      color: hasError ? NMColors.red.withOpacity(0.5) : NMColors.border,
      width: 0.5,
    ),
  );
}

class _PasswordStrength extends StatelessWidget {
  final int strength;
  const _PasswordStrength({required this.strength});
  Color get _color => strength <= 1
      ? NMColors.red
      : strength == 2
      ? NMColors.orange
      : strength == 3
      ? NMColors.amber
      : NMColors.green;
  String get _label => strength <= 1
      ? 'Weak'
      : strength == 2
      ? 'Fair'
      : strength == 3
      ? 'Good'
      : 'Strong';
  @override
  Widget build(BuildContext context) {
    if (strength == 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            4,
            (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 2,
                decoration: BoxDecoration(
                  color: i < strength ? _color : NMColors.border,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _label,
          style: TextStyle(
            color: _color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: NMColors.red.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: NMColors.red.withOpacity(0.3), width: 0.5),
    ),
    child: Row(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.error_outline, size: 15, color: NMColors.red),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: NMColors.red, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

class _TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  const _TermsCheckbox({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 20,
        height: 20,
        child: Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: NMColors.green,
          checkColor: const Color(0xFF0A1A0C),
          side: const BorderSide(color: NMColors.muted, width: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: Text(
          'I agree to the terms of service and privacy policy.',
          style: TextStyle(color: NMColors.muted, fontSize: 12),
        ),
      ),
    ],
  );
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      onPressed: loading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: NMColors.green,
        disabledBackgroundColor: NMColors.green.withOpacity(0.5),
        foregroundColor: const Color(0xFF0A1A0C),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF0A1A0C),
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Container(height: 0.5, color: NMColors.border)),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14),
        child: Text(
          'or continue with',
          style: TextStyle(color: NMColors.muted, fontSize: 11),
        ),
      ),
      Expanded(child: Container(height: 0.5, color: NMColors.border)),
    ],
  );
}

class _SocialButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget icon;
  final String label;
  final bool dimmed;
  const _SocialButton({
    required this.onTap,
    required this.icon,
    required this.label,
    this.dimmed = false,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: NMColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: NMColors.border, width: 0.5),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: dimmed ? NMColors.muted : NMColors.text,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();
  @override
  Widget build(BuildContext context) => Container(
    width: 18,
    height: 18,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white,
    ),
    child: const Center(
      child: Text(
        'G',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF444444),
        ),
      ),
    ),
  );
}

class _GuestIcon extends StatelessWidget {
  const _GuestIcon();
  @override
  Widget build(BuildContext context) => Container(
    width: 18,
    height: 18,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: NMColors.muted, width: 1),
    ),
    child: Center(
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: NMColors.muted,
        ),
      ),
    ),
  );
}
