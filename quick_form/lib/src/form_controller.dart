import 'package:flutter/material.dart';

import '../quick_form.dart';

/// Specifies a Form
class QuickFormController extends ChangeNotifier {
  /// Construct a FormHelper
  QuickFormController(
      {@required this.fields,
      this.onChanged,
      this.onSubmitted,
      this.allowWithErrors = false}) {
    for (final field in fields) {
      /// as radio buttons share a single valuefield we have to
      /// ensure only to create one field for a given valueKey therefore the
      /// ??=
      values[field.valueKey] ??= _FieldValue(
          initialValue: field.initialValue, isMandatory: field.mandatory);
      if (field is FieldText) {
        assert(!controllers.containsKey(field.name));
        controllers[field.name] =
            TextEditingController(text: field.initialValue);
      }
      final node = FocusNode();
      if (field.validateOnLostFocus) {
        node.addListener(() => onFocusNodeChange(field.name, node));
      }
      focusNodes[field.name] = node;
    }
  }

  /// Called when the form is changed
  final FormResultsCallback onChanged;

  /// Called when the form is submitted
  final FormResultsCallback onSubmitted;

  /// Allow callbacks when there is errors present
  /// (missing fields or validation errors)
  final bool allowWithErrors;

  /// All the fields
  final List<FieldBase> fields;

  /// All the controllers
  final Map<String, TextEditingController> controllers = {};

  /// All the focus nodes
  final Map<String, FocusNode> focusNodes = {};

  /// All the values
  final Map<String, _FieldValue> values = {};

  /// A count of validation errors
  int get validationErrors => fields.fold(
      0,
      (sum, field) => compositeValidator(
                  field.validators, this, getValue(field.valueKey)) ==
              null
          ? sum
          : sum + 1);

  /// A count of how many fields are still required
  int get stillRequired => fields.fold(
      0,
      (sum, field) => field.mandatory
          ? values[field.name]?.isEmpty ?? false ? sum + 1 : sum
          : sum);

  /// Returns auto-generated submission button text
  /// It'll indicate errors with the form
  String get submissionButtonText {
    if (stillRequired > 0) {
      return "$stillRequired fields remaining";
    }

    if (validationErrors > 0) {
      return "$validationErrors field doesn't validate";
    }
    return "Submit Form";
  }

  /// Dispose this form
  @override
  void dispose() {
    this
      ..controllers.forEach((key, value) => value.dispose())
      ..focusNodes.forEach((key, value) => value.dispose());
    super.dispose();
  }

  /// Build the form
  Widget buildForm(BuildContext context,
          {FormUiBuilder builder = scrollableSimpleForm}) =>
      builder(this, context);

  /// Get's the Widget for a name
  /// "submit" is a special case
  Widget getWidget(String name) {
    if (name == "submit") {
      return RaisedButton(
          key: const Key("submit"),
          onPressed: submitForm,
          child: Text(submissionButtonText));
    }

    return getFieldSpec(name).buildWidget(this);
  }

  /// Call this when you want to "Submit" the form
  ///
  /// It'll redirect you to required fields or to fix errors
  /// before submitting
  void submitForm() {
    if (allowWithErrors && onSubmitted != null) {
      onSubmitted(values);
      return;
    }

    if (stillRequired > 0) {
      _focusOnFirstRemaining();
      return;
    }
    if (validationErrors > 0) {
      _focusOnFirstError();
      return;
    }

    if (onSubmitted != null) {
      onSubmitted(values);
    }
    notifyListeners();
  }

  void onFocusNodeChange(String fieldName, FocusNode node) {
    if (!node.hasFocus) {
      if (!validateField(fieldName)) {
        values[fieldName].validateOnEachChange = true;
      }
    }
  }

  bool validateField(String fieldName) {
    final valueField = values[fieldName];
    final spec = getFieldSpec(fieldName);
    valueField.errorMessage =
        compositeValidator(spec.validators, this, valueField._rawValue);
    notifyListeners();
    return valueField.errorMessage == null;
  }

  /// Focus on the first remaining mandatory field
  /// Used when user taps "submit" without completing the form
  void _focusOnFirstRemaining() {
    final field = fields.firstWhere(
        (field) => field.mandatory && (values[field.name]?.isEmpty ?? true));
    if (field != null) {
      getFocusNode(field.name).requestFocus();
    }
  }

  /// Focus on the first error in the form
  /// Used when user taps "submit" with errors detected in input
  void _focusOnFirstError() {
    final field = fields.firstWhere((field) =>
        compositeValidator(field.validators, this, getValue(field.name)) !=
        null);
    if (field != null) {
      getFocusNode(field.name).requestFocus();
    }
  }

  /// Gets a field spec
  FieldBase getFieldSpec(String name) =>
      fields.firstWhere((element) => element.name == name);

  /// Gets a field spec
  int _getFieldSpecIndex(FieldBase fieldSpec) => fields.indexOf(fieldSpec);

  /// Get a focus node for a named field
  FocusNode getFocusNode(String name) => focusNodes[name];

  String getValidationError(String valueKey) => values[valueKey]?.errorMessage;

  /// Get a text editting controller for a name
  TextEditingController getTextEditingController(String name) =>
      controllers[name];

  /// Called every time a value is changed
  void onChange(String name, Object value) {
    final fieldValue = values[name]..rawValue = value;

    if (fieldValue.validateOnEachChange) {
      validateField(name);
    }

    // if (onChanged != null) {
    //   /// Todo allow errors
    //   if (allowWithErrors || (validationErrors == 0 && stillRequired == 0)) {
    //     onChanged(values);
    //   }
    // }
    notifyListeners();
  }

  void onSubmit(String name) {
    final spec = getFieldSpec(name);
    final idx = _getFieldSpecIndex(spec);
    if (spec is FieldText) {
      values[name].rawValue = getTextEditingController(name).text;
    }

    if (idx + 1 < fields.length) {
      final nextField = fields[idx + 1];
      getFocusNode(nextField.name).requestFocus();
    } else {
      getFocusNode(name).unfocus();
    }
  }

  /// Gets the current value for a field by name
  /// Radio buttons get value by Group name
  /// and default to a value = to the first option listed
  Object getValue(String name) => values[name].rawValue;
}

/// Extensions on List<String> to help with building the ultimate simple form
extension FormHelperStringListExtension on List<String> {
  /// Build Simple Form. It's got fields, none are required, none are validated
  ///
  /// ["title","name","email"].buildSimpleForm();
  Widget buildSimpleForm(
          {FormUiBuilder uiBuilder = scrollableSimpleForm,
          FormResultsCallback onFormChanged,
          FormResultsCallback onFormSubmitted}) =>
      QuickForm(
          onFormChanged: onFormChanged,
          onFormSubmitted: onFormSubmitted,
          formFields: map((string) => FieldText(name: string)).toList());
}

/// Extensions on List<Field> to help with building the ultimate simple form

extension FormHelperFieldListExtension on List<FieldBase> {
  /// Extension Syntax for building out of a List<Field>
  Widget buildSimpleForm(
          {FormUiBuilder uiBuilder = scrollableSimpleForm,
          FormResultsCallback onFormChanged,
          FormResultsCallback onFormSubmitted}) =>
      QuickForm(
          uiBuilder: uiBuilder,
          onFormChanged: onFormChanged,
          onFormSubmitted: onFormSubmitted,
          formFields: this);
}

class _FieldValue {
  _FieldValue({Object initialValue, this.isMandatory})
      : _rawValue = initialValue;

  Object get rawValue => _rawValue;
  set rawValue(Object v) {
    _rawValue = v;
    hasChanged = true;
  }

  final bool isMandatory;
  bool hasChanged = false;
  Object _rawValue;
  Object value;
  bool validateOnEachChange = false;

  String errorMessage;

  bool get isEmpty {
    if (_rawValue == null) {
      return true;
    }
    if (_rawValue is String) {
      return (_rawValue as String).isEmpty;
    }
    return false;
  }

  void clear() {
    _rawValue = null;
    value = null;
    validateOnEachChange = false;
    hasChanged = false;
  }
}
