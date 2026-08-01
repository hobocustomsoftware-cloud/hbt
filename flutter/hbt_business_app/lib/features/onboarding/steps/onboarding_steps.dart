import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../onboarding_data.dart';

/// Large-touch helper for wizard form fields (Myanmar-first labels).
InputDecoration _fieldDecoration(String label, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

// ── Step 1: Create Company ────────────────────────────────────────────
class CompanyNameStep extends StatefulWidget {
  const CompanyNameStep({super.key, required this.data, required this.isMy});

  final OnboardingData data;
  final bool isMy;

  @override
  State<CompanyNameStep> createState() => _CompanyNameStepState();
}

class _CompanyNameStepState extends State<CompanyNameStep> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.data.companyName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMy = widget.isMy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.business_center_outlined,
            size: 56, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          isMy ? 'ကုမ္ပဏီ အမည် ဖြည့်ပါ' : 'Company name',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          isMy ? 'ဥပမာ - မန္တလေးအမြန်၊ ဧရာဝတီခရီး' : 'e.g. Mandalay Express',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _controller,
          style: const TextStyle(fontSize: 17),
          decoration: _fieldDecoration(isMy ? 'ကုမ္ပဏီ အမည်' : 'Company name'),
          onChanged: (value) => widget.data.companyName = value,
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }
}

// ── Step 2: Company Information ───────────────────────────────────────
class CompanyInfoStep extends StatefulWidget {
  const CompanyInfoStep({super.key, required this.data, required this.isMy});

  final OnboardingData data;
  final bool isMy;

  @override
  State<CompanyInfoStep> createState() => _CompanyInfoStepState();
}

class _CompanyInfoStepState extends State<CompanyInfoStep> {
  late final TextEditingController _legal =
      TextEditingController(text: widget.data.legalName);
  late final TextEditingController _phone =
      TextEditingController(text: widget.data.phone);
  late final TextEditingController _email =
      TextEditingController(text: widget.data.email);

  @override
  void dispose() {
    _legal.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMy = widget.isMy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isMy ? 'တရားဝင် အချက်အလက်များ' : 'Legal details',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          isMy ? 'မဖြစ်မနေ မဟုတ်ပါ။ နောက်မှ ဖြည့်နိုင်ပါသည်။' : 'Optional — you can add these later.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _legal,
          style: const TextStyle(fontSize: 17),
          decoration: _fieldDecoration(isMy ? 'တရားဝင် အမည်' : 'Legal name'),
          onChanged: (value) => widget.data.legalName = value,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 17),
          decoration: _fieldDecoration(isMy ? 'ဖုန်းနံပါတ်' : 'Phone'),
          onChanged: (value) => widget.data.phone = value,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontSize: 17),
          decoration: _fieldDecoration(isMy ? 'အီးမေးလ်' : 'Email'),
          onChanged: (value) => widget.data.email = value,
        ),
      ],
    );
  }
}

// ── Step 3: Upload Logo ───────────────────────────────────────────────
class LogoStep extends StatefulWidget {
  const LogoStep({super.key, required this.data, required this.isMy});

  final OnboardingData data;
  final bool isMy;

  @override
  State<LogoStep> createState() => _LogoStepState();
}

class _LogoStepState extends State<LogoStep> {
  bool _busy = false;

  Future<void> _pick() async {
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          widget.data.logoPath = file.name;
          widget.data.logoBase64 = file.bytes != null
              ? base64Encode(file.bytes!)
              : null;
        });
      }
    } catch (_) {
      // File picker unavailable (web) — logo can be added later.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMy = widget.isMy;
    final hasLogo = widget.data.logoPath != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isMy ? 'သင့်ကုမ္ပဏီ၏ အမှတ်တံဆိပ်' : 'Your company brand',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          isMy
              ? 'လိုဂိုသည် လက်မှတ်၊ ပြေစာ၊ ဝက်ဘ်ဆိုက်အားလုံးတွင် ပါဝင်ပါမည်။'
              : 'Your logo appears on tickets, receipts, and the website.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        Center(
          child: InkWell(
            onTap: _busy ? null : _pick,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 2,
                ),
              ),
              child: hasLogo
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle,
                            size: 48, color: Colors.green),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            widget.data.logoPath!,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _busy ? Icons.hourglass_top : Icons.add_photo_alternate,
                          size: 56,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(isMy ? 'လိုဂို ရွေးရန်' : 'Choose logo'),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            isMy ? 'ကျော်သွားနိုင်သည်' : 'You can skip this',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

// ── Step 4: Business Type ─────────────────────────────────────────────
class BusinessTypeStep extends StatefulWidget {
  const BusinessTypeStep({super.key, required this.data, required this.isMy});

  final OnboardingData data;
  final bool isMy;

  @override
  State<BusinessTypeStep> createState() => _BusinessTypeStepState();
}

class _BusinessTypeStepState extends State<BusinessTypeStep> {
  static const _options = [
    ('bus_operator', 'ခရီးသည်တင် လုပ်ငန်း', 'Passenger bus operator'),
    ('bus_cargo', 'ခရီးသည် + ကုန်', 'Bus + cargo'),
    ('cargo_only', 'ကုန်တင် လုပ်ငန်း', 'Cargo / freight only'),
    ('mixed', 'ပေါင်းစပ်', 'Mixed transport'),
  ];

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final isMy = widget.isMy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isMy ? 'လုပ်ငန်း အမျိုးအစား ရွေးပါ' : 'Choose business type',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ..._options.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: data.businessType == option.$1
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => data.businessType = option.$1),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(
                        data.businessType == option.$1
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.$2,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              option.$3,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
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
          ),
        ),
      ],
    );
  }
}

// ── Step 5: Default Language (မြန်မာ default) ─────────────────────────
class LanguageStep extends StatefulWidget {
  const LanguageStep({super.key, required this.data});

  final OnboardingData data;

  @override
  State<LanguageStep> createState() => _LanguageStepState();
}

class _LanguageStepState extends State<LanguageStep> {
  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'မူရင်းဘာသာစကား ရွေးပါ',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'မြန်မာဘာသာကို မူရင်းအဖြစ် အသုံးပြုပါမည်။',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        _LanguageCard(
          value: 'my',
          label: 'မြန်မာ',
          note: 'Myanmar (default)',
          selected: data.defaultLanguage == 'my',
          onTap: () => setState(() => data.defaultLanguage = 'my'),
        ),
        const SizedBox(height: 12),
        _LanguageCard(
          value: 'en',
          label: 'English',
          note: 'English',
          selected: data.defaultLanguage == 'en',
          onTap: () => setState(() => data.defaultLanguage = 'en'),
        ),
      ],
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.value,
    required this.label,
    required this.note,
    required this.selected,
    required this.onTap,
  });

  final String value;
  final String label;
  final String note;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600)),
                    Text(note,
                        style: TextStyle(
                            fontSize: 13,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 6: Timezone ──────────────────────────────────────────────────
class TimezoneStep extends StatefulWidget {
  const TimezoneStep({super.key, required this.data, required this.isMy});

  final OnboardingData data;
  final bool isMy;

  @override
  State<TimezoneStep> createState() => _TimezoneStepState();
}

class _TimezoneStepState extends State<TimezoneStep> {
  static const _zones = [
    ('Asia/Yangon', 'မြန်မာ (Asia/Yangon)', 'Myanmar (Asia/Yangon)'),
    ('Asia/Bangkok', 'ထိုင်း (Asia/Bangkok)', 'Thailand (Asia/Bangkok)'),
    ('Asia/Singapore', 'စင်ကာပူ', 'Singapore'),
  ];

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final isMy = widget.isMy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isMy ? 'အချိန်ဇုန် ရွေးပါ' : 'Choose timezone',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ..._zones.map(
          (zone) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: data.timezone == zone.$1
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => data.timezone = zone.$1),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(
                        data.timezone == zone.$1
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        isMy ? zone.$2 : zone.$3,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Step 7: Currency (MMK default) ────────────────────────────────────
class CurrencyStep extends StatefulWidget {
  const CurrencyStep({super.key, required this.data, required this.isMy});

  final OnboardingData data;
  final bool isMy;

  @override
  State<CurrencyStep> createState() => _CurrencyStepState();
}

class _CurrencyStepState extends State<CurrencyStep> {
  static const _currencies = [
    ('MMK', 'ကျပ်', 'Myanmar Kyat'),
    ('USD', 'ဒေါ်လာ', 'US Dollar'),
    ('THB', 'ဘတ်', 'Thai Baht'),
  ];

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final isMy = widget.isMy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isMy ? 'ငွေကြေး ရွေးပါ' : 'Choose currency',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          isMy ? 'မူရင်းအားဖြင့် မြန်မာကျပ် (MMK)' : 'MMK by default',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        ..._currencies.map(
          (currency) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: data.currency == currency.$1
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => data.currency = currency.$1),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(
                        data.currency == currency.$1
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${currency.$1} — ${isMy ? currency.$2 : currency.$3}',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Step 8: Create Owner Account ──────────────────────────────────────
class OwnerAccountStep extends StatefulWidget {
  const OwnerAccountStep({super.key, required this.data, required this.isMy});

  final OnboardingData data;
  final bool isMy;

  @override
  State<OwnerAccountStep> createState() => _OwnerAccountStepState();
}

class _OwnerAccountStepState extends State<OwnerAccountStep> {
  late final TextEditingController _phone =
      TextEditingController(text: widget.data.ownerPhone);
  late final TextEditingController _password =
      TextEditingController(text: widget.data.ownerPassword);
  late final TextEditingController _first =
      TextEditingController(text: widget.data.ownerFirstName);
  late final TextEditingController _last =
      TextEditingController(text: widget.data.ownerLastName);

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMy = widget.isMy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isMy ? 'ပိုင်ရှင် အကောင့်' : 'Owner account',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          isMy
              ? 'ဤအကောင့်သည် ကုမ္ပဏီ၏ ပိုင်ရှင်အဖြစ် ပါဝင်မည်။'
              : 'This account becomes the company Owner.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 17),
          decoration: _fieldDecoration(
            isMy ? 'ဖုန်းနံပါတ် (မဖြစ်မနေ)' : 'Phone number (required)',
            hint: '+959…',
          ),
          onChanged: (value) => widget.data.ownerPhone = value,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _password,
          obscureText: true,
          style: const TextStyle(fontSize: 17),
          decoration: _fieldDecoration(
            isMy ? 'စကားဝှက် (အနည်းဆုံး ၈ လုံး)' : 'Password (min 8 chars)',
          ),
          onChanged: (value) => widget.data.ownerPassword = value,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _first,
                style: const TextStyle(fontSize: 17),
                decoration:
                    _fieldDecoration(isMy ? 'နာမည်' : 'First name'),
                onChanged: (value) => widget.data.ownerFirstName = value,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _last,
                style: const TextStyle(fontSize: 17),
                decoration: _fieldDecoration(isMy ? 'မျိုးရိုးနာမည်' : 'Last name'),
                onChanged: (value) => widget.data.ownerLastName = value,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// setState helper used by option cards — the option steps are StatefulWidgets
// and call setState directly; no extension needed.
