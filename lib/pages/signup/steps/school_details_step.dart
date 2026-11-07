import 'package:flutter/material.dart';

import '../signup_form_data.dart';
import '../widgets/form_fields.dart';

/// Step 2. Learners give their school, grade, class and (optionally) a sport.
/// Coaches give their school, coaching role and the team they run.
class SchoolDetailsStep extends StatelessWidget {
  const SchoolDetailsStep({super.key, required this.data});

  final SignupFormData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
          title: 'School details',
          subtitle:
              'Help us locate your institution so we can pair your account with the correct teams and leagues.',
        ),
        SignupTextField(
          label: 'School Name',
          hint: 'e.g. Greenwood High',
          controller: data.school,
          validator: requiredValidator,
        ),
        const SizedBox(height: 18),
        if (data.isCoach) ..._coachFields() else ..._learnerFields(),
      ],
    );
  }

  List<Widget> _learnerFields() => [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SignupDropdown<int>(
                label: 'Grade',
                hint: 'Select grade',
                items: List.generate(12, (i) => i + 1),
                itemLabel: (g) => 'Grade $g',
                value: data.grade,
                onChanged: (v) => data.grade = v,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SignupTextField(
                label: 'Class',
                hint: 'e.g. 10A',
                controller: data.className,
                validator: requiredValidator,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SignupTextField(
          label: 'Sport (optional)',
          hint: 'e.g. Football',
          controller: data.sport,
        ),
        const SizedBox(height: 18),
        SignupTextField(
          label: 'Team name (optional)',
          hint: 'e.g. Falcons',
          controller: data.teamName,
        ),
      ];

  List<Widget> _coachFields() => [
        SignupDropdown<String>(
          label: 'Your role',
          hint: 'Select your coaching role',
          items: [for (final c in coachingRoles) c.code],
          itemLabel: (code) => coachingRoles.firstWhere((c) => c.code == code).label,
          value: data.coachingRole,
          onChanged: (v) => data.coachingRole = v,
        ),
        const SizedBox(height: 18),
        SignupDropdown<String>(
          label: 'Coaching experience',
          hint: 'Select your experience',
          items: [for (final c in coachExperience) c.code],
          itemLabel: (code) => coachExperience.firstWhere((c) => c.code == code).label,
          value: data.experience,
          onChanged: (v) => data.experience = v,
        ),
        const SizedBox(height: 18),
        SignupTextField(
          label: 'Team name',
          hint: 'e.g. Basketball Boys',
          controller: data.teamName,
          validator: requiredValidator,
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SignupDropdown<String>(
                label: 'Team level',
                hint: 'Select level',
                items: [for (final c in teamLevels) c.code],
                itemLabel: (code) => teamLevels.firstWhere((c) => c.code == code).label,
                value: data.teamLevel,
                onChanged: (v) => data.teamLevel = v,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SignupTextField(
                label: 'Sport',
                hint: 'e.g. Basketball',
                controller: data.sport,
                validator: requiredValidator,
              ),
            ),
          ],
        ),
      ];
}
