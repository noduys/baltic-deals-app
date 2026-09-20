// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Latvian (`lv`).
class AppLocalizationsLv extends AppLocalizations {
  AppLocalizationsLv([String locale = 'lv']) : super(locale);

  @override
  String get appTitle => 'Baltic Deals';

  @override
  String get home => 'Sākums';

  @override
  String get stores => 'Veikali';

  @override
  String get favorites => 'Izlase';

  @override
  String get settings => 'Iestatījumi';

  @override
  String get topDeals => 'Labākie piedāvājumi';

  @override
  String get clothing => 'Apģērbs';

  @override
  String get shoes => 'Apavi';

  @override
  String get accessories => 'Aksesuāri';

  @override
  String get beauty => 'Skaistumkopšana';

  @override
  String get perfume => 'Parfimērija';

  @override
  String get technology => 'Tehnika';

  @override
  String get homeCategory => 'Mājai';

  @override
  String get sport => 'Sports';

  @override
  String get all => 'Visi';

  @override
  String get allBrands => 'Visi zīmoli';

  @override
  String get allStores => 'Visi veikali';

  @override
  String get any => 'Jebkura';

  @override
  String get searchHint => 'Meklēt pēc preces vai zīmola';

  @override
  String get minPrice => 'Cena no';

  @override
  String get maxPrice => 'Cena līdz';

  @override
  String get desiredPrice => 'Vēlamā cena, €';

  @override
  String get priceExample => 'Piemēram, 49.99';

  @override
  String get minDiscount => 'Minimālā atlaide';

  @override
  String get sort => 'Kārtot';

  @override
  String get biggestDiscount => 'Lielākā atlaide';

  @override
  String get maximumSavings => 'Lielākais ietaupījums';

  @override
  String get priceLow => 'Zemākā cena';

  @override
  String get priceHigh => 'Augstākā cena';

  @override
  String get byBrand => 'Pēc zīmola';

  @override
  String get multiStoreOnly => 'Pieejams vairākos veikalos';

  @override
  String get reset => 'Atiestatīt';

  @override
  String get refresh => 'Atjaunot';

  @override
  String get retry => 'Mēģināt vēlreiz';

  @override
  String get loadMore => 'Ielādēt vēl';

  @override
  String get showAll => 'Rādīt visu';

  @override
  String get details => 'Detalizēti';

  @override
  String get compareStores => 'Salīdzināt veikalus';

  @override
  String get bestPrice => 'Labākā cena';

  @override
  String get coupon => 'KUPONS';

  @override
  String get addFavorite => 'Pievienot izlasei';

  @override
  String get removeFavorite => 'Noņemt no izlases';

  @override
  String get trackPrice => 'Sekot cenas kritumam';

  @override
  String get disable => 'Izslēgt';

  @override
  String get save => 'Saglabāt';

  @override
  String get cancel => 'Atcelt';

  @override
  String get open => 'Atvērt';

  @override
  String get language => 'Valoda';

  @override
  String get systemLanguage => 'Ierīces valoda';

  @override
  String get estonian => 'Igauņu';

  @override
  String get english => 'Angļu';

  @override
  String get russian => 'Krievu';

  @override
  String get loadingError => 'Neizdevās ielādēt preces';

  @override
  String get noProducts => 'Preces netika atrastas';

  @override
  String foundProducts(int count) {
    return 'Atrasts: $count';
  }

  @override
  String loadedProducts(int count) {
    return 'Ielādēts: $count';
  }

  @override
  String discountBadge(int percent) {
    return '-$percent%';
  }

  @override
  String storesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count veikali',
      one: '1 veikals',
    );
    return '$_temp0';
  }

  @override
  String savingsUpTo(String amount) {
    return 'Ietaupi līdz $amount €';
  }
}
