import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mellonnSpeak/utilities/.env.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

bool promotionAdded = false;
String responseBody = '';

class CreatePromotionPage extends StatefulWidget {
  const CreatePromotionPage({Key? key}) : super(key: key);

  @override
  State<CreatePromotionPage> createState() => _CreatePromotionPageState();
}

class _CreatePromotionPageState extends State<CreatePromotionPage> {
  String typeValue = 'benefit';
  String codeAdd = '';
  String uses = '0';
  String freePeriods = '1';
  bool addLoading = false;

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
                                  'periods'
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
                          validator: (emailValue) {
                            if (emailValue!.isEmpty) {
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
                        typeValue == 'periods'
                            ? Column(
                                children: [
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
                                        uses = textValue;
                                      });
                                    },
                                    initialValue: '1',
                                  ),
                                ],
                              )
                            : Container(),
                        SizedBox(
                          height: typeValue == 'periods' ? 25 : 10,
                        ),
                        InkWell(
                          onTap: () async {
                            setState(() {
                              addLoading = true;
                            });
                            print('uses: $uses, freePeriods: $freePeriods');
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> addPromotion(Function() stateSetter, String type, String code,
    String uses, String freePeriods) async {
  final params =
      '{"action":"add","type":"$type","code":"$code","date":"","uses":$uses,"freePeriods":$freePeriods}';

  final response = await http.put(
    Uri.parse(addPromotionEndPoint),
    headers: {
      "x-api-key": addPromotionKey,
    },
    body: params,
  );

  print(response.body);

  if (response.statusCode == 200) {
    promotionAdded = true;
    responseBody = response.body;
    stateSetter();
    return true;
  } else {
    return false;
  }
}
