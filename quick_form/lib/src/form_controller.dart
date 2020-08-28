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
      this.onlyValidateOnSubmit = false,
      this.mandatoryFieldMessage = 'This field is mandatory!'}) {
    for (final field in fields) {
      /// fields that have a `null` value for `valueKey` are only displayed
      /// and not included in validation and the return value e.g. `FieldSpacer`
      /// or `FieldLabely`
      if (field.valueKey != null) {
        /// as radio buttons share a single `_FieldState` we have to
        /// ensure only to create one field for a given valueKey therefore the
        /// ??=
        values[field.valueKey] ??= _FieldState(
          fieldName: field.name,
          initialValue: field.initialValue,
          isMandatory: field.mandatory,
        );
        final node = FocusNode();
        if (field.validateOnLostFocus) {
          node.addListener(() => _onFocusNodeChange(field, node));
        }
        focusNodes[field.name] = node;
      }
    }
  }

  /// if true field validation will only be done on submission of the Form
  final bool onlyValidateOnSubmit;

  /// Error message that is displayed for an empty mandatory field when
  /// validating the form on submit.
  /// if `null`, no error message is displayed but the field is still considered
  /// not validated and counted in [stillRequired]
  final String mandatoryFieldMessage;

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
  int get validationErrors => values.values.fold(
      0, (sum, fieldState) => fieldState.hasValidationError ? sum + 1 : sum);

  /// A count of how many fields are still required
  int get stillRequired => values.values.fold(
      0,
      (sum, fieldState) =>
          fieldState.isMandatory ? fieldState.isEmpty ? sum + 1 : sum : sum);

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
  Future submitForm() async {
    for (final fieldState in values.values) {
      await _validateFieldState(
        fieldState,
        markEmptyMandatoryFields: true,
      );
    }

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
        field.valueKey != null && values[field.valueKey].hasValidationError);
    if (field != null) {
      getFocusNode(field.name).requestFocus();
    }
  }

  /// Gets a field spec
  FieldBase _getFieldSpec(String fieldName) =>
      fields.firstWhere((element) => element.name == fieldName,
          orElse: () => throw Exception('Unknown field name "$fieldName"'));

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

  Future<void> _onFocusNodeChange(FieldBase field, FocusNode node) async {
    if (!node.hasFocus) {
      if (!onlyValidateOnSubmit) {
        await _validateFieldState(values[field.valueKey]);
      }
      if (onChanged != null) {
        /// Todo allow errors
        if (allowWithErrors || (validationErrors == 0 && stillRequired == 0)) {
          onChanged(values.map((k, v) => MapEntry(k, v.toFieldValue())));
        }
      }
    }
  }

  Future<bool> _validateFieldState(
    _FieldState fieldState, {
    bool markEmptyMandatoryFields = false,

    ///we only markt these on [submitForm]
  }) async {
    if (fieldState.isNotEmpty) {
      final spec = _getFieldSpec(fieldState.fieldName);

      final errorMessage = StringBuffer();
      for (final validator in spec.rawValidators) {
        final result = await validator.validate(this, fieldState._rawValue);
        errorMessage..write(result.message)..write('\n');
        if (result.stopValidating) {
          break;
        }
      }

      if (errorMessage.isEmpty) {
        /// validation of the raw value suceeded so we convert
        /// and validate the converted value
        fieldState.value = spec.convert(fieldState.rawValue);

        for (final validator in spec.validators) {
          final result = await validator.validate(this, fieldState._rawValue);
          errorMessage..write(result.message)..write('\n');
          if (result.stopValidating) {
            break;
          }
        }
      }
      fieldState.errorMessage =
          errorMessage.isNotEmpty ? errorMessage.toString() : null;
    } else {
      // fieldState is empty
      fieldState.errorMessage =
          markEmptyMandatoryFields && fieldState.isMandatory
              ? mandatoryFieldMessage
              : null;
    }
    if (fieldState.hasValidationError) {
      fieldState.validateOnEachChange = true;
    }

    notifyListeners();
    return fieldState.errorMessage == null;
  }

  /// Has to be called by the implementing widget
  /// every time its value is changed
  /// [valueKey] the key under which the value will be stored
  /// in the result map. Typically the name of the Field but there can be
  /// exceptions like RadioButtons that use their Groupname instead
  Future<void> onChange(String valueKey, Object value) async {
    final fieldValue = values[valueKey]..rawValue = value;

    if (fieldValue.validateOnEachChange) {
      await _validateFieldState(
        values[valueKey],
        markEmptyMandatoryFields: true,
      );
    }
  }

  /// If the implementing widget supports an submit/done option
  /// it has to call this function
  Future<void> onSubmit(String name) async {
    final field = _getFieldSpec(name);
    final idx = _getFieldSpecIndex(field);

    if (!await _validateFieldState(values[field.valueKey]) &&
        !onlyValidateOnSubmit) {
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
  _FieldState({
    @required this.fieldName,
    @required Object initialValue,
    @required this.isMandatory,
  }) : _rawValue = initialValue;
  final String fieldName;
  Object get rawValue => _rawValue;
  set rawValue(Object v) {
    _rawValue = v;
    hasChanged = true;
    value = null;
    errorMessage = null;
  }

  final bool isMandatory;
  bool hasChanged = false;
  Object _rawValue;
  Object value;
  bool validateOnEachChange = false;

  String errorMessage;

  bool get hasValidationError => errorMessage != null;

  bool get isEmpty {
    if (_rawValue == null) {
      return true;
    }
    if (_rawValue is String) {
      return (_rawValue as String).isEmpty;
    }
    return false;
  }

  bool get isNotEmpty => !isEmpty;

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
