import 'package:flutter/widgets.dart';

enum Gender { male, female }

/// Who is signing up. The backend has a separate sign-up for each.
enum AccountType { learner, coach }

/// A value the backend understands, with the words shown to the person.
class Choice {
  const Choice(this.code, this.label);

  final String code;
  final String label;
}

const coachingRoles = [
  Choice('head_coach', 'Head coach'),
  Choice('assistant_coach', 'Assistant coach'),
  Choice('fitness_coach', 'Fitness coach'),
  Choice('team_manager', 'Team manager'),
];

const coachExperience = [
  Choice('less_than_1_year', 'Less than 1 year'),
  Choice('1_3_years', '1 to 3 years'),
  Choice('3_5_years', '3 to 5 years'),
  Choice('5_10_years', '5 to 10 years'),
  Choice('10_plus_years', 'More than 10 years'),
];

const teamLevels = [
  Choice('u13', 'Under 13'),
  Choice('u14', 'Under 14'),
  Choice('u15', 'Under 15'),
  Choice('u16', 'Under 16'),
  Choice('u17', 'Under 17'),
  Choice('u19', 'Under 19'),
  Choice('1st_team', '1st team'),
  Choice('2nd_team', '2nd team'),
];

/// Values collected across every sign-up step. It lives for the whole flow,
/// so going Back keeps what the user already entered.
class SignupFormData extends ChangeNotifier {
  // Step 1: personal info
  AccountType accountType = AccountType.learner;
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  int? birthDay;
  int? birthMonth;
  int? birthYear;
  Gender gender = Gender.male;

  // Step 2: school (and, for coaches, their team)
  final school = TextEditingController();
  int? grade; // learners
  final className = TextEditingController(); // learners
  final sport = TextEditingController(); // optional for learners, required for coaches
  final teamName = TextEditingController(); // optional for learners, required for coaches
  String? coachingRole; // coaches: a code from [coachingRoles]
  String? experience; // coaches: a code from [coachExperience]
  String? teamLevel; // coaches: a code from [teamLevels]

  // Step 3: account setup
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  bool get isCoach => accountType == AccountType.coach;

  /// Applies [change] and rebuilds any listeners (radio buttons, checkboxes).
  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  /// `YYYY-MM-DD`, or null until day, month and year are all chosen.
  String? get dateOfBirth {
    final d = birthDay, m = birthMonth, y = birthYear;
    if (d == null || m == null || y == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${y.toString().padLeft(4, '0')}-${two(m)}-${two(d)}';
  }

  String get _gender => gender == Gender.female ? 'female' : 'male';

  /// The body for `POST /api/auth/register` (learners).
  Map<String, Object?> learnerPayload() {
    final sportName = sport.text.trim();
    final team = teamName.text.trim();
    return {
      'role': 'learner',
      'firstName': firstName.text.trim(),
      'lastName': lastName.text.trim(),
      'dateOfBirth': dateOfBirth,
      'gender': _gender,
      'school': {
        'name': school.text.trim(),
        'grade': grade,
        'className': className.text.trim(),
      },
      // The sport step is optional; the backend accepts null.
      'sport': sportName.isEmpty
          ? null
          : {'name': sportName, if (team.isNotEmpty) 'teamName': team},
      'email': email.text.trim(),
      'password': password.text,
    };
  }

  /// The body for `POST /api/auth/register/coach`.
  Map<String, Object?> coachPayload() => {
        'firstName': firstName.text.trim(),
        'lastName': lastName.text.trim(),
        'dateOfBirth': dateOfBirth,
        'gender': _gender,
        'school': school.text.trim(),
        'coachingRole': coachingRole,
        'experience': experience,
        'team': {
          'name': teamName.text.trim(),
          'level': teamLevel,
          'sport': sport.text.trim(),
        },
        'email': email.text.trim(),
        'password': password.text,
      };

  @override
  void dispose() {
    for (final controller in [
      firstName,
      lastName,
      school,
      className,
      sport,
      teamName,
      email,
      password,
      confirmPassword,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }
}
