import 'package:flutter/material.dart';

import '../quick_form.dart';

/// Specifies a Form
class QuickFormController extends ChangeNotifier {
  /// Construct a FormHelper
  QuickFormController(
      {@required this.fields,
      this.onChanged,
      this.onSubmitted,
      this.allowWithErrors = false,
      this.onlyValidateOnSubmit = false}) {
    for (final field in fields) {
      /// as radio buttons share a single `_FieldState` we have to
      /// ensure only to create one field for a given valueKey therefore the
      /// ??=
      values[field.valueKey] ??= _FieldState(
          fieldName: field.name,
          initialValue: field.initialValue,
          isMandatory: field.mandatory);
      final node = FocusNode();
      if (field.validateOnLostFocus) {
        node.addListener(() => _onFocusNodeChange(field.name, node));
      }
      focusNodes[field.name] = node;
    }
  }

  /// if true field validation will only be done on submission of the Form
  final bool onlyValidateOnSubmit;

  /// Called when the form is changed
  final FormResultsCallback onChanged;

  /// Called when the form is submitted
  final FormResultsCallback onSubmitted;

  /// Allow callbacks when there is errors present
  /// (missing fields or validation errors)
  final bool allowWithErrors;

  /// All the fields
  final List<FieldBase> fields;

  /// All the focus nodes
  final Map<String, FocusNode> focusNodes = {};

  /// All the values
  final Map<String, _FieldState> values = {};

  /// A count of validation errors
  int get validationErrors => fields.fold(
      0,
      (sum, field) => compositeValidator(
                  field.validators, this, getRawValue(field.valueKey)) ==
              null
          ? sum
          : sum + 1);

  /// A count of how many fields are still required
  int get stillRequired => fields.fold(
      0,
      (sum, field) => field.mandatory
          ? values[field.valueKey]?.isEmpty ?? false ? sum + 1 : sum
          : sum);

  /// Dispose this form
  @override
  void dispose() {
    focusNodes.forEach((key, value) => value.dispose());
    super.dispose();
  }

  /// Build the form
  Widget buildForm(BuildContext context,
          {FormUiBuilder builder = scrollableSimpleForm}) =>
      builder(this, context);

  /// Gets the label for a field
  String getLabel(String fieldName) => _getFieldSpec(fieldName).label;

  /// Call this when you want to "Submit" the form
  ///
  /// It'll redirect you to required fields or to fix errors
  /// before submitting
  void submitForm() {
    if (allowWithErrors && onSubmitted != null) {
      onSubmitted(values.map((k, v) => MapEntry(k, v.toFieldValue())));
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
      onSubmitted(values.map((k, v) => MapEntry(k, v.toFieldValue())));
    }
    notifyListeners();
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
        compositeValidator(
            field.validators, this, getRawValue(field.valueKey)) !=
        null);
    if (field != null) {
      getFocusNode(field.name).requestFocus();
    }
  }

  /// Gets a field spec
  FieldBase _getFieldSpec(String fieldName) =>
      fields.firstWhere((element) => element.name == fieldName);

  /// Gets a field spec
  int _getFieldSpecIndex(FieldBase fieldSpec) => fields.indexOf(fieldSpec);

  /// Get a focus node for a named field
  FocusNode getFocusNode(String fieldName) => focusNodes[fieldName];

  /// returns the current validation error of a field
  /// [valueKey] the key under which the value will be stored
  /// in the result map. Typically the name of the Field but there can be
  /// exceptions like RadioButtons that use their Groupname instead
  String getValidationError(String valueKey) => values[valueKey]?.errorMessage;

  /// Gets the Widget for a field
  /// "submit" is a special case
  Widget getWidget(String name) => _getFieldSpec(name).buildWidget(this);

  void _onFocusNodeChange(String fieldName, FocusNode node) {
    if (!node.hasFocus) {
      if (!onlyValidateOnSubmit) {
        _validateField(fieldName);
      }
      if (onChanged != null) {
        /// Todo allow errors
        if (allowWithErrors || (validationErrors == 0 && stillRequired == 0)) {
          onChanged(values.map((k, v) => MapEntry(k, v.toFieldValue())));
        }
      }
    }
  }

  bool _validateField(String valueKey) {
    final valueField = values[valueKey];
    final spec = _getFieldSpec(valueKey);
    valueField.errorMessage =
        compositeValidator(spec.validators, this, valueField._rawValue);
    if (valueField.errorMessage != null) {
      values[valueKey].validateOnEachChange = true;
    } else {
      valueField.value = spec.convert(valueField.rawValue);
    }
    notifyListeners();
    return valueField.errorMessage == null;
  }

  /// Has to be called by the implementing widget
  /// every time its value is changed
  /// [valueKey] the key under which the value will be stored
  /// in the result map. Typically the name of the Field but there can be
  /// exceptions like RadioButtons that use their Groupname instead
  void onChange(String valueKey, Object value) {
    final fieldValue = values[valueKey]..rawValue = value;

    if (fieldValue.validateOnEachChange) {
      _validateField(valueKey);
    }
  }

  /// If the implementing widget supports an submit/done option
  /// it has to call this function
  void onSubmit(String name) {
    final spec = _getFieldSpec(name);
    final idx = _getFieldSpecIndex(spec);

    if (!_validateField(name) && !onlyValidateOnSubmit) {
      // if validation fails we keep focus in this field
      getFocusNode(name).requestFocus();
      if (onChanged != null) {
        /// Todo allow errors
        if (allowWithErrors || (validationErrors == 0 && stillRequired == 0)) {
          onChanged(values.map((k, v) => MapEntry(k, v.toFieldValue())));
        }
      }
    } else {
      // move focus to next field
      if (idx + 1 < fields.length) {
        final nextField = fields[idx + 1];
        getFocusNode(nextField.name).requestFocus();
      } else {
        getFocusNode(name).unfocus();
      }
    }
  }

  /// Gets the current value for a field by name
  /// Radio buttons get value by Group name
  /// and default to a value = to the first option listed
  /// [valueKey] the key under which the value will be stored
  /// in the result map. Typically the name of the Field but there can be
  /// exceptions like RadioButtons that use their Groupname instead
  Object getRawValue(String valueKey) => values[valueKey].rawValue;
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

class _FieldState {
  _FieldState({this.fieldName, Object initialValue, this.isMandatory})
      : _rawValue = initialValue;
  final String fieldName;
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

  FieldValue toFieldValue() => FieldValue(
      name: fieldName,
      rawValue: _rawValue,
      value: value,
      hasError: errorMessage != null,
      isEmpty: isEmpty);
}
