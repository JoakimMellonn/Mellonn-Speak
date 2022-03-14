import 'package:flutter/material.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/promotionProvider.dart';
import 'package:mellonnSpeak/utilities/.env.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:http/http.dart' as http;
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
  Promotion promotion = Promotion(type: 'none', freePeriods: 0);
  PageController pageController = PageController(
    initialPage: 0,
    keepPage: true,
  );

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
        child: Column(
          children: [
            TitleBox(
              title: 'Redeem Code',
              heroString: 'getPromotion',
              extras: true,
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
                                  if (code.isEmpty || code == '') {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          OkAlert(
                                        title: 'Code is empty',
                                        text:
                                            'You need to write a promotional code',
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
                                      context
                                          .read<AuthAppProvider>()
                                          .freePeriods,
                                    );
                                    setState(() {
                                      gettingPromotion = false;
                                    });
                                    if (promotion.type == 'noExist') {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) =>
                                            OkAlert(
                                          title: "Code doesn't exist",
                                          text:
                                              "The code you've entered doesn't exist in the system. Please make sure you've written the code correctly.",
                                        ),
                                      );
                                    } else if (promotion.type == 'used') {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) =>
                                            OkAlert(
                                          title: "Code already used",
                                          text:
                                              "You've already used this code, and you can't use this code again.",
                                        ),
                                      );
                                    } else if (promotion.type == 'benefit' ||
                                        promotion.type == 'periods') {
                                      pageController.animateToPage(
                                        1,
                                        duration: Duration(milliseconds: 200),
                                        curve: Curves.easeIn,
                                      );
                                    } else {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) =>
                                            OkAlert(
                                          title: "Error",
                                          text:
                                              "An error happened while checking the code, please try again later.",
                                        ),
                                      );
                                    }
                                  }
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
                                child: Text(
                                  discountString(promotion),
                                  style: Theme.of(context).textTheme.headline6,
                                ),
                              ),
                              SizedBox(
                                height: 25,
                              ),
                              InkWell(
                                onTap: () async {
                                  await context
                                      .read<AuthAppProvider>()
                                      .getUserAttributes();
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
    );
  }
}

String discountString(Promotion promotion) {
  if (promotion.type == 'benefit' && promotion.freePeriods > 0) {
    return 'Discount: Benefit user (-40% on all purchases) and ${promotion.freePeriods} free credit(s)';
  } else if (promotion.type == 'benefit' && promotion.freePeriods == 0) {
    return 'Discount: Benefit user (-40% on all purchases)';
  } else {
    return 'Discount: ${promotion.freePeriods} free credits';
  }
}
