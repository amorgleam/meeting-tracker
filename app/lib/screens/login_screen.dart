import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/institutional_theme.dart';
import '../state/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final err = await context.read<AppState>().signIn(
          _identifierController.text,
          _passwordController.text,
        );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstitutionalTheme.creamBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            decoration: BoxDecoration(
              color: InstitutionalTheme.creamCard,
              border: Border.all(color: InstitutionalTheme.primaryNavy, width: 1.5),
              borderRadius: BorderRadius.circular(3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Formal Institutional Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                  decoration: const BoxDecoration(
                    color: InstitutionalTheme.primaryNavy,
                    border: Border(
                      bottom: BorderSide(color: InstitutionalTheme.goldAccent, width: 3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0x22B8923A),
                          border: Border.all(color: InstitutionalTheme.goldAccent, width: 1.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Icon(
                          Icons.account_balance,
                          color: InstitutionalTheme.goldAccent,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'MEETING TRACKER',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          color: InstitutionalTheme.creamBackground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Office of the Secretariat • Institutional Access Portal',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: InstitutionalTheme.goldLight,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'SIGN IN TO YOUR ACCOUNT',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                          color: InstitutionalTheme.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Enter your Admin-issued institutional email or username and password to access the ledger.',
                        style: TextStyle(fontSize: 12, color: InstitutionalTheme.textMuted),
                      ),
                      const SizedBox(height: 20),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: InstitutionalTheme.bgEliminated,
                            border: Border.all(color: InstitutionalTheme.statusEliminated),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: InstitutionalTheme.statusEliminated, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: InstitutionalTheme.statusEliminated,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      TextField(
                        controller: _identifierController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email / Username *',
                          hintText: 'e.g. member@institution.gov',
                          prefixIcon: Icon(Icons.person_outline, size: 18),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submitLogin(),
                        decoration: InputDecoration(
                          labelText: 'Password *',
                          prefixIcon: const Icon(Icons.lock_outline, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 18,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitLogin,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.login, size: 18),
                          label: Text(
                            _isSubmitting ? 'VERIFYING CREDENTIALS...' : 'SIGN IN TO DOCKET',
                            style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.7),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: InstitutionalTheme.creamSurface,
                          border: Border.all(color: InstitutionalTheme.borderLedger),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text(
                          'Credentials are provisioned and managed exclusively by the Institutional Administrator.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: InstitutionalTheme.textMuted),
                        ),
                      ),
                    ],
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
