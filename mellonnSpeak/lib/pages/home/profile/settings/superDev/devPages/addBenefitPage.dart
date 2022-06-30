import 'package:flutter/material.dart';
import 'package:mellonnSpeak/providers/promotionProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';

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

  @override
  void dispose() {
    emailAdded = false;
    emailRemoved = false;
    emailAdd = '';
    emailRemove = '';
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
      //Creating the same app bar that is used everywhere else
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
              heroString: 'addBenefit',
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

                            RegExp regExp =
                                new RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+\.[a-zA-Z]+");

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
                            await addRemEmail(emailAdd, AddRemAction.add, stateSetter);
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
                                style: Theme.of(context).textTheme.bodyText1?.copyWith(
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

                            RegExp regExp =
                                new RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+\.[a-zA-Z]+");

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
                            await addRemEmail(emailRemove, AddRemAction.remove, stateSetter);
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
                                style: Theme.of(context).textTheme.bodyText1?.copyWith(
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
