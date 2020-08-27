import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_form/quick_form.dart';

void main() {
  test("Basic Form Helper Test", () {
    Map<String, FieldValue> results;
    QuickFormController(
        fields: [const FieldText(name: "test")],
        onSubmitted: (map) => results = map)
      ..onChange("test", "value")
      ..submitForm();

    expect(results, isNotNull);
    expect(results["test"].value, equals("value"));
  });

  test("Basic Form Helper Test with LengthValidator", () {
    /// Test Validation Fail
    Map<String, FieldValue> results;
    QuickFormController(fields: [
      const FieldText(name: "test", validators: [lengthValidator])
    ], onSubmitted: (map) => results = map)
      ..onChange("test", "va")
      ..submitForm();

    expect(results, isNull);

    /// Test validation Pass
    QuickFormController(fields: [
      const FieldText(name: "test", validators: [lengthValidator])
    ], onSubmitted: (map) => results = map)
      ..onChange("test", "value")
      ..submitForm();

    //Try again with a correct length, expect callback to work
    expect(results, isNotNull);
    expect(results["test"].value, equals("value"));
  });

  testWidgets("Integration Test of the Flutter Form", (tester) async {
    Map<String, FieldValue> onSubmittedMap;
    await tester.pumpWidget(
      MaterialApp(
        home: QuickForm(
          formFields: sampleForm,
          onFormSubmitted: (map) => onSubmittedMap = map,
        ),
      ),
    );

    expect(find.text("Title"), findsOneWidget);
    expect(find.text("Url"), findsOneWidget);
    expect(find.byKey(const ValueKey("age")), findsOneWidget);

    await tester.tap(find.byKey(const Key("title")));
    await tester.enterText(find.byKey(const Key("title")), "Test Title");
    await tester.testTextInput.receiveAction(TextInputAction.done);

    await tester.tap(find.byKey(const Key("age")));
    await tester.enterText(find.byKey(const Key("age")), "34");
    await tester.testTextInput.receiveAction(TextInputAction.done);

    await tester.tap(find.byKey(const Key("submit")));
    expect(onSubmittedMap["age"].value, equals("34"));
    expect(onSubmittedMap["title"].value, equals("Test Title"));
  });
}

/// This is the Sample Form used on the main() page
const sampleForm = <FieldBase>[
  FieldText(
      name: "name",
      label: "Name",
      mandatory: true,
      validators: [lengthValidator]),
  FieldText(name: "title", label: "Title", mandatory: false),
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
    initialValue: true,
  )
];
