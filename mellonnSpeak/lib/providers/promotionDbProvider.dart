import 'package:amplify_flutter/amplify_flutter.dart';
import '../models/ModelProvider.dart';
import 'analyticsProvider.dart';

Future<Promotion> getPromotion(Function() stateSetter, String code, int freePeriods, bool applyPromo) async {
  if (await isCodeUsed(code)) {
    throw "code already used";
  }
  final promotions = await Amplify.DataStore.query(Promotion.classType, where: Promotion.CODE.eq(code));
  if (promotions.length == 0) {
    throw "code no exist";
  }
  Promotion promotion = promotions.first;
  if (applyPromo) await applyPromotion(stateSetter, promotion, freePeriods);
  return promotion;
}

Future<bool> isCodeUsed(String code) async {
  final attributes = await Amplify.Auth.fetchUserAttributes();
  final promotions = attributes.where((element) => element.userAttributeKey == CognitoUserAttributeKey.custom("promos"));
  if (promotions.length > 0) {
    final promoList = promotions.first.value.split(';');
    if (promoList.contains(code)) {
      return true;
    }
  }
  return false;
}

///
///Applies the discount
///
Future<void> applyPromotion(Function() stateSetter, Promotion promotion, int userFreePeriods) async {
  final attributes = await Amplify.Auth.fetchUserAttributes();
  final userPromos = attributes.where((element) => element.userAttributeKey == CognitoUserAttributeKey.custom("promos"));
  final newPromos = userPromos.length > 0 ? userPromos.first.value + ';' + promotion.code : promotion.code;
  try {
    var attributes = [
      AuthUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.custom("promos"),
        value: newPromos,
      ),
    ];

    await Amplify.Auth.updateUserAttributes(attributes: attributes);
  } on AuthException catch (e) {
    recordEventError('applyPromotion', e.message);
    print(e.message);
  }

  if (promotion.type == PromotionType.BENEFIT) {
    await updateUserGroup('benefit');
    if (promotion.freePeriods > 0) {
      await updateFreePeriods(userFreePeriods + promotion.freePeriods);
    }
  } else if (promotion.type == PromotionType.DEV) {
    await updateUserGroup('dev');
  } else if (promotion.type == PromotionType.PERIODS) {
    await updateFreePeriods(userFreePeriods + promotion.freePeriods);
  } else if (promotion.type == PromotionType.REFERRER) {
    final referrer = (await Amplify.DataStore.query(Referrer.classType, where: Referrer.ID.eq(promotion.referrerID))).first;
    await addUserToReferrer(referrer);
    if (promotion.freePeriods > 0) {
      await updateFreePeriods(userFreePeriods + promotion.freePeriods);
    }
  }
}

Future<void> updateUserGroup(String group) async {
  try {
    var attributes = [
      AuthUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.custom("group"),
        value: group,
      ),
    ];
    await Amplify.Auth.updateUserAttributes(attributes: attributes);
  } on AuthException catch (e) {
    recordEventError('updateUserGroup', e.message);
    print(e.message);
  }
}

Future<bool> addPromotion(PromotionType type, String code, int uses, int freePeriods, String referrer) async {
  try {
    final dbPromo = await Amplify.DataStore.query(Promotion.classType, where: Promotion.CODE.eq(code));
    if (dbPromo.length > 0) {
      return false;
    }

    late Promotion promotion;

    if (type == PromotionType.REFERRER || type == PromotionType.REFERGROUP) {
      final promoReferrer = await createReferrer(referrer, type == PromotionType.REFERGROUP);
      if (promoReferrer == null) {
        throw 'Something went wrong creating the referrer';
      }
      promotion = Promotion(
        type: type,
        code: code,
        date: TemporalDate.now(),
        uses: uses,
        freePeriods: freePeriods,
        referrerID: promoReferrer.id,
      );
    } else {
      promotion = Promotion(
        type: type,
        code: code,
        date: TemporalDate.now(),
        uses: uses,
        freePeriods: freePeriods,
      );
    }
    await Amplify.DataStore.save(promotion);
    return true;
  } catch (e) {
    recordEventError('addPromotion', e.toString());
    print(e.toString());
    return false;
  }
}

Future<bool> removePromotion(String code) async {
  try {
    final dbPromo = await Amplify.DataStore.query(Promotion.classType, where: Promotion.CODE.eq(code));
    if (dbPromo.length == 0) {
      return true;
    }
    await Amplify.DataStore.delete(dbPromo.first);
    return true;
  } catch (e) {
    recordEventError('removePromotion', e.toString());
    print(e.toString());
    return false;
  }
}

Future<bool> addUserToReferrer(Referrer referrer) async {
  try {
    var attributes = [
      AuthUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.custom("referrer"),
        value: referrer.name,
      ),
      AuthUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.custom("referGroup"),
        value: referrer.isGroup ? referrer.name : '',
      ),
    ];
    await Amplify.Auth.updateUserAttributes(attributes: attributes);

    await Amplify.DataStore.save(
      referrer.copyWith(
        members: referrer.members + 1,
      ),
    );
    return true;
  } catch (e) {
    recordEventError('addUserToReferrer', e.toString());
    print(e.toString());
    return false;
  }
}

Future<Referrer?> createReferrer(String referrer, bool group) async {
  try {
    final dbReferrer = await Amplify.DataStore.query(Referrer.classType, where: Referrer.NAME.eq(referrer));
    if (dbReferrer.length > 0) {
      if (dbReferrer.first.isGroup != group) {
        return null;
      }
      return dbReferrer.first;
    }
    final referrerObj = Referrer(
      name: referrer,
      members: 0,
      purchases: 0,
      seconds: 0,
      discount: 40,
      isGroup: group,
    );
    await Amplify.DataStore.save(referrerObj);
    return referrerObj;
  } catch (e) {
    recordEventError('createReferrer', e.toString());
    print(e.toString());
    return null;
  }
}

Future<void> updateFreePeriods(int freePeriods) async {
  try {
    var attributes = [
      AuthUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.custom("freeCredits"),
        value: freePeriods.toString(),
      ),
    ];
    await Amplify.Auth.updateUserAttributes(attributes: attributes);
  } on AuthException catch (e) {
    recordEventError('updateFreePeriods', e.message);
    print(e.message);
  }
}

Future<void> registerPurchase(double duration) async {
  try {
    final attributes = await Amplify.Auth.fetchUserAttributes();
    final referrer = attributes.where((element) => element.userAttributeKey == CognitoUserAttributeKey.custom("referrer")).first.value;
    final dbReferrer = await Amplify.DataStore.query(Referrer.classType, where: Referrer.NAME.eq(referrer));
    if (dbReferrer.length > 0) {
      await Amplify.DataStore.save(
        dbReferrer.first.copyWith(
          purchases: dbReferrer.first.purchases + 1,
          seconds: dbReferrer.first.seconds + duration,
        ),
      );
    }
  } catch (e) {
    recordEventError('registerPurchase', e.toString());
    print(e.toString());
  }
}

String discountString(Promotion promotion) {
  if (promotion.type == PromotionType.BENEFIT && promotion.freePeriods > 0) {
    return 'Benefit user \n(-40% on all purchases) \nand ${promotion.freePeriods} free credit(s)';
  } else if (promotion.type == PromotionType.BENEFIT && promotion.freePeriods == 0) {
    return 'Benefit user \n(-40% on all purchases)';
  } else if (promotion.type == PromotionType.DEV) {
    return 'Developer user \n(everything is free)';
  } else {
    return '${promotion.freePeriods} free credits';
  }
}

PromotionType getPromoType(String type) {
  switch (type) {
    case 'benefit':
      return PromotionType.BENEFIT;
    case 'periods':
      return PromotionType.PERIODS;
    case 'referrer':
      return PromotionType.REFERRER;
    case 'referGroup':
      return PromotionType.REFERGROUP;
    case 'dev':
      return PromotionType.DEV;
    default:
      return PromotionType.PERIODS;
  }
}
