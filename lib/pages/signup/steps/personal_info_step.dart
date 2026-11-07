import 'package:flutter/material.dart';

import '../../../widgets/site/site_routes.dart';
import '../signup_form_data.dart';
import '../../../theme/app_colors.dart';
import '../widgets/form_fields.dart';

class PersonalInfoStep extends StatelessWidget {
  const PersonalInfoStep({super.key, required this.data});

  final SignupFormData data;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String? _validateDay(int? day) {
    if (day == null) return 'Required';
    final month = data.birthMonth;
    final year = data.birthYear;
    if (month != null && year != null && day > DateUtils.getDaysInMonth(year, month)) {
      return 'Invalid date';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
          title: 'Create an account',
          subtitle:
              "Join your school's sporting community and connect, compete, and keep track of every match.",
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SignupTextField(
                label: 'First Name',
                hint: 'e.g. John',
                controller: data.firstName,
                autofillHints: const [AutofillHints.givenName],
                validator: requiredValidator,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SignupTextField(
                label: 'Last Name',
                hint: 'e.g. Doe',
                controller: data.lastName,
                autofillHints: const [AutofillHints.familyName],
                validator: requiredValidator,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const FieldLabel('Date of Birth'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SignupDropdown<int>(
                hint: 'Day',
                items: List.generate(31, (i) => i + 1),
                value: data.birthDay,
                onChanged: (v) => data.birthDay = v,
                validator: _validateDay,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SignupDropdown<int>(
                hint: 'Month',
                items: List.generate(12, (i) => i + 1),
                itemLabel: (m) => _months[m - 1],
                value: data.birthMonth,
                onChanged: (v) => data.birthMonth = v,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SignupDropdown<int>(
                hint: 'Year',
                items: [for (var y = currentYear - 5; y >= currentYear - 80; y--) y],
                value: data.birthYear,
                onChanged: (v) => data.birthYear = v,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const FieldLabel('Gender'),
        ListenableBuilder(
          listenable: data,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioGroup<Gender>(
                groupValue: data.gender,
                onChanged: (g) => data.update(() => data.gender = g!),
                child: Row(
                  children: [
                    _genderOption(Gender.male, 'Male'),
                    const SizedBox(width: 24),
                    _genderOption(Gender.female, 'Female'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const FieldLabel('I am signing up as'),
              RadioGroup<AccountType>(
                groupValue: data.accountType,
                onChanged: (t) => data.update(() => data.accountType = t!),
                child: Row(
                  children: [
                    _typeOption(AccountType.learner, 'Learner'),
                    const SizedBox(width: 24),
                    _typeOption(AccountType.coach, 'Coach'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _schoolLink(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _genderOption(Gender gender, String label) {
    return GestureDetector(
      onTap: () => data.update(() => data.gender = gender),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<Gender>(
            value: gender,
            activeColor: AppColors.orange,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.ink)),
        ],
      ),
    );
  }

  Widget _typeOption(AccountType type, String label) {
    return GestureDetector(
      onTap: () => data.update(() => data.accountType = type),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<AccountType>(
            value: type,
            activeColor: AppColors.orange,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.ink)),
        ],
      ),
    );
  }

  /// Registering a whole school is a different flow from creating a personal account.
  Widget _schoolLink(BuildContext context) {
    return Wrap(
      children: [
        const Text(
          'Registering a whole school? ',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => openSiteRoute(context, SiteRoutes.forSchools),
            child: const Text(
              'See how it works',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.orange),
            ),
          ),
        ),
      ],
    );
  }
}
