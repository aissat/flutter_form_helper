import 'package:flutter_test/flutter_test.dart';
import 'package:quick_form/src/validators.dart';

/// Field Validator Tests
///
/// These validators don't need a `QuickFormController`,
/// hence the nulls
///
/// The controller is used when a Validator needs to access another field
/// these are all basic validations.

void main() {
  test("Test Length Validator", () async {
    expect((await const LengthValidator().validate(null, "Hello")).message,
        isNull);
    expect((await const LengthValidator().validate(null, "He")).message,
        isNotNull);
    expect(
        (await const LengthValidator(minLength: 10).validate(null, "Hello"))
            .message,
        isNotNull);
    expect(
        (await const LengthValidator(minLength: 10).validate(null, "HelloEllo"))
            .message,
        isNotNull);
    expect(
        (await const LengthValidator(minLength: 10)
                .validate(null, "HelloHello"))
            .message,
        isNull);
  });

  test("PatternValidator Test", () async {
    /// No space
    expect(
        (await PatternValidator.exclude(exclude: ' ').validate(null, "hello"))
            .message,
        isNull);

    /// No space
    expect(
        (await PatternValidator.exclude(exclude: ' ')
                .validate(null, "hello world"))
            .message,
        isNotNull);

    /// One space
    expect(
        (await PatternValidator(RegExp('[^ ]+ [^ ]'), 'Only one space allowed')
                .validate(null, "hello world"))
            .message,
        isNull);
  });

  test("Test Email Validator", () async {
    expect(
        (await PatternValidator.forEmail().validate(null, "not-a-email"))
            .message,
        isNotNull);
    expect(
        (await PatternValidator.forEmail().validate(null, "is@email.com"))
            .message,
        isNull);
  });

  test("Test Url Validator", () async {
    expect(
        (await PatternValidator.forUrl().validate(null, "not-a-url")).message,
        isNotNull);
    expect(
        (await PatternValidator.forUrl()
                .validate(null, "http://www.google.com"))
            .message,
        isNull);
    expect(
        (await PatternValidator.forUrl()
                .validate(null, "https://www.google.com"))
            .message,
        isNull);
  });
}
