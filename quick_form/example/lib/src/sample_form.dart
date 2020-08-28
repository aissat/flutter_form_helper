import 'package:quick_form/quick_form.dart';

/// This is the Sample Form used on the main() page
final sampleForm = <FieldBase>[
  FieldText(name: "name", label: "Name", mandatory: true, validators: [
    const LengthValidator(stopValidating: false),
    PatternValidator.exclude(exclude: 'i')
  ]),
  const FieldText(name: "title", label: "Title", mandatory: false),
  const FieldText(
      name: "password", label: "Password", mandatory: false, obscureText: true),
  const FieldText(
      name: "repeat_password",
      label: "Repeat Password",
      //validators: [repeatPasswordValidator],
      mandatory: false,
      obscureText: true),
  FieldText(
      name: "email",
      label: "Email",
      mandatory: false,
      validators: [PatternValidator.forEmail()]),
  FieldText(
      name: "url",
      label: "Url",
      mandatory: false,
      validators: [PatternValidator.forUrl()]),
  const FieldText(name: "age", label: "Age", mandatory: true, validators: []),
  const FieldSpacer(),
  const FieldRadioButton(
    initialValue: 'He',
    name: "radio1",
    group: "Pronoun",
    value: "He",
    label: "He",
  ),
  const FieldRadioButton(
    name: "radio2",
    group: "Pronoun",
    value: "She",
    label: "She",
  ),
  const FieldRadioButton(
    name: "radio3",
    group: "Pronoun",
    value: "Unspecified",
    label: "Unspecified",
  ),
  const FieldCheckbox(
    name: "checkbox",
    initialValue: true,
  )
];

/// Validator for repeat_password
/// Checks to see if it matches "password"
String repeatPasswordValidator(QuickFormController helper, String input,
    {String defaultOutput}) {
  final password = helper.getRawValue("password");
  if (password != input) {
    return "Password do not match";
  } else {
    return defaultOutput;
  }
}
