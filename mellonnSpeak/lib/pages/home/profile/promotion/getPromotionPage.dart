import 'package:flutter/material.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/promotionProvider.dart';
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
  Promotion promotion = Promotion(code: '', type: 'none', freePeriods: 0, referrer: '', referGroup: '');
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
        promotion = await getPromotion(
          stateSetter,
          code,
          context.read<AuthAppProvider>().email,
          context.read<AuthAppProvider>().freePeriods,
          true,
        );
        setState(() {
          gettingPromotion = false;
        });
        if (promotion.type == 'noExist') {
          showDialog(
            context: context,
            builder: (BuildContext context) => OkAlert(
              title: "Code doesn't exist",
              text: "The code you've entered doesn't exist in the system. Please make sure you've written the code correctly.",
            ),
          );
        } else if (promotion.type == 'used') {
          showDialog(
            context: context,
            builder: (BuildContext context) => OkAlert(
              title: "Code already used",
              text: "You've already used this code, and you can't use this code again.",
            ),
          );
        } else if (promotion.type == 'benefit' || promotion.type == 'periods' || promotion.type == 'dev') {
          pageController.animateToPage(
            1,
            duration: Duration(milliseconds: 200),
            curve: Curves.easeIn,
          );
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) => OkAlert(
              title: "Error",
              text: "An error happened while checking the code, please try again later.",
            ),
          );
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
        backgroundColor: Theme.of(context).backgroundColor,
        body: Stack(
          children: [
            BackGroundCircles(
              colorBig: Color.fromARGB(163, 250, 176, 40),
              colorSmall: Color.fromARGB(112, 250, 176, 40),
            ),
            Container(
              child: Column(
                children: [
                  standardAppBar(context, 'Redeem promotional code', 'getPromotion'),
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
                                        style: Theme.of(context).textTheme.headline5,
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
                                        style: Theme.of(context).textTheme.headline5,
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
                                            style: Theme.of(context).textTheme.headline6,
                                          ),
                                          Text(
                                            promotion.discountString(),
                                            style: Theme.of(context).textTheme.headline6!.copyWith(fontWeight: FontWeight.normal),
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
