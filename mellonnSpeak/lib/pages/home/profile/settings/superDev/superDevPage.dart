import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
      body: Stack(
        children: [
          BackGroundCircles(),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                leading: appBarLeading(context),
                pinned: true,
                expandedHeight: 100,
                elevation: 0.5,
                backgroundColor: Theme.of(context).colorScheme.background,
                surfaceTintColor: Color.fromARGB(38, 118, 118, 118),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Hero(
                    tag: 'superDev',
                    child: Text(
                      'Super Dev',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  [
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
                            Hero(
                              tag: 'createPromotion',
                              child: Text(
                                'Create Promotion Code',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
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
        ],
      ),
    );
  }
}
