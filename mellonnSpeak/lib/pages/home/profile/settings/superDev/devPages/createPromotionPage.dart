import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mellonnSpeak/providers/promotionProvider.dart';
import 'package:mellonnSpeak/utilities/.env.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

bool promotionAdded = false;
bool promotionRemoved = false;
String responseBody = '';
String removeResponseBody = '';

class CreatePromotionPage extends StatefulWidget {
  const CreatePromotionPage({Key? key}) : super(key: key);

  @override
  State<CreatePromotionPage> createState() => _CreatePromotionPageState();
}

class _CreatePromotionPageState extends State<CreatePromotionPage> {
  String typeValue = 'benefit';
  String codeAdd = '';
  String uses = '0';
  String freePeriods = '0';
  bool addLoading = false;

  String codeRemove = '';
  bool removeLoading = false;

  @override
  void dispose() {
    promotionAdded = false;
    promotionRemoved = false;
    responseBody = '';
    removeResponseBody = '';
    super.dispose();
  }

  void stateSetter() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.background,
      //Creating the same appbar that is used everywhere else
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        automaticallyImplyLeading: false,
        title: StandardAppBarTitle(),
        elevation: 0,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            TitleBox(
              title: 'Create Promotion Code',
              heroString: 'createPromotion',
              extras: true,
            ),
            Expanded(
              child: ListView(
                physics: BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.all(25),
                children: [
                  StandardBox(
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            'Create Promotion',
                            style: Theme.of(context).textTheme.headline6,
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Divider(),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Row(
                            children: [
                              Text(
                                'Type of promotion:',
                                style: Theme.of(context).textTheme.headline6,
                              ),
                              Spacer(),
                              DropdownButton(
                                value: typeValue,
                                items: <String>[
                                  'benefit',
                                  'periods',
                                  'dev'
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style:
                                          Theme.of(context).textTheme.headline6,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? value) {
                                  if (value != null) {
                                    setState(() {
                                      typeValue = value;
                                    });
                                  }
                                },
                                icon: Icon(
                                  Icons.arrow_downward,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                                elevation: 16,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  shadows: <Shadow>[
                                    Shadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer,
                                      blurRadius: 1,
                                    ),
                                  ],
                                ),
                                underline: Container(
                                  height: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Divider(),
                        TextFormField(
                          onChanged: (textValue) {
                            setState(() {
                              codeAdd = textValue;
                            });
                          },
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'This field is mandatory';
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Code',
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Divider(),
                        TextFormField(
                          decoration: new InputDecoration(
                              labelText: "Number of uses (0 for infinite)"),
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onChanged: (textValue) {
                            setState(() {
                              uses = textValue;
                            });
                          },
                          initialValue: '0',
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Divider(),
                        TextFormField(
                          decoration: new InputDecoration(
                              labelText: "Number of free periods"),
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onChanged: (textValue) {
                            setState(() {
                              freePeriods = textValue;
                            });
                          },
                          initialValue: '0',
                        ),
                        SizedBox(
                          height: 25,
                        ),
                        InkWell(
                          onTap: () async {
                            if (typeValue == 'periods' && freePeriods == '0') {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) => OkAlert(
                                  title: "Free Periods",
                                  text: "Free Periods can't be 0 you dumbass",
                                ),
                              );
                            }
                            setState(() {
                              addLoading = true;
                            });
                            await addPromotion(
                              stateSetter,
                              typeValue,
                              codeAdd,
                              uses,
                              freePeriods,
                            );
                            setState(() {
                              addLoading = false;
                            });
                          },
                          child: LoadingButton(
                            text: 'Add Promotion code',
                            isLoading: addLoading,
                          ),
                        ),
                        promotionAdded == true
                            ? Text(
                                responseBody,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyText1
                                    ?.copyWith(
                                      color: Colors.green,
                                    ),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                  StandardBox(
                    margin: EdgeInsets.only(top: 25),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            'Remove Promotion',
                            style: Theme.of(context).textTheme.headline6,
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Divider(),
                        TextFormField(
                          onChanged: (textValue) {
                            setState(() {
                              codeRemove = textValue;
                            });
                          },
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'This field is mandatory';
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Code',
                          ),
                        ),
                        SizedBox(
                          height: 25,
                        ),
                        InkWell(
                          onTap: () async {
                            setState(() {
                              removeLoading = true;
                            });
                            await removePromotion(
                              stateSetter,
                              codeRemove,
                            );
                            setState(() {
                              removeLoading = false;
                            });
                          },
                          child: LoadingButton(
                            text: 'Remove Promotion code',
                            isLoading: removeLoading,
                          ),
                        ),
                        promotionRemoved == true
                            ? Text(
                                removeResponseBody,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyText1
                                    ?.copyWith(
                                      color: Colors.green,
                                    ),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}