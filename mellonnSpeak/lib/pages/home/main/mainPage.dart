import 'dart:ui';

import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mellonnSpeak/awsDatabase/recordingElement.dart';
import 'package:mellonnSpeak/models/ModelProvider.dart';
import 'package:mellonnSpeak/pages/home/profile/profilePage.dart';
import 'package:mellonnSpeak/utilities/theme.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'mainPageProvider.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  Size bodySize = Size.zero;
  double blurAmount = 0;

  void panelOpen(double amount) {
    setState(() {
      blurAmount = amount * 10;
    });
  }

  state() {}

  Future<void> _pullRefresh() async {
    await Amplify.DataStore.clear();
    await Future.delayed(Duration(milliseconds: 250));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    print(MediaQuery.of(context).size.height);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SlidingUpPanel(
        minHeight: MediaQuery.of(context).size.height - bodySize.height + 40,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
        onPanelSlide: panelOpen,
        panelBuilder: recordingList,
        renderPanelSheet: false,
        body: body(context),
      ),
    );
  }

  Widget body(BuildContext buildContext) {
    return Stack(
      children: [
        Wrap(
          children: [
            MeasureSize(
              onChange: (size) {
                setState(() {
                  bodySize = size;
                  print(size);
                });
              },
              child: Container(
                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top, 20, MediaQuery.of(context).padding.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePageMobile(
                              homePageSetState: state,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.height * 0.06,
                        height: MediaQuery.of(context).size.height * 0.06,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage('assets/images/emptyProfile.png'),
                            fit: BoxFit.fill,
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              blurRadius: shadowRadius,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      '${greetingsString()}, ${context.read<AuthAppProvider>().firstName} ${context.read<AuthAppProvider>().lastName}!',
                      style: Theme.of(context).textTheme.bodyText2!.copyWith(
                            color: Color.fromRGBO(80, 80, 80, 0.75),
                            fontSize: 14,
                          ),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Text(
                      'Upload new recording?...',
                      style: GoogleFonts.raleway(
                        textStyle: Theme.of(context).textTheme.headline4,
                        fontSize: 30,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 20),
                      padding: EdgeInsets.fromLTRB(20, 15, 20, 15),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Theme.of(context).colorScheme.onBackground,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Color.fromARGB(38, 118, 118, 118),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Upload a new recording',
                            style: Theme.of(context).textTheme.headline5,
                          ),
                          Spacer(),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Color.fromARGB(38, 118, 118, 118),
                                  blurRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                FontAwesomeIcons.arrowUpFromBracket,
                                size: 18,
                                color: Theme.of(context).colorScheme.onSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 25,
                    ),
                    Text(
                      '...Or edit a recording?',
                      style: GoogleFonts.raleway(
                        textStyle: Theme.of(context).textTheme.headline4,
                        fontSize: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        IgnorePointer(
          ignoring: true,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: blurAmount,
              sigmaY: blurAmount,
            ),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey.shade300.withOpacity(blurAmount / 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget recordingList(ScrollController scrollController) {
    return RefreshIndicator(
      onRefresh: () async {
        await _pullRefresh();
      },
      child: StreamBuilder(
        stream: Amplify.DataStore.observeQuery(
          Recording.classType,
          sortBy: [Recording.DATE.descending()],
        ).skipWhile((snapshot) => !snapshot.isSynced),
        builder: (context, AsyncSnapshot<QuerySnapshot<Recording>> snapshot) {
          if (snapshot.data == null) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          QuerySnapshot<Recording> querySnapshot = snapshot.data!;
          return ListView.builder(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(25, 25, 25, 0),
            itemCount: querySnapshot.items.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [],
                );
              } else {
                Recording recording = querySnapshot.items[index - 1];
                return RecordingElement(
                  recording: recording,
                  recordingsContext: context,
                );
              }
            },
          );
        },
      ),
    );
  }
}

typedef void OnWidgetSizeChange(Size size);

class MeasureSizeRenderObject extends RenderProxyBox {
  Size? oldSize;
  final OnWidgetSizeChange onChange;

  MeasureSizeRenderObject(this.onChange);

  @override
  void performLayout() {
    super.performLayout();

    Size newSize = child!.size;
    if (oldSize == newSize) return;

    oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onChange(newSize);
    });
  }
}

class MeasureSize extends SingleChildRenderObjectWidget {
  final OnWidgetSizeChange onChange;

  const MeasureSize({
    Key? key,
    required this.onChange,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return MeasureSizeRenderObject(onChange);
  }
}
