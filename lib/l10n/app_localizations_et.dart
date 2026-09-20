// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Estonian (`et`).
class AppLocalizationsEt extends AppLocalizations {
  AppLocalizationsEt([String locale = 'et']) : super(locale);

  @override
  String get appTitle => 'Baltic Deals';

  @override
  String get home => 'Avaleht';

  @override
  String get stores => 'Poed';

  @override
  String get favorites => 'Lemmikud';

  @override
  String get settings => 'Seaded';

  @override
  String get topDeals => 'Parimad pakkumised';

  @override
  String get clothing => 'Riided';

  @override
  String get shoes => 'Jalatsid';

  @override
  String get accessories => 'Aksessuaarid';

  @override
  String get beauty => 'Ilu';

  @override
  String get perfume => 'Parfüümid';

  @override
  String get technology => 'Tehnika';

  @override
  String get homeCategory => 'Kodu';

  @override
  String get sport => 'Sport';

  @override
  String get all => 'Kõik';

  @override
  String get allBrands => 'Kõik brändid';

  @override
  String get allStores => 'Kõik poed';

  @override
  String get any => 'Kõik';

  @override
  String get searchHint => 'Otsi toodet või brändi';

  @override
  String get minPrice => 'Hind alates';

  @override
  String get maxPrice => 'Hind kuni';

  @override
  String get desiredPrice => 'Soovitud hind, €';

  @override
  String get priceExample => 'Näiteks 49.99';

  @override
  String get minDiscount => 'Minimaalne allahindlus';

  @override
  String get sort => 'Sorteerimine';

  @override
  String get biggestDiscount => 'Suurim allahindlus';

  @override
  String get maximumSavings => 'Suurim sääst';

  @override
  String get priceLow => 'Odavamad enne';

  @override
  String get priceHigh => 'Kallimad enne';

  @override
  String get byBrand => 'Brändi järgi';

  @override
  String get multiStoreOnly => 'Saadaval mitmes poes';

  @override
  String get reset => 'Lähtesta';

  @override
  String get refresh => 'Värskenda';

  @override
  String get retry => 'Proovi uuesti';

  @override
  String get loadMore => 'Laadi veel';

  @override
  String get showAll => 'Näita kõiki';

  @override
  String get details => 'Vaata lähemalt';

  @override
  String get compareStores => 'Võrdle poode';

  @override
  String get bestPrice => 'Parim hind';

  @override
  String get coupon => 'KUPONG';

  @override
  String get addFavorite => 'Lisa lemmikutesse';

  @override
  String get removeFavorite => 'Eemalda lemmikutest';

  @override
  String get trackPrice => 'Jälgi hinnalangust';

  @override
  String get disable => 'Lülita välja';

  @override
  String get save => 'Salvesta';

  @override
  String get cancel => 'Tühista';

  @override
  String get open => 'Ava';

  @override
  String get language => 'Keel';

  @override
  String get systemLanguage => 'Seadme keel';

  @override
  String get estonian => 'Eesti';

  @override
  String get english => 'Inglise';

  @override
  String get russian => 'Vene';

  @override
  String get loadingError => 'Toodete laadimine ebaõnnestus';

  @override
  String get noProducts => 'Tooteid ei leitud';

  @override
  String foundProducts(int count) {
    return 'Leitud: $count';
  }

  @override
  String loadedProducts(int count) {
    return 'Laaditud: $count';
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
      other: '$count poodi',
      one: '1 pood',
    );
    return '$_temp0';
  }

  @override
  String savingsUpTo(String amount) {
    return 'Säästa kuni $amount €';
  }
}
