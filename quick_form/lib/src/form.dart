import 'package:flutter/material.dart';

import '../quick_form.dart';

/// Builds a form
///
///
/// By default you can just provide it a form spec
/// It'll wire it all up for you
///
/// Optionally you can provide uiBuilder to build a specific form UI
///
class QuickForm extends StatefulWidget {
  /// Construct a form
  ///
  /// form = List of fields
  /// uiBuilder = builds the ui
  const QuickForm(
      {@required this.formFields,
      Key key,
      this.uiBuilder = scrollableSimpleForm,
      this.onFormChanged,
      this.onFormSubmitted})
      : controller = null,
        super(key: key);

  const QuickForm.withController({
    @required this.controller,
    Key key,
    this.uiBuilder = scrollableSimpleForm,
  })  : onFormChanged = null,
        onFormSubmitted = null,
        formFields = null,
        super(key: key);

  final QuickFormController controller;

  /// The list of fields in order of focus/drawing
  final List<FieldBase> formFields;

  /// A builder for the UI, scrollable SimpleForm to start
  final FormUiBuilder uiBuilder;

  /// Called every time the form is changed
  final FormResultsCallback onFormChanged;

  /// Called when the submit button is pressed and fields are validated
  final FormResultsCallback onFormSubmitted;

  @override
  _QuickFormState createState() => _QuickFormState();
}

class _QuickFormState extends State<QuickForm> {
  QuickFormController controller;

  @override
  void initState() {
    controller = widget.controller ??
        QuickFormController(
            fields: widget.formFields,
            onChanged: widget.onFormChanged,
            onSubmitted: widget.onFormSubmitted)
      ..addListener(_refresh);
    super.initState();
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    if (widget.controller == null) {
      //this means we have no custom controller
      // so we dispose this controller
      controller.dispose();
    }
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) => widget.uiBuilder(controller, context);
}

///
/// This is the default "debug" form
///
/// It can be used to rapidly generate a form, and is the default.
///
/// It's assumed you'll implement your own form however.
///
Widget scrollableSimpleForm(QuickFormController helper, BuildContext context) =>
    Column(
      children: <Widget>[
        Expanded(
          child: Card(
            elevation: 0.25,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: helper.fields.map((f) {
                      if (f is FieldRadioButton) {
                        return Row(children: <Widget>[
                          Text("${f.group ?? ""} ${f.label}"),
                          helper.getWidget(f.name)
                        ]);
                      } else {
                        return helper.getWidget(f.name);
                      }
                    }).toList()),
              ),
            ),
          ),
        ),
        helper.getWidget("submit")
      ],
    );
