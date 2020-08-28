import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_form/quick_form.dart';

void main() {
  test("Basic Form Helper Test", () async {
    Map<String, FieldValue> results;
    final controller = QuickFormController(
        fields: [const FieldText(name: "test")],
        onSubmitted: (map) => results = map)
      ..onChange("test", "value");
    await controller.submitForm();

    expect(results, isNotNull);
    expect(results["test"].value, equals("value"));
  });

  test("Basic Form Helper Test with LengthValidator", () async {
    /// Test Validation Fail
    Map<String, FieldValue> results;
    final controller = QuickFormController(fields: [
      const FieldText(name: "test", validators: [LengthValidator()])
    ], onSubmitted: (map) => results = map)
      ..onChange("test", "va");
    await controller.submitForm();

    expect(results, isNull);

    /// Test validation Pass
    final controller2 = QuickFormController(fields: [
      const FieldText(name: "test", validators: [LengthValidator()])
    ], onSubmitted: (map) => results = map)
      ..onChange("test", "value");
    await controller2.submitForm();

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

    await tester.tap(find.byKey(const Key("name")));
    await tester.enterText(find.byKey(const Key("name")), "Joe");
    await tester.testTextInput.receiveAction(TextInputAction.done);

    await tester.tap(find.byKey(const Key("email")));
    await tester.enterText(find.byKey(const Key("email")), "Joe@x.de");
    await tester.testTextInput.receiveAction(TextInputAction.done);

    await tester.tap(find.byKey(const Key("submit")));

    await tester.pump();
    expect(onSubmittedMap["age"]?.value, equals("34"));
    expect(onSubmittedMap["title"]?.value, equals("Test Title"));
  });
}

/// This is the Sample Form used on the main() page
final sampleForm = <FieldBase>[
  const FieldText(
      name: "name",
      label: "Name",
      mandatory: true,
      validators: [LengthValidator()]),
  const FieldText(name: "title", label: "Title", mandatory: false),
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
  const FieldRadioButton(
    name: "radio1",
    group: "Pronoun",
    value: "He",
  ),
  const FieldRadioButton(
    name: "radio2",
    group: "Pronoun",
    value: "She",
  ),
  const FieldRadioButton(
    name: "radio3",
    group: "Pronoun",
    value: "Unspecified",
  ),
  const FieldCheckbox(
    name: "checkbox",
    initialValue: true,
  )
];
