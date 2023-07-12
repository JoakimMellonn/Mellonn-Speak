import 'package:flutter/material.dart';
import 'package:mellonnSpeak/models/ModelProvider.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/promotionDbProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/provider.dart';

bool gotPromotion = false;

class GetPromotionPage extends StatefulWidget {
  const GetPromotionPage({Key? key}) : super(key: key);

  @override
  State<GetPromotionPage> createState() => _GetPromotionPageState();
}

class _GetPromotionPageState extends State<GetPromotionPage> {
  String code = '';
  bool gettingPromotion = false;
  late Promotion promotion;
  PageController pageController = PageController(
    initialPage: 0,
    keepPage: true,
  );

  void stateSetter() {
    setState(() {});
  }

  Future onEnter() async {
    if (!gettingPromotion) {
      if (code.isEmpty || code == '') {
        showDialog(
          context: context,
          builder: (BuildContext context) => OkAlert(
            title: 'Code is empty',
            text: 'You need to write a promotional code',
          ),
        );
      } else {
        setState(() {
          gettingPromotion = true;
        });
        try {
          promotion = await getPromotion(
            stateSetter,
            code,
            context.read<AuthAppProvider>().freePeriods,
            true,
          );
          setState(() {
            gettingPromotion = false;
          });
          pageController.animateToPage(
            1,
            duration: Duration(milliseconds: 200),
            curve: Curves.easeIn,
          );
        } catch (e) {
          setState(() {
            gettingPromotion = false;
          });
          if (e.toString().contains('code no exist')) {
            showDialog(
              context: context,
              builder: (BuildContext context) => OkAlert(
                title: "Code doesn't exist",
                text: "The code you've entered doesn't exist in the system. Please make sure you've written the code correctly.",
              ),
            );
          } else if (e.toString().contains('code already used')) {
            showDialog(
              context: context,
              builder: (BuildContext context) => OkAlert(
                title: "Code already used",
                text: "You've already used this code, and you can't use this code again.",
              ),
            );
          } else {
            showDialog(
              context: context,
              builder: (BuildContext context) => OkAlert(
                title: "Something went wrong",
                text: "Something went wrong while trying to get the promotion. Please try again later.",
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            BackGroundCircles(
              colorBig: Color.fromARGB(163, 250, 176, 40),
              colorSmall: Color.fromARGB(112, 250, 176, 40),
            ),
            Container(
              child: Column(
                children: [
                  standardAppBar(
                    context,
                    'Redeem promotional code',
                    'getPromotion',
                    true,
                  ),
                  Expanded(
                    child: PageView(
                      physics: NeverScrollableScrollPhysics(),
                      controller: pageController,
                      children: [
                        Container(
                          child: Column(
                            children: [
                              StandardBox(
                                margin: EdgeInsets.all(25),
                                child: Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        'Redeem Code',
                                        style: Theme.of(context).textTheme.headlineSmall,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Divider(),
                                    TextFormField(
                                      onChanged: (textValue) {
                                        setState(() {
                                          code = textValue;
                                        });
                                      },
                                      onFieldSubmitted: (value) async {
                                        await onEnter();
                                      },
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return 'This field is mandatory';
                                        }
                                        return null;
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
                                        await onEnter();
                                      },
                                      child: LoadingButton(
                                        text: 'Redeem code',
                                        isLoading: gettingPromotion,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          child: Column(
                            children: [
                              StandardBox(
                                margin: EdgeInsets.all(25),
                                child: Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        'Code redeemed!',
                                        style: Theme.of(context).textTheme.headlineSmall,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Divider(),
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: Row(
                                        children: [
                                          Text(
                                            'Discount: ',
                                            style: Theme.of(context).textTheme.titleLarge,
                                          ),
                                          Text(
                                            discountString(promotion),
                                            style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.normal),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 25,
                                    ),
                                    InkWell(
                                      onTap: () async {
                                        await context.read<AuthAppProvider>().getUserAttributes();
                                        Navigator.pop(context);
                                      },
                                      child: StandardButton(
                                        text: 'Ok',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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
