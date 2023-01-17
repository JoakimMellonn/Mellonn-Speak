import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingProvider with ChangeNotifier {
  bool _onboarded = false;
  String _buttonText = "Next";

  bool get onboarded => _onboarded;
  String get buttonText => _buttonText;

  setOnboardedState(bool state) {
    _onboarded = state;
    notifyListeners();
  }

  changeButtonText(int currentPage, int totalPages) {
    _buttonText = "Next";
    if (currentPage + 1 == totalPages) _buttonText = "Let's begin!";
    notifyListeners();
  }

  Future getOnboardedState() async {
    setOnboardedState((await SharedPreferences.getInstance()).getBool('onboarded') ?? false);
  }
}

class OnboardContent extends StatelessWidget {
  final String svgAsset;
  final String title;
  final String text;

  const OnboardContent({
    required this.svgAsset,
    required this.title,
    required this.text,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SvgPicture.asset(
          svgAsset,
        ),
        SizedBox(
          height: 25,
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.headline6,
          textAlign: TextAlign.center,
        ),
        SizedBox(
          height: 10,
        ),
        Container(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyText2!.copyWith(fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class CustomOrangeShape extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Path path_0 = Path();
    path_0.moveTo(size.width * 0.1215534, size.height * 0.8090806);
    path_0.arcToPoint(Offset(size.width * 0.6413387, size.height * 0.7663667),
        radius: Radius.elliptical(size.width * 0.3678173, size.height * 0.7229289), rotation: 0, largeArc: false, clockwise: false);
    path_0.lineTo(size.width * 0.6413387, size.height * 0.7663667);
    path_0.lineTo(size.width * 0.9997895, 0);
    path_0.lineTo(size.width * 0.2186908, 0);
    path_0.arcToPoint(Offset(0, size.height * 0.4298273),
        radius: Radius.elliptical(size.width * 0.2186908, size.height * 0.4298273), rotation: 0, largeArc: false, clockwise: false);
    path_0.lineTo(0, size.height * 0.4298273);
    path_0.lineTo(0, size.height * 0.5895129);
    path_0.close();

    Paint paint0Fill = Paint()..style = PaintingStyle.fill;
    paint0Fill.color = Color(0xfffab228).withOpacity(1.0);
    canvas.drawPath(path_0, paint0Fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
