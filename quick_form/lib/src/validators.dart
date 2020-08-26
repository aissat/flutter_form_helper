import '../quick_form.dart';

/// Composite Validator
///
/// Composes and folds together multiple validators
/// Applies the list of Validators in order
String compositeValidator(
        List<Validator> validators, QuickFormController helper, Object input) =>
    input != null && (input is String && input.isNotEmpty)
        ? validators.fold(
            null, (output, v) => v(helper, input, defaultOutput: output))
        : null;

/// Length Validator
///
/// By default validates at least 3 characters entered
/// Can be customized as necessary
String lengthValidator(
  QuickFormController helper,
  String input, {
  int minLength = 3,
  int maxLength = 100000,
  String defaultOutput,
}) =>
    input == null || (input.length < minLength || input.length > maxLength)
        ? "$minLength characters or more Required"
        : defaultOutput;

/// Space Count Validator
///
/// Ensures the correct amount of spaces in a string
/// By default, no spaces, but can be configured to allow
/// as many words as you want.
String spaceCountValidator(QuickFormController helper, String input,
        {String defaultOutput,
        int count = 0,
        String message = "No Spaces Allowed"}) =>
    input != null && " ".allMatches(input).length != count
        ? message
        : defaultOutput;

/// Email Validator
///
/// Validates an email address against a regex
String emailValidator(QuickFormController helper, String input,
        {String defaultOutput}) =>
    input == null || !_emailPattern.hasMatch(input)
        ? "Please enter a email"
        : defaultOutput;

/// URL Validator
///
/// Validates that a URL was entered correctly
String urlValidator(QuickFormController helper, String input,
        {String defaultOutput}) =>
    input == null || !_urlPattern.hasMatch(input)
        ? "Please enter a URL"
        : defaultOutput;

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
final _emailPattern = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
