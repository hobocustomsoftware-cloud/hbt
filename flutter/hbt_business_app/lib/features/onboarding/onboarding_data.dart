import 'package:flutter/material.dart';

/// Onboarding flow state (single shared model across wizard steps).
class OnboardingData {
  OnboardingData();

  // Step 1 — Create Company
  String companyName = '';

  // Step 2 — Company Information
  String legalName = '';
  String phone = '';
  String email = '';
  String address = '';

  // Step 3 — Upload Logo (path for display; sent to API as base64 later)
  String? logoPath;
  String? logoBase64;

  // Step 4 — Business Type
  String businessType = 'bus_operator';

  // Step 5 — Default Language
  String defaultLanguage = 'my';

  // Step 6 — Timezone
  String timezone = 'Asia/Yangon';

  // Step 7 — Currency
  String currency = 'MMK';

  // Step 8 — Create Owner Account
  String ownerPhone = '';
  String ownerPassword = '';
  String ownerFirstName = '';
  String ownerLastName = '';
}

/// Shared step model for the wizard.
class OnboardingStep {
  const OnboardingStep({
    required this.title,
    required this.titleMy,
    required this.subtitle,
    required this.subtitleMy,
    required this.icon,
  });

  final String title;
  final String titleMy;
  final String subtitle;
  final String subtitleMy;
  final IconData icon;
}

const List<OnboardingStep> onboardingSteps = [
  OnboardingStep(
    title: 'Create Company',
    titleMy: 'ကုမ္ပဏီ ဖန်တီးရန်',
    subtitle: 'Start your transport company',
    subtitleMy: 'သင့်ရဲ့ သယ်ယူပို့ဆောင်ရေး ကုမ္ပဏီကို စတင်ပါ',
    icon: Icons.business_center_outlined,
  ),
  OnboardingStep(
    title: 'Company Information',
    titleMy: 'ကုမ္ပဏီ အချက်အလက်',
    subtitle: 'Legal details',
    subtitleMy: 'တရားဝင် အချက်အလက်များ',
    icon: Icons.fact_check_outlined,
  ),
  OnboardingStep(
    title: 'Upload Logo',
    titleMy: 'လိုဂို တင်ရန်',
    subtitle: 'Your company brand',
    subtitleMy: 'သင့်ကုမ္ပဏီ၏ အမှတ်တံဆိပ်',
    icon: Icons.image_outlined,
  ),
  OnboardingStep(
    title: 'Business Type',
    titleMy: 'လုပ်ငန်းအမျိုးအစား',
    subtitle: 'What do you operate?',
    subtitleMy: 'ဘာလုပ်ငန်း လုပ်ဆောင်မှာလဲ',
    icon: Icons.category_outlined,
  ),
  OnboardingStep(
    title: 'Default Language',
    titleMy: 'မူရင်းဘာသာစကား',
    subtitle: 'မြန်မာ by default',
    subtitleMy: 'မူရင်းအားဖြင့် မြန်မာ',
    icon: Icons.language,
  ),
  OnboardingStep(
    title: 'Timezone',
    titleMy: 'အချိန်ဇုန်',
    subtitle: 'Local time zone',
    subtitleMy: 'ဒေသစံတော်ချိန်',
    icon: Icons.schedule_outlined,
  ),
  OnboardingStep(
    title: 'Currency',
    titleMy: 'ငွေကြေး',
    subtitle: 'MMK by default',
    subtitleMy: 'မူရင်းအားဖြင့် ကျပ်',
    icon: Icons.payments_outlined,
  ),
  OnboardingStep(
    title: 'Create Owner Account',
    titleMy: 'ပိုင်ရှင်အကောင့် ဖန်တီးရန်',
    subtitle: 'You will be the Owner',
    subtitleMy: 'သင်သည် ပိုင်ရှင် ဖြစ်လာမည်',
    icon: Icons.person_outline,
  ),
];
