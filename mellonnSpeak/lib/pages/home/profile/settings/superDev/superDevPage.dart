import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/superDev/devPages/addBenefitPage.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/superDev/devPages/createPromotionPage.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';

class SuperDevPage extends StatefulWidget {
  const SuperDevPage({Key? key}) : super(key: key);

  @override
  State<SuperDevPage> createState() => _SuperDevPageState();
}

class _SuperDevPageState extends State<SuperDevPage> {
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
              title: 'Super Dev Settings',
              extras: true,
            ),
            Expanded(
              child: ListView(
                physics: BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: [
                  ///
                  ///Add a new email to the benefit users
                  ///
                  InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddBenefitPage(),
                        ),
                      );
                    },
                    child: StandardBox(
                      margin: EdgeInsets.fromLTRB(25, 25, 25, 0),
                      child: Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.solidUser,
                            size: 20,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          Text(
                            'Add Benefit User',
                            style: Theme.of(context).textTheme.headline6,
                          ),
                        ],
                      ),
                    ),
                  ),

                  ///
                  ///Create a new rebate code
                  ///
                  InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreatePromotionPage(),
                        ),
                      );
                    },
                    child: StandardBox(
                      margin: EdgeInsets.fromLTRB(25, 25, 25, 0),
                      child: Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.percent,
                            size: 20,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          Text(
                            'Create Promotion Code',
                            style: Theme.of(context).textTheme.headline6,
                          ),
                        ],
                      ),
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
