import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_helper/form_helper.dart';
import 'src/custom_form_builder.dart';
import 'src/sample_form.dart';

/// A key to the Scaffold Root
/// Allows me to wire up dialogs easily
final GlobalKey _scaffoldKey = GlobalKey();

void main() {
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  runApp(FormTestApp());
}

///
/// Form Testing App, Sample Project
class FormTestApp extends StatefulWidget {  
  @override
  _FormTestAppState createState() => _FormTestAppState();
}

class _FormTestAppState extends State<FormTestApp>
    with SingleTickerProviderStateMixin {
  TabController controller;

  @override
  void initState() {
    controller = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Flutter Form Demo',
        home: Scaffold(
            key: _scaffoldKey,
            body: SafeArea(
                child: Column(
              children: <Widget>[
                TabBar(
                  labelColor: Theme.of(context).colorScheme.primary,
                  controller: controller,
                  tabs: const <Widget>[
                    Tab(text: "Simple"),
                    Tab(text: "Custom")
                  ],
                ),
                Expanded(
                    child:
                        TabBarView(controller: controller, children: <Widget>[
                  FormBuilder(
                      form: sampleForm, onFormSubmitted: resultsCallback),
                  FormBuilder(
                      form: sampleForm,
                      onFormSubmitted: resultsCallback,
                      uiBuilder: customFormBuilder),
                ])),
              ],
            ))),
      );
}

/// We are going to send the results here
void resultsCallback(Map<String, String> results) => showDialog<void>(
    context: _scaffoldKey.currentContext,
    builder: (context) => Padding(
          padding: const EdgeInsets.all(64),
          child: Card(
              child: Text(results.keys.fold(
                  "",
                  (previousValue, element) =>
                      "$previousValue$element = ${results[element]}\n"))),
        ));