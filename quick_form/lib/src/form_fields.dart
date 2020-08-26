import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quick_form/quick_form.dart';

/// Metadata to define a field
abstract class FieldBase<T> {
  /// Build a FieldSpec
  const FieldBase(
      {@required this.name, // Name of this field
      this.validators = const [], // A list of validators
      this.mandatory = false, // Is this field mandatory?
      // ignore: avoid_init_to_null
      this.initialValue = null, // Default Value
      this.label // Label to be displayed as hint
      });

  // The key of the field value in the result map
  String get valueKey => name;

  /// The name of this field
  final String name;

  /// The label for this field (name is default)
  final String label;

  /// Is the field Required
  final bool mandatory;

  /// The value of this field
  final T initialValue;

  /// The Validator for this field
  /// Null if OK
  /// Text if Error
  final List<Validator> validators;

  Widget buildWidget(QuickFormController controller);
}

class FieldText extends FieldBase<String> {
  const FieldText({
    @required String name, // Name of this field
    List<Validator> validators = const [], // A list of validators
    bool mandatory = false, // Is this field mandatory?
    String initialValue = '', // Default Value
    String label, // Label to be displayed as hint
    this.obscureText = false,
  }) : super(
            name: name,
            validators: validators,
            mandatory: mandatory,
            initialValue: initialValue,
            label: label);

  /// Should this field be masked if possible?
  final bool obscureText;

  @override
  Widget buildWidget(QuickFormController controller) => TextFormField(
      key: Key(name),
      obscureText: obscureText,
      onChanged: (value) => controller.onChange(name, value),
      onFieldSubmitted: (value) => controller.onSubmit(name),
      focusNode: controller.getFocusNode(name),
      controller: controller.getTextEditingController(name),
      decoration: InputDecoration(
          labelText: mandatory ? "* $label" : label,
          errorText: compositeValidator(validators, controller,
              controller.getTextEditingController(name).text)));
}

class FieldRadioButton extends FieldBase<String> {
  const FieldRadioButton({
    @required String name, // Name of radio button group
    @required this.value, // Value for this RadioButton
    String initialValue, // initial value for the group
    bool mandatory = false, // Is this field mandatory?
    String label, // Label to be displayed
    this.group,
  }) : super(
            name: name,
            validators: const [],
            mandatory: mandatory,
            initialValue: initialValue,
            label: label);

  @override
  String get valueKey => group;

  final String value;

  /// The group (for RadioGroups)
  final String group;

  @override
  // ignore: prefer_expression_function_bodies
  Widget buildWidget(QuickFormController controller) {
    return Radio<String>(
        key: Key(name),
        groupValue: controller.getValue(valueKey) as String,
        value: value,
        focusNode: controller.getFocusNode(name),
        onChanged: (value) => controller.onChange(valueKey, value));
  }
}

class FieldCheckbox extends FieldBase<bool> {
  const FieldCheckbox({
    @required String name, // Name of this field
    List<Validator> validators = const [], // A list of validators
    bool mandatory = false, // Is this field mandatory?
    bool initialValue = false, // Default Value
    String label, // Label to be displayed as hint
  }) : super(
            name: name,
            validators: validators,
            mandatory: mandatory,
            initialValue: initialValue,
            label: label);

  @override
  Widget buildWidget(QuickFormController controller) => Checkbox(
      key: Key(name),
      focusNode: controller.getFocusNode(name),
      value: controller.getValue(valueKey) as bool ?? false,
      onChanged: (value) => controller.onChange(valueKey, value));
}
