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

  @override
  String availableCount(int count) {
    return 'Prieinama: $count';
  }

  @override
  String bestPriceValue(String price) {
    return 'Geriausia kaina: $price';
  }

  @override
  String get category => 'Kategorija';

  @override
  String get changeTarget => 'Keisti';

  @override
  String get chooseSize => 'Pasirink dydį, kad palygintum parduotuves';

  @override
  String get country => 'Šalis';

  @override
  String currentPriceLabel(String price) {
    return 'Dabartinė kaina: $price';
  }

  @override
  String get filters => 'Filtrai';

  @override
  String get gender => 'Lytis';

  @override
  String get goToStore => 'Eiti į parduotuvę';

  @override
  String get hideFilters => 'Slėpti filtrus';

  @override
  String historyPoints(int count) {
    return 'Istorijos taškų: $count';
  }

  @override
  String get historyStarted => 'Kainos istorija tik pradėta kaupti. Nauji taškai atsiras pasikeitus kainai.';

  @override
  String get inStock => 'Yra sandėlyje';

  @override
  String get invalidPrice => 'Įvesk teisingą kainą';

  @override
  String get invalidProductLink => 'Neteisinga prekės nuoroda';

  @override
  String get loadOffersFailed => 'Nepavyko įkelti pasiūlymų';

  @override
  String get loadPriceHistoryFailed => 'Nepavyko įkelti kainos istorijos';

  @override
  String get loadSizesFailed => 'Nepavyko įkelti dydžių';

  @override
  String get loadingSizes => 'Įkeliami galimi dydžiai…';

  @override
  String get maximum => 'Maksimumas';

  @override
  String get minimum => 'Minimumas';

  @override
  String get noOffers => 'Pasiūlymų kol kas nėra';

  @override
  String get noSizeData => 'Šios prekės dydžių duomenys dar neįkelti.';

  @override
  String get notSpecified => 'Nenurodyta';

  @override
  String get now => 'Dabar';

  @override
  String get openStoreFailed => 'Nepavyko atidaryti parduotuvės';

  @override
  String priceAboveTarget(String amount) {
    return 'Dabartinė kaina yra $amount didesnė už tikslą';
  }

  @override
  String get priceAlertInfo => 'Tikslinė kaina išsaugoma Baltic Deals serveryje. Kai kaina pasieks tikslą, programa išsiųs push pranešimą.';

  @override
  String get priceAlertPrompt => 'Išsaugok norimą šios prekės kainą';

  @override
  String get priceAlreadyReached => 'Kaina jau pasiekė nustatytą lygį';

  @override
  String get priceHistory => 'Kainos istorija';

  @override
  String get priceTrackingDisableFailed => 'Nepavyko išjungti tikslo serveryje. Bandyk dar kartą.';

  @override
  String get priceTrackingDisabled => 'Kainos stebėjimas serveryje išjungtas';

  @override
  String get product => 'Prekė';

  @override
  String get productLinkMissing => 'Prekės nuorodos nėra';

  @override
  String selectedSize(String size) {
    return 'Pasirinktas dydis: $size';
  }

  @override
  String get selectedSizeUnavailable => 'Pasirinkto dydžio šiuo metu nėra';

  @override
  String get serverUnavailableSavedLocally => 'Serveris laikinai nepasiekiamas. Tikslas išsaugotas tik šiame įrenginyje.';

  @override
  String get setTarget => 'Nustatyti';

  @override
  String sizeStoreCount(String size, int count) {
    return 'Dydis $size · parduotuvių: $count';
  }

  @override
  String get sizes => 'Dydžiai';

  @override
  String sizesLabel(String sizes) {
    return 'Dydžiai: $sizes';
  }

  @override
  String get store => 'Parduotuvė';

  @override
  String get storePrices => 'Kainos parduotuvėse';

  @override
  String get targetReached => 'Tikslinė kaina pasiekta!';

  @override
  String targetSavedServer(String price) {
    return 'Tikslas išsaugotas serveryje: $price';
  }

  @override
  String targetValue(String price) {
    return 'Tikslas: $price';
  }

  @override
  String triggeredAtTarget(String triggeredPrice, String targetPrice) {
    return 'Suveikė ties $triggeredPrice • tikslas $targetPrice';
  }

  @override
  String get tryDifferentSearch => 'Pabandyk pakeisti paiešką arba filtrus.';

  @override
  String get unavailableSizesGray => 'Šiuo metu neprieinami dydžiai rodomi pilkai.';
}
