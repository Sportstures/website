import 'package:flutter/widgets.dart';

enum Gender { male, female }

/// Values collected across every sign-up step. It lives for the whole flow,
/// so going Back keeps what the user already entered.
class SignupFormData extends ChangeNotifier {
  // Step 1: personal info
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  int? birthDay;
  int? birthMonth;
  int? birthYear;
  Gender gender = Gender.male;
  bool registerAsSchool = false;

  // Step 2: school details
  String? school;
  String? province;
  final schoolCode = TextEditingController();
  String? role;

  // Step 3: account setup
  final email = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  /// Applies [change] and rebuilds any listeners (radio buttons, checkboxes).
  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final controller in [
      firstName,
      lastName,
      schoolCode,
      email,
      username,
      password,
      confirmPassword,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }
}
