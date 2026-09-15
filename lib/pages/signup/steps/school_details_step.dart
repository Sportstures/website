import 'package:flutter/material.dart';

import '../signup_form_data.dart';
import '../widgets/form_fields.dart';

class SchoolDetailsStep extends StatelessWidget {
  const SchoolDetailsStep({super.key, required this.data});

  final SignupFormData data;

  // TODO: load schools from the Node/JS backend instead of this placeholder list
  static const _schools = [
    'Greenwood Academy',
    'Hillcrest Secondary School',
    'Riverside High School',
    "St. Andrew's College",
  ];

  static const _provinces = [
    'Eastern Cape',
    'Free State',
    'Gauteng',
    'KwaZulu-Natal',
    'Limpopo',
    'Mpumalanga',
    'North West',
    'Northern Cape',
    'Western Cape',
  ];

  static const _roles = ['Coach', 'Teacher', 'Athlete', 'Parent', 'Administrator'];

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
        SignupDropdown<String>(
          label: 'School Name',
          hint: 'Select your school',
          items: _schools,
          value: data.school,
          onChanged: (v) => data.school = v,
        ),
        const SizedBox(height: 18),
        SignupDropdown<String>(
          label: 'Province / Region',
          hint: 'Select your province',
          items: _provinces,
          value: data.province,
          onChanged: (v) => data.province = v,
        ),
        const SizedBox(height: 18),
        SignupTextField(
          label: 'School Code (provided by your coach)',
          hint: 'e.g. GRW-2024',
          controller: data.schoolCode,
          validator: requiredValidator,
        ),
        const SizedBox(height: 18),
        SignupDropdown<String>(
          label: 'Role at School',
          hint: 'Select your role',
          items: _roles,
          value: data.role,
          onChanged: (v) => data.role = v,
        ),
      ],
    );
  }
}
