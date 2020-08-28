import 'package:flutter/widgets.dart';

import '../quick_form.dart';

/// Type that is used to return the form data in a `map<String,FieldValue`
class FieldValue {
  const FieldValue({
    this.name,
    this.rawValue,
    this.hasError,
    this.value,
    this.isEmpty,
  });

  /// name that was used in the form defintion
  final String name;

  /// raw value of the form, not validated or converted
  /// probably only interesting if you accept forms with errors
  final Object rawValue;

  /// The validated value for this form field
  final Object value;

  /// true if the linked form fiels failed validation
  final bool hasError;

  /// if the field is empty
  final bool isEmpty;
}

/// Form UI Builder
///
/// Define functions like this to build a form and access the FormHelper
/// to get the widgets
typedef FormUiBuilder = Widget Function(
    QuickFormController helper, BuildContext context);

/// Form Results Callback
///
/// This function is used to return the results of the form to the callbacks
typedef FormResultsCallback = Function(Map<String, FieldValue> results);
