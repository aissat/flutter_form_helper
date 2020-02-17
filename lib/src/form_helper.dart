import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../form_helper.dart';
import 'validators.dart';

/// Specifies the behavior of a field
class FieldSpec {
  /// Build a FieldSpec
  const FieldSpec(
      {@required this.name,
      @required this.validators,
      this.mandatory = false,
      this.label});

  /// The name of this field
  final String name;

  /// The label for this field (name is default)
  final String label;

  /// Is the field Required
  final bool mandatory;

  /// The Validator for this field
  /// Null if OK
  /// Text if Error
  final List<validator> validators;
}

/// Specifies a Form
class FormHelper extends ChangeNotifier {
  /// Construct a FormHelper
  factory FormHelper(List<FieldSpec> spec) => FormHelper._(
      controllers: spec.fold(
          <String, TextEditingController>{},
          (p, v) => <String, TextEditingController>{}
            ..addAll(p)
            ..putIfAbsent(v.name, () => TextEditingController())),
      focusNodes: spec.fold(
          <String, FocusNode>{},
          (p, v) => <String, FocusNode>{}
            ..addAll(p)
            ..putIfAbsent(v.name, () => FocusNode())),
      fields: spec);

  /// Private Constructor - Init from Factory
  FormHelper._(
      {@required this.fields,
      @required this.controllers,
      @required this.focusNodes});

  /// All the fields
  final List<FieldSpec> fields;

  /// All the controllers
  final Map<String, TextEditingController> controllers;

  /// All the focus nodes
  final Map<String, FocusNode> focusNodes;

  /// All the values
  final Map<String, String> values = {};

  /// Gets a field spec
  FieldSpec _getFieldSpec(String name) =>
      fields.firstWhere((element) => element.name == name);

  /// Gets a field spec
  int _getFieldSpecIndex(FieldSpec fieldSpec) => fields.indexOf(fieldSpec);

  /// Get a focus node for a named field
  FocusNode _getFocusNode(String name) => focusNodes[name];

  /// Get a text editting controller for a name
  TextEditingController _getTextEditingController(String name) =>
      controllers[name];

  int submissions = 0;

  String _getText(String name) => _getTextEditingController(name).text;

  /// A count of validation errors
  int get validationErrors => fields.fold(
      0,
      (sum, field) =>
          compositeValidator(field.validators, _getText(field.name)) == null
              ? sum
              : sum + 1);

  /// A count of how many fields are still required              
  int get stillRequired => fields.fold(
      0,
      (sum, field) => field.mandatory
          ? _getTextEditingController(field.name).text.isEmpty ? sum + 1 : sum
          : sum);

  String get submissionButtonText {
    if (stillRequired > 0) {
      return "$stillRequired fields remaining";
    }

    if (validationErrors > 0) {
      return "$validationErrors field doesn't validate";
    }
    return "Submit Form";
  }

  void _focusOnFirstRemaining() {
    final field = fields.firstWhere((field)=>field.mandatory && _getText(field.name).isEmpty);
    if (field != null) {
      _getFocusNode(field.name).requestFocus();
    }
  }

  @override
  void dispose() {
    this
      ..controllers.forEach((key, value) => value.dispose())
      ..focusNodes.forEach((key, value) => value.dispose());
    super.dispose();
  }

  /// Dispose this form

  void _onChange(String name, String value) {
    values[name] = value;
    notifyListeners();
  }

  /// Gets a list of TextFields for this form
  List<Widget> getTextFields() => fields
      .map((fs) => FormHelperTextField._(formHelper: this, name: fs.name))
      .toList();

  /// Build the form
  Widget buildForm({FormUiBuilder builder = scrollableSimpleForm}) =>
      builder(this, _buildWidgets());

  void _onSubmit(String name) {
    final idx = _getFieldSpecIndex(_getFieldSpec(name));
    if (idx + 1 < fields.length) {
      final nextField = fields[idx + 1];
      _getFocusNode(nextField.name).requestFocus();
    } else {
      _getFocusNode(name).unfocus();
    }
  }

  /// Called when the form is submitted
  void onFormSubmit() {
    if (stillRequired > 0) {
      _focusOnFirstRemaining();
    }
    notifyListeners();
  }

  Map<String, Widget> _buildWidgets() => fields.fold(
      Map<String, Widget>(),
      (map, field) => <String, Widget>{
            field.name:
                FormHelperTextField._(formHelper: this, name: field.name)
          }..addAll(map));
}

typedef FormUiBuilder = Widget Function(
    FormHelper helper, Map<String, Widget> widgets);

/// A TextFormField, but with FormHelper bindings
class FormHelperTextField extends StatelessWidget {
  /// Construct a text form helper
  const FormHelperTextField._(
      {@required this.formHelper, @required this.name, Key key})
      : super(key: key);

  /// The Form Helper
  final FormHelper formHelper;

  /// The name of the field
  final String name;

  @override
  Widget build(BuildContext context) {
    final fieldSpec = formHelper._getFieldSpec(name);
    final label = fieldSpec.label ?? name;

    return TextFormField(
        onChanged: (value) => formHelper._onChange(name, value),
        onFieldSubmitted: (value) => formHelper._onSubmit(name),
        focusNode: formHelper._getFocusNode(name),
        controller: formHelper._getTextEditingController(name),
        decoration: InputDecoration(
            labelText: fieldSpec.mandatory ? "* $label" : label,
            errorText: compositeValidator(fieldSpec.validators,
                formHelper._getTextEditingController(name).text)));
  }
}
