import 'package:flutter/material.dart';

import '../../shared/services/api_client.dart';
import '../auth/controllers/session_controller.dart';
import 'onboarding_data.dart';
import 'steps/onboarding_steps.dart';

/// First-run wizard: create a company + owner account.
///
/// Design rules: Myanmar-first, one-hand operation (content top, primary
/// button in thumb zone), large touch targets, high contrast, max 3 taps
/// per common operation. After the final step the owner is logged in
/// automatically and lands on the Owner dashboard.
class CompanyOnboardingScreen extends StatefulWidget {
  const CompanyOnboardingScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<CompanyOnboardingScreen> createState() => _CompanyOnboardingScreenState();
}

class _CompanyOnboardingScreenState extends State<CompanyOnboardingScreen> {
  final OnboardingData _data = OnboardingData();
  int _step = 0;
  bool _submitting = false;
  String? _error;

  static const int _totalSteps = 8;

  bool get _isLastStep => _step == _totalSteps - 1;

  Future<void> _next() async {
    // Validate current step before advancing.
    final valid = await _validateStep(_step);
    if (!valid) return;

    if (!_isLastStep) {
      setState(() => _step++);
      return;
    }
    await _submit();
  }

  Future<bool> _validateStep(int step) async {
    switch (step) {
      case 0:
        return _data.companyName.trim().isNotEmpty;
      case 7:
        return _data.ownerPhone.trim().isNotEmpty &&
            _data.ownerPassword.length >= 8;
      default:
        return true;
    }
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.session.api.post(
        '/onboarding/company/',
        {
          'company_name': _data.companyName.trim(),
          'legal_name': _data.legalName.trim(),
          'name_my': _data.companyName.trim(),
          'name_en': _data.companyName.trim(),
          // public_slug intentionally omitted: the backend auto-generates and
          // auto-uniquifies it from company_name.
          'primary_color': '#0B7A4B',
          'secondary_color': '#FFFFFF',
          'public_phone': _data.phone.trim(),
          'public_email': _data.email.trim(),
          'business_type': _data.businessType,
          'default_language': _data.defaultLanguage,
          'timezone': _data.timezone,
          'currency': _data.currency,
          'owner_phone': _data.ownerPhone.trim(),
          'owner_password': _data.ownerPassword,
          'owner_first_name': _data.ownerFirstName.trim(),
          'owner_last_name': _data.ownerLastName.trim(),
        },
      );
      if (!mounted) return;
      // Auto-login the new owner.
      await widget.session.signIn(
        phone: _data.ownerPhone.trim(),
        password: _data.ownerPassword,
      );
      if (!mounted) return;
      setState(() => _step = _totalSteps); // Done screen
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = _localizeError(error.message);
          _submitting = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = 'မအောင်မြင်ပါ။ ထပ်စမ်းကြည့်ပါ။';
          _submitting = false;
        });
      }
    }
  }

  /// Map common API errors to Myanmar (default locale).
  String _localizeError(String message) {
    if (message.contains('already exists')) {
      return 'ဖုန်းနံပါတ် သုံးပြီးသားဖြစ်နေပါသည်။ ဝင်ရောက်ကြည့်ပါ။';
    }
    if (message.contains('phone')) {
      return 'ဖုန်းနံပါတ် မှားနေပါသည်။ ပြန်စစ်ပါ။';
    }
    if (message.contains('password')) {
      return 'စကားဝှက် မမှန်ပါ။ ပြန်စစ်ပါ။';
    }
    return 'မအောင်မြင်ပါ။ ထပ်စမ်းကြည့်ပါ။ ($message)';
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    if (_step >= _totalSteps) {
      return _DoneScreen(onLogin: () {});
    }
    final step = onboardingSteps[_step];
    final isMy = _data.defaultLanguage == 'my';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'နောက်သို့',
          onPressed: _submitting ? null : _back,
        ),
        title: Text(isMy ? step.titleMy : step.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _StepIndicator(current: _step, total: _totalSteps),
            if (_error != null)
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.errorContainer,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _buildStepBody(step, isMy),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _submitting ? null : _next,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isMy
                              ? (_isLastStep ? 'အကောင့်ဖွင့်ပြီး ဝင်မည်' : 'ရှေ့ဆက်ရန်')
                              : (_isLastStep ? 'Create & Sign in' : 'Next'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBody(OnboardingStep step, bool isMy) {
    final data = _data;
    switch (_step) {
      case 0:
        return CompanyNameStep(data: data, isMy: isMy);
      case 1:
        return CompanyInfoStep(data: data, isMy: isMy);
      case 2:
        return LogoStep(data: data, isMy: isMy);
      case 3:
        return BusinessTypeStep(data: data, isMy: isMy);
      case 4:
        return LanguageStep(data: data);
      case 5:
        return TimezoneStep(data: data, isMy: isMy);
      case 6:
        return CurrencyStep(data: data, isMy: isMy);
      case 7:
        return OwnerAccountStep(data: data, isMy: isMy);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: List.generate(total, (i) {
          final done = i < current;
          final active = i == current;
          return Expanded(
            child: Container(
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: done
                    ? Theme.of(context).colorScheme.primary
                    : active
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DoneScreen extends StatelessWidget {
  const _DoneScreen({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 96, color: theme.colorScheme.primary),
                const SizedBox(height: 24),
                Text(
                  'ပြီးပါပြီ။', // Done
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'ကုမ္ပဏီနှင့် ပိုင်ရှင်အကောင့် ဖန်တီးပြီးပါပြီ။\nOwner Dashboard ကို ပို့ဆောင်ပေးပါမည်။',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () {
                      // The app root has already switched to the post-login
                      // home (session became authenticated); pop the wizard
                      // to reveal it.
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text(
                      'Owner Dashboard သို့ သွားရန်',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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
