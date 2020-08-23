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
      this.value = null, // Default Value
      this.label // Label to be displayed as hint
      });

  /// The name of this field
  final String name;

  /// The label for this field (name is default)
  final String label;

  /// Is the field Required
  final bool mandatory;

  /// The value of this field
  final T value;

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
    String value = '', // Default Value
    String label, // Label to be displayed as hint
    this.obscureText = false,
  }) : super(
            name: name,
            validators: validators,
            mandatory: mandatory,
            value: value,
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
  /// The group (for RadioGroups)
  final String group;

  const FieldRadioButton({
    @required String name, // Name of this field
    List<Validator> validators = const [], // A list of validators
    bool mandatory = false, // Is this field mandatory?
    String value = '', // Default Value
    String label, // Label to be displayed as hint
    this.group,
  }) : super(
            name: name,
            validators: validators,
            mandatory: mandatory,
            value: value,
            label: label);

  @override
  Widget buildWidget(QuickFormController controller) => Radio<String>(
      key: Key(name),
      groupValue: value,
      value: controller.getValue(name),
      focusNode: controller.getFocusNode(name),
      onChanged: (value) => controller.applyRadioValue(
          name, controller.getFieldSpec(name).value as String));
}

class FieldCheckbox extends FieldBase<String> {
  /// The group (for RadioGroups)
  final String group;

  const FieldCheckbox({
    @required String name, // Name of this field
    List<Validator> validators = const [], // A list of validators
    bool mandatory = false, // Is this field mandatory?
    String value = '', // Default Value
    String label, // Label to be displayed as hint
    this.group,
  }) : super(
            name: name,
            validators: validators,
            mandatory: mandatory,
            value: value,
            label: label);

  @override
  Widget buildWidget(QuickFormController controller) => Checkbox(
      key: Key(name),
      focusNode: controller.getFocusNode(name),
      value: controller.isChecked(name),
      onChanged: (value) => controller.toggleCheckbox(name));
}
