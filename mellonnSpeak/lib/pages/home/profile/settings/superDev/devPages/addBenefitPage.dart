import 'package:flutter/material.dart';
import 'package:mellonnSpeak/utilities/.env.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:http/http.dart' as http;

bool emailAdded = false;
bool emailRemoved = false;

class AddBenefitPage extends StatefulWidget {
  const AddBenefitPage({Key? key}) : super(key: key);

  @override
  State<AddBenefitPage> createState() => _AddBenefitPageState();
}

class _AddBenefitPageState extends State<AddBenefitPage> {
  String emailAdd = '';
  String emailRemove = '';
  bool isAddLoading = false;
  bool isRemoveLoading = false;

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
              title: 'Add Benefit User',
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
                            'Add a Benefit User',
                            style: Theme.of(context).textTheme.headline6,
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          onChanged: (textValue) {
                            setState(() {
                              emailAdd = textValue;
                            });
                          },
                          validator: (emailValue) {
                            if (emailValue!.isEmpty) {
                              return 'This field is mandatory';
                            }

                            RegExp regExp = new RegExp(
                                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+\.[a-zA-Z]+");

                            if (regExp.hasMatch(emailValue)) {
                              return null;
                            }

                            return 'This is not a valid email';
                          },
                          decoration: InputDecoration(
                            labelText: 'Email',
                          ),
                        ),
                        SizedBox(
                          height: 25,
                        ),
                        InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            setState(() {
                              isAddLoading = true;
                            });
                            await addEmail(emailAdd, stateSetter);
                            setState(() {
                              isAddLoading = false;
                            });
                          },
                          child: LoadingButton(
                            text: 'Add Email',
                            isLoading: isAddLoading,
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        emailAdded
                            ? Text(
                                'Email added!',
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
                  SizedBox(
                    height: 25,
                  ),
                  StandardBox(
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            'Remove a Benefit User',
                            style: Theme.of(context).textTheme.headline6,
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          onChanged: (textValue) {
                            setState(() {
                              emailRemove = textValue;
                            });
                          },
                          validator: (emailValue) {
                            if (emailValue!.isEmpty) {
                              return 'This field is mandatory';
                            }

                            RegExp regExp = new RegExp(
                                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+\.[a-zA-Z]+");

                            if (regExp.hasMatch(emailValue)) {
                              return null;
                            }

                            return 'This is not a valid email';
                          },
                          decoration: InputDecoration(
                            labelText: 'Email',
                          ),
                        ),
                        SizedBox(
                          height: 25,
                        ),
                        InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            setState(() {
                              isRemoveLoading = true;
                            });
                            await removeEmail(emailRemove, stateSetter);
                            setState(() {
                              isRemoveLoading = false;
                            });
                          },
                          child: LoadingButton(
                            text: 'Remove Email',
                            isLoading: isRemoveLoading,
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        emailRemoved
                            ? Text(
                                'Email removed!',
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

Future<bool> addEmail(String email, Function() stateSetter) async {
  final params = {"action": "add", "email": "$email"};

  final response = await http.post(
    Uri.parse(addBenefitEndPoint),
    headers: {
      "x-api-key": addBenefitKey,
    },
    body: params,
  );

  if (response.statusCode == 200) {
    emailAdded = true;
    stateSetter();
    return true;
  } else {
    return false;
  }
}

Future<bool> removeEmail(String email, Function() stateSetter) async {
  final params = {"action": "remove", "email": "$email"};

  final response = await http.post(
    Uri.parse(addBenefitEndPoint),
    headers: {
      "x-api-key": addBenefitKey,
    },
    body: params,
  );

  if (response.statusCode == 200) {
    emailRemoved = true;
    stateSetter();
    return true;
  } else {
    return false;
  }
}
