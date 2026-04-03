import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import '../shell.dart';

// ── Which tab is active ───────────────────────────────────────────────────────
enum _AuthTab { login, signup }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  _AuthTab _tab = _AuthTab.login;

  // Controllers
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  // State
  bool _obscurePassword = true;
  bool _loading = false;
  bool _agreedToTerms = false;
  String? _errorMessage;

  // Password strength 0-4
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

    // Simulate network call
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    // Demo: wrong password triggers error state
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
        pageBuilder: (_, animation, __) => const AppShell(),
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
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Subtle map grid background ──────────────────────────────────
          const Positioned.fill(child: _GridBackground()),

          // ── Scrollable content ──────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // Logo mark + name
                  _LogoMark(),
                  const SizedBox(height: 8),

                  // Tagline
                  const Text(
                    'Document what gets ignored.',
                    style: TextStyle(
                      color: NMColors.muted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Tab switcher
                  _TabSwitcher(activeTab: _tab, onSwitch: _switchTab),
                  const SizedBox(height: 24),

                  // Error banner
                  if (_errorMessage != null) ...[
                    _ErrorBanner(message: _errorMessage!),
                    const SizedBox(height: 16),
                  ],

                  // Form fields
                  if (_tab == _AuthTab.signup) ...[
                    _FieldLabel('Display name'),
                    const SizedBox(height: 6),
                    _InputField(
                      controller: _nameCtrl,
                      hint: 'How you appear on the map',
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                  ],

                  _FieldLabel('Email'),
                  const SizedBox(height: 6),
                  _InputField(
                    controller: _emailCtrl,
                    hint: 'your@email.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    hasError: _errorMessage != null,
                  ),
                  const SizedBox(height: 16),

                  _FieldLabel('Password'),
                  const SizedBox(height: 6),
                  _InputField(
                    controller: _passwordCtrl,
                    hint: _tab == _AuthTab.login
                        ? 'Enter your password'
                        : 'Min. 8 characters',
                    obscure: _obscurePassword,
                    hasError: _errorMessage != null,
                    textInputAction: TextInputAction.done,
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

                  // Password strength (signup only)
                  if (_tab == _AuthTab.signup) ...[
                    const SizedBox(height: 8),
                    _PasswordStrength(strength: _passwordStrength),
                  ],

                  const SizedBox(height: 12),

                  // Forgot password (login only)
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

                  // Terms checkbox (signup only)
                  if (_tab == _AuthTab.signup) ...[
                    const SizedBox(height: 4),
                    _TermsCheckbox(
                      value: _agreedToTerms,
                      onChanged: (v) =>
                          setState(() => _agreedToTerms = v ?? false),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Primary CTA
                  _PrimaryButton(
                    label: _tab == _AuthTab.login ? 'Log in' : 'Create account',
                    loading: _loading,
                    onTap: _submit,
                  ),
                  const SizedBox(height: 20),

                  // Divider
                  const _Divider(),
                  const SizedBox(height: 20),

                  // Google
                  _SecondaryButton(
                    onTap: _continueAsGuest,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _GoogleIcon(),
                        const SizedBox(width: 10),
                        Text(
                          _tab == _AuthTab.login
                              ? 'Continue with Google'
                              : 'Sign up with Google',
                          style: const TextStyle(
                            color: NMColors.text,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Guest (login only)
                  if (_tab == _AuthTab.login) ...[
                    _SecondaryButton(
                      onTap: _continueAsGuest,
                      dimmed: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GuestIcon(),
                          const SizedBox(width: 10),
                          const Text(
                            'Continue as guest',
                            style: TextStyle(
                              color: NMColors.muted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Reports submitted as guest are still geotagged\nbut not linked to an account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF3D5C42),
                        fontSize: 11,
                        height: 1.6,
                      ),
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
}

// ── Grid background ───────────────────────────────────────────────────────────
class _GridBackground extends StatelessWidget {
  const _GridBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
  }
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

// ── Logo mark ─────────────────────────────────────────────────────────────────
class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
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
            letterSpacing: -0.6,
          ),
        ),
      ],
    );
  }
}

// ── Tab switcher ──────────────────────────────────────────────────────────────
class _TabSwitcher extends StatelessWidget {
  final _AuthTab activeTab;
  final ValueChanged<_AuthTab> onSwitch;

  const _TabSwitcher({required this.activeTab, required this.onSwitch});

  @override
  Widget build(BuildContext context) {
    return Column(
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
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
          // Active underline sits flush against the full-width separator
          Container(
            height: 1.5,
            color: active ? NMColors.green : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

// ── Field label ───────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: NMColors.muted,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Input field ───────────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final bool hasError;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;

  const _InputField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.hasError = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      style: const TextStyle(color: NMColors.text, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffix,
        filled: true,
        fillColor: NMColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: hasError ? NMColors.red.withOpacity(0.5) : NMColors.border,
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: hasError ? NMColors.red.withOpacity(0.5) : NMColors.border,
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: hasError ? NMColors.red : NMColors.green.withOpacity(0.55),
            width: 1,
          ),
        ),
      ),
    );
  }
}

// ── Password strength indicator ───────────────────────────────────────────────
class _PasswordStrength extends StatelessWidget {
  final int strength; // 0–4

  const _PasswordStrength({required this.strength});

  Color get _color {
    if (strength <= 1) return NMColors.red;
    if (strength == 2) return NMColors.orange;
    if (strength == 3) return NMColors.amber;
    return NMColors.green;
  }

  String get _label {
    if (strength == 0) return '';
    if (strength <= 1) return 'Weak';
    if (strength == 2) return 'Fair';
    if (strength == 3) return 'Good';
    return 'Strong';
  }

  @override
  Widget build(BuildContext context) {
    if (strength == 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 2,
                decoration: BoxDecoration(
                  color: i < strength ? _color : NMColors.border,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }),
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

// ── Error banner ──────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: NMColors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: NMColors.red.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.error_outline, size: 15, color: NMColors.red),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: NMColors.red,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Terms checkbox ────────────────────────────────────────────────────────────
class _TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _TermsCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'I agree to the terms of service and privacy policy.',
            style: TextStyle(color: NMColors.muted, fontSize: 12, height: 1.5),
          ),
        ),
      ],
    );
  }
}

// ── Primary button ────────────────────────────────────────────────────────────
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
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: NMColors.green,
          disabledBackgroundColor: NMColors.green.withOpacity(0.5),
          foregroundColor: const Color(0xFF0A1A0C),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
      ),
    );
  }
}

// ── Divider ───────────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Row(
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
}

// ── Secondary button ──────────────────────────────────────────────────────────
class _SecondaryButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool dimmed;

  const _SecondaryButton({
    required this.onTap,
    required this.child,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: NMColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: dimmed ? NMColors.border : NMColors.border,
            width: 0.5,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ── Google icon ───────────────────────────────────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
}

// ── Guest icon ────────────────────────────────────────────────────────────────
class _GuestIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
}
