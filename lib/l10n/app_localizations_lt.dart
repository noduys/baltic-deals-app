// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Lithuanian (`lt`).
class AppLocalizationsLt extends AppLocalizations {
  AppLocalizationsLt([String locale = 'lt']) : super(locale);

  @override
  String get appTitle => 'Baltic Deals';

  @override
  String get home => 'Pradžia';

  @override
  String get stores => 'Parduotuvės';

  @override
  String get favorites => 'Mėgstamiausi';

  @override
  String get settings => 'Nustatymai';

  @override
  String get topDeals => 'Geriausi pasiūlymai';

  @override
  String get clothing => 'Drabužiai';

  @override
  String get shoes => 'Avalynė';

  @override
  String get accessories => 'Aksesuarai';

  @override
  String get beauty => 'Grožis';

  @override
  String get perfume => 'Kvepalai';

  @override
  String get technology => 'Technika';

  @override
  String get homeCategory => 'Namams';

  @override
  String get sport => 'Sportas';

  @override
  String get all => 'Visi';

  @override
  String get allBrands => 'Visi prekių ženklai';

  @override
  String get allStores => 'Visos parduotuvės';

  @override
  String get any => 'Bet koks';

  @override
  String get searchHint => 'Ieškoti pagal prekę arba prekės ženklą';

  @override
  String get minPrice => 'Kaina nuo';

  @override
  String get maxPrice => 'Kaina iki';

  @override
  String get desiredPrice => 'Norima kaina, €';

  @override
  String get priceExample => 'Pavyzdžiui, 49.99';

  @override
  String get minDiscount => 'Minimali nuolaida';

  @override
  String get sort => 'Rūšiuoti';

  @override
  String get biggestDiscount => 'Didžiausia nuolaida';

  @override
  String get maximumSavings => 'Didžiausias sutaupymas';

  @override
  String get priceLow => 'Mažiausia kaina';

  @override
  String get priceHigh => 'Didžiausia kaina';

  @override
  String get byBrand => 'Pagal prekės ženklą';

  @override
  String get multiStoreOnly => 'Yra keliose parduotuvėse';

  @override
  String get reset => 'Atstatyti';

  @override
  String get refresh => 'Atnaujinti';

  @override
  String get retry => 'Bandyti dar kartą';

  @override
  String get loadMore => 'Įkelti daugiau';

  @override
  String get showAll => 'Rodyti viską';

  @override
  String get details => 'Plačiau';

  @override
  String get compareStores => 'Palyginti parduotuves';

  @override
  String get bestPrice => 'Geriausia kaina';

  @override
  String get coupon => 'KUPONAS';

  @override
  String get addFavorite => 'Pridėti prie mėgstamiausių';

  @override
  String get removeFavorite => 'Pašalinti iš mėgstamiausių';

  @override
  String get trackPrice => 'Stebėti kainos kritimą';

  @override
  String get disable => 'Išjungti';

  @override
  String get save => 'Išsaugoti';

  @override
  String get cancel => 'Atšaukti';

  @override
  String get open => 'Atidaryti';

  @override
  String get language => 'Kalba';

  @override
  String get systemLanguage => 'Įrenginio kalba';

  @override
  String get estonian => 'Estų';

  @override
  String get english => 'Anglų';

  @override
  String get russian => 'Rusų';

  @override
  String get loadingError => 'Nepavyko įkelti prekių';

  @override
  String get noProducts => 'Prekių nerasta';

  @override
  String foundProducts(int count) {
    return 'Rasta: $count';
  }

  @override
  String loadedProducts(int count) {
    return 'Įkelta: $count';
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
      other: '$count parduotuvės',
      one: '1 parduotuvė',
    );
    return '$_temp0';
  }

  @override
  String savingsUpTo(String amount) {
    return 'Sutaupyk iki $amount €';
  }
}
