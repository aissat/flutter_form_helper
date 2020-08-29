import 'dart:async';

import 'package:flutter/foundation.dart';

import '../quick_form.dart';

class ValidationResult {
  const ValidationResult(this.message, {this.stopValidating = false});

  factory ValidationResult.validationOk() => const ValidationResult(null);

  final String message;
  final bool stopValidating;
}

abstract class Validator {
  /// The General philosphy is as follows
  /// - [controller] gives access to all fields in form
  /// - [input] is the current fields raw value
  /// - return a String with an error when failing validation
  /// - return `null` on validation pass
  FutureOr<ValidationResult> validate(
    QuickFormController controller,
    Object input,
  );
}

/// Length Validator
///
/// By default validates at least 3 characters entered
/// Can be customized as necessary
class LengthValidator implements Validator {
  const LengthValidator({
    this.minLength = 3,
    this.maxLength = 10000,
    this.minErrMessage = "[length] characters or more Required",
    this.maxErrMessage = "not more than [length] characters",
    this.stopValidating = true,
  });

  final int minLength;
  final int maxLength;
  final String minErrMessage;
  final String maxErrMessage;
  final bool stopValidating;

  @override
  FutureOr<ValidationResult> validate(
    QuickFormController helper,
    Object input,
  ) {
    if (input is String) {
      if (input == null || input.length < minLength) {
        return ValidationResult(
            minErrMessage.replaceFirst('[length]', minLength.toString()),
            stopValidating: stopValidating);
      }
      if (input.length > maxLength) {
        return ValidationResult(
            maxErrMessage.replaceFirst('[length]', minLength.toString()),
            stopValidating: stopValidating);
      }
      return ValidationResult.validationOk();
    }
    throw ArgumentError('Length validator expects a value of type String but '
        'received: ${input.runtimeType}');
  }
}

class PatternValidator implements Validator {
  const PatternValidator(
    this.pattern,
    this.errorMessage, {
    this.invertResult = false,
    this.stopValidating = false,
  });

  factory PatternValidator.forEmail(
          {String errorMessage = 'Invalid email adress'}) =>
      PatternValidator(RegExp(r'[^@]+@.+\.[^.]+'), errorMessage);

  factory PatternValidator.forUrl(
          {String errorMessage = 'Invalid URL format'}) =>
      PatternValidator(_urlPattern, errorMessage);

  factory PatternValidator.exclude({
    @required String exclude,
    String errorMessage = '"[exclude]" is not allowed',
  }) {
    assert(exclude != null);
    errorMessage = errorMessage.replaceAll('[exclude]', exclude);
    return PatternValidator(RegExp('^((?!$exclude).)*\$'), errorMessage);
  }

  final RegExp pattern;
  final String errorMessage;
  final bool invertResult;
  final bool stopValidating;

  @override
  FutureOr<ValidationResult> validate(
      QuickFormController controller, Object input) {
    if (input is String) {
      if (pattern.hasMatch(input) && !invertResult) {
        return ValidationResult.validationOk();
      } else {
        return ValidationResult(errorMessage, stopValidating: stopValidating);
      }
    }
    throw ArgumentError('Pattern validator expects a value of type String but '
        'received: ${input.runtimeType}');
  }
}

/// Double Validator
///
/// Validates that text can be parsed to a double
String doubleValidator(QuickFormController helper, String input,
    {String defaultOutput}) {
  try {
    double.parse(input);
  } on Exception {
    return "Enter a valid number";
  }
  return defaultOutput;
}

/// Int Validator
///
/// Validates that text can be parsed to an Int
String intValidator(QuickFormController helper, String input,
    {String defaultOutput}) {
  try {
    int.parse(input);
  } on Exception {
    return "Enter a valid integer";
  }
  return defaultOutput;
}

/// Regex Patterns for URL & Email
final _urlPattern =
    RegExp(r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+');
