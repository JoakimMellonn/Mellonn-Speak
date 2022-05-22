import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:http/http.dart';
import 'package:html/parser.dart';

class LanguageProvider with ChangeNotifier {
  ///Creating the necessary variables
  List<String> _languageList = [];
  List<String> _languageCodeList = [];
  String _defaultLanguage = 'Danish';
  String _defaultLanguageCode = 'da-DK';

  ///Providing them...
  List<String> get languageList => _languageList;
  List<String> get languageCodeList => _languageCodeList;
  String get defaultLanguage => _defaultLanguage;
  String get defaultLanguageCode => _defaultLanguageCode;

  ///
  ///This function can be called, with a language name
  ///The function will then return the language code for the given language
  ///
  String getLanguageCode(String language) {
    int index = _languageList.indexOf(language);
    return _languageCodeList[index];
  }

  ///
  ///This function can be called, with a language code
  ///The function will then return the language name for the given code
  ///
  String getLanguage(String languageCode) {
    int index = _languageCodeList.indexOf(languageCode);
    return _languageList[index];
  }

  ///
  ///This function will set the default language to the given language code
  ///
  void setDefaultLanguage(String languageCode) {
    _defaultLanguageCode = languageCode;
    _defaultLanguage = getLanguage(languageCode);
    print(_defaultLanguage + ' - ' + _defaultLanguageCode);
  }

  ///
  ///This function will scrape the Amazon website for supported languages
  ///
  Future<void> webScraber() async {
    var client = Client();
    //Gets the link to the webpage
    Response response = await client.get(
      Uri.parse(
          'https://docs.aws.amazon.com/transcribe/latest/dg/supported-languages.html'),
    );
    var document = parse(response.body);
    //Creating a list of all the elements in the table (this is where the languages are place)
    List<dom.Element> tbody = document.getElementsByTagName('tbody');
    List<dom.Element> rows = tbody.first.getElementsByTagName('tr');

    ///
    ///This loop goes through all the elements in the list created
    ///For each element it take the first and second element
    ///These two elements gives us the language name and code
    ///These are now added to the list of supported languages
    ///
    for (var row in rows) {
      String language = '';
      List<dom.Element> element = row.getElementsByTagName('td');
      dom.Element a = element.first.getElementsByTagName('a').first;
      if (element.first.text.contains(',')) {
        String variation =
            element.first.text.replaceAll(RegExp('[^,A-Za-z0-9]'), '');
        List temp = variation.split(',');
        language = temp.first + ' (' + temp.last + ')';
      } else {
        String temp = a.text.replaceAll(RegExp('[^,A-Za-z0-9]'), '');
        language = temp;
      }
      _languageList.add(language);
      _languageCodeList.add(element[1].text);
    }
    notifyListeners();
  }
}
