import 'package:flutter/material.dart';
import 'package:quick_form/quick_form.dart';

/// This is a Custom Form function for SampleForm
///
/// For each field, we use helper.getField(name) to inject the fields in
/// the righ places in the UI
///
Widget customFormBuilder(QuickFormController controller, BuildContext context) {
  String getSubmissionButtonText() {
    final stillRequired = controller.stillRequired;
    if (stillRequired > 0) {
      return "$stillRequired fields remaining";
    }

    final validationErrors = controller.validationErrors;
    if (validationErrors > 0) {
      return "$validationErrors field doesn't validate";
    }
    return "Submit Form";
  }

  return Column(
    children: <Widget>[
      Expanded(
        child: Card(
          elevation: 0.25,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(mainAxisSize: MainAxisSize.max, children: [
                Row(
                  children: <Widget>[
                    Expanded(flex: 3, child: controller.getWidget("name")),
                    Container(width: 16),
                    Expanded(flex: 3, child: controller.getWidget("title")),
                    Container(width: 16),
                    Expanded(child: controller.getWidget("age"))
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(child: controller.getWidget("password")),
                    Container(width: 16),
                    Expanded(child: controller.getWidget("repeat_password"))
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(child: controller.getWidget("email")),
                    Container(width: 16),
                    Expanded(child: controller.getWidget("url"))
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                  child: Container(
                    width: 320,
                    child: Card(
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: <Widget>[
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text("Gender"),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                mainAxisSize: MainAxisSize.max,
                                children: const <Widget>[
                                  Expanded(
                                      child: Text(
                                    "Male",
                                    textAlign: TextAlign.center,
                                  )),
                                  Expanded(
                                      child: Text(
                                    "Female",
                                    textAlign: TextAlign.center,
                                  )),
                                  Expanded(
                                      child: Text(
                                    "Unspecified",
                                    textAlign: TextAlign.center,
                                  )),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[
                                  Expanded(
                                      child: controller.getWidget("radio1")),
                                  Expanded(
                                      child: controller.getWidget("radio2")),
                                  Expanded(
                                      child: controller.getWidget("radio3")),
                                ],
                              )
                            ],
                          ),
                        )),
                  ),
                ),
                Row(
                  children: <Widget>[
                    const Text("Accept Terms"),
                    controller.getWidget("checkbox")
                  ],
                )
              ]),
            ),
          ),
        ),
      ),
      RaisedButton(
          key: const Key("submit"),
          onPressed: controller.submitForm,
          child: Text(getSubmissionButtonText())),
    ],
  );
}
