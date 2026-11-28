import 'package:flutter_test/flutter_test.dart';
import 'package:website/pages/signup/steps/account_setup_step.dart';

/// The sign-up password check must match the backend: 8 to 72 characters, a letter and a number.
void main() {
  String? problem(String v) => AccountSetupStep.passwordProblem(v);

  test('accepts any letter with any number', () {
    expect(problem('Sipho2026'), isNull);
    expect(problem('DemoPass1'), isNull);
    expect(problem('abcxyz99'), isNull);
  });

  test('refuses a password without a number, even with the letter d', () {
    expect(problem('Password'), 'Use at least one letter and one number');
    expect(problem('abcddddd'), 'Use at least one letter and one number');
  });

  test('refuses a password without a letter, or of the wrong length', () {
    expect(problem('12345678'), 'Use at least one letter and one number');
    expect(problem('Ab1'), 'Password must be at least 8 characters');
    expect(problem('a1' * 37), 'Password must be 72 characters or fewer');
  });
}
