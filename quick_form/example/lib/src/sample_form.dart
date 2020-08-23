import 'package:quick_form/quick_form.dart';

/// This is the Sample Form used on the main() page
const sampleForm = <FieldBase>[
  FieldText(
      name: "name",
      label: "Name",
      mandatory: true,
      validators: [lengthValidator]),
  FieldText(name: "title", label: "Title", mandatory: false),
  FieldText(
      name: "password", label: "Password", mandatory: false, obscureText: true),
  FieldText(
      name: "repeat_password",
      label: "Repeat Password",
      validators: [repeatPasswordValidator],
      mandatory: false,
      obscureText: true),
  FieldText(
      name: "email",
      label: "Email",
      mandatory: false,
      validators: [emailValidator]),
  FieldText(
      name: "url", label: "Url", mandatory: false, validators: [urlValidator]),
  FieldText(
      name: "age", label: "Age", mandatory: true, validators: [intValidator]),
  FieldRadioButton(
    name: "radio1",
    group: "Pronoun",
    value: "He",
  ),
  FieldRadioButton(
    name: "radio2",
    group: "Pronoun",
    value: "She",
  ),
  FieldRadioButton(
    name: "radio3",
    group: "Pronoun",
    value: "Unspecified",
  ),
  FieldCheckbox(
    name: "checkbox",
    value: "checked",
  )
];

/// Validator for repeat_password
/// Checks to see if it matches "password"
String repeatPasswordValidator(QuickFormController helper, String input,
    {String defaultOutput}) {
  final password = helper.getValue("password");
  if (password != input) {
    return "Password do not match";
  } else {
    return defaultOutput;
  }
}
