import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/superDev/devPages/createPromotionPageProvider.dart';
import 'package:mellonnSpeak/providers/promotionDbProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/provider.dart';

class CreatePromotionPage extends StatelessWidget {
  const CreatePromotionPage({Key? key}) : super(key: key);

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
                elevation: 0.5,
                backgroundColor: Theme.of(context).colorScheme.background,
                surfaceTintColor: Color.fromARGB(38, 118, 118, 118),
                expandedHeight: 100,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Hero(
                    tag: 'createPromotion',
                    child: Text(
                      'Create/Remove promotion',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    StandardBox(
                      margin: EdgeInsets.fromLTRB(25, 25, 25, 0),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              'Create Promotion',
                              style: Theme.of(context).textTheme.headlineSmall,
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
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                Spacer(),
                                DropdownButton(
                                  value: context.watch<CreatePromotionPageProvider>().typeValue,
                                  items:
                                      <String>['benefit', 'periods', 'dev', 'referrer', 'referGroup'].map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: Theme.of(context).textTheme.headlineSmall,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? value) {
                                    if (value != null) {
                                      context.read<CreatePromotionPageProvider>().typeValue = value;
                                    }
                                  },
                                  icon: Icon(
                                    Icons.arrow_downward,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                  elevation: 16,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.secondary,
                                    shadows: <Shadow>[
                                      Shadow(
                                        color: Theme.of(context).colorScheme.secondaryContainer,
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
                              context.read<CreatePromotionPageProvider>().codeAdd = textValue;
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
                            height: 15,
                          ),
                          Divider(),
                          TextFormField(
                            decoration: new InputDecoration(labelText: "Number of uses (0 for infinite)"),
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                            onChanged: (textValue) {
                              context.read<CreatePromotionPageProvider>().uses = textValue;
                            },
                            initialValue: '0',
                          ),
                          SizedBox(
                            height: 15,
                          ),
                          Divider(),
                          TextFormField(
                            decoration: new InputDecoration(labelText: "Number of free periods"),
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                            onChanged: (textValue) {
                              context.read<CreatePromotionPageProvider>().freePeriods = textValue;
                            },
                            initialValue: '0',
                          ),
                          context.read<CreatePromotionPageProvider>().isReferrer
                              ? TextFormField(
                                  decoration: new InputDecoration(labelText: "Referrer name"),
                                  onChanged: (textValue) {
                                    context.read<CreatePromotionPageProvider>().referrer = textValue;
                                  },
                                  initialValue: '',
                                )
                              : Container(),
                          SizedBox(
                            height: 25,
                          ),
                          InkWell(
                            onTap: () async {
                              if (context.read<CreatePromotionPageProvider>().typeValue == 'periods' &&
                                  context.read<CreatePromotionPageProvider>().freePeriods == '0') {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) => OkAlert(
                                    title: "Free Periods",
                                    text: "Free Periods can't be 0 you dumbass",
                                  ),
                                );
                              }
                              context.read<CreatePromotionPageProvider>().addLoading = true;
                              await addPromotion(
                                getPromoType(context.read<CreatePromotionPageProvider>().typeValue),
                                context.read<CreatePromotionPageProvider>().codeAdd,
                                int.parse(context.read<CreatePromotionPageProvider>().uses),
                                int.parse(context.read<CreatePromotionPageProvider>().freePeriods),
                                context.read<CreatePromotionPageProvider>().referrer,
                              );
                              context.read<CreatePromotionPageProvider>().addLoading = false;
                            },
                            child: LoadingButton(
                              text: 'Add Promotion code',
                              isLoading: context.watch<CreatePromotionPageProvider>().addLoading,
                            ),
                          ),
                          context.read<CreatePromotionPageProvider>().promotionAdded == true
                              ? Text(
                                  context.read<CreatePromotionPageProvider>().responseBody,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.green,
                                      ),
                                )
                              : Container(),
                        ],
                      ),
                    ),
                    StandardBox(
                      margin: EdgeInsets.fromLTRB(25, 25, 25, 0),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              'Remove Promotion',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          SizedBox(
                            height: 15,
                          ),
                          Divider(),
                          TextFormField(
                            onChanged: (textValue) {
                              context.read<CreatePromotionPageProvider>().codeRemove = textValue;
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
                              context.read<CreatePromotionPageProvider>().removeLoading = true;
                              await removePromotion(
                                context.read<CreatePromotionPageProvider>().codeRemove,
                              );
                              context.read<CreatePromotionPageProvider>().removeLoading = false;
                            },
                            child: LoadingButton(
                              text: 'Remove Promotion code',
                              isLoading: context.watch<CreatePromotionPageProvider>().removeLoading,
                            ),
                          ),
                          context.read<CreatePromotionPageProvider>().promotionRemoved == true
                              ? Text(
                                  context.read<CreatePromotionPageProvider>().removeResponseBody,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
        ],
      ),
    );
  }
}
