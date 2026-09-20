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

  @override
  String availableCount(int count) {
    return 'Saadaval: $count';
  }

  @override
  String bestPriceValue(String price) {
    return 'Parim hind: $price';
  }

  @override
  String get category => 'Kategooria';

  @override
  String get changeTarget => 'Muuda';

  @override
  String get chooseSize => 'Vali suurus, et poode võrrelda';

  @override
  String get country => 'Riik';

  @override
  String currentPriceLabel(String price) {
    return 'Praegune hind: $price';
  }

  @override
  String get filters => 'Filtrid';

  @override
  String get gender => 'Sugu';

  @override
  String get goToStore => 'Mine poodi';

  @override
  String get hideFilters => 'Peida filtrid';

  @override
  String historyPoints(int count) {
    return 'Ajaloopunkte: $count';
  }

  @override
  String get historyStarted => 'Hinnaajalugu alles hakkas kogunema. Uued punktid ilmuvad hinna muutumisel.';

  @override
  String get inStock => 'Laos';

  @override
  String get invalidPrice => 'Sisesta korrektne hind';

  @override
  String get invalidProductLink => 'Vigane tootelink';

  @override
  String get loadOffersFailed => 'Pakkumiste laadimine ebaõnnestus';

  @override
  String get loadPriceHistoryFailed => 'Hinnaajaloo laadimine ebaõnnestus';

  @override
  String get loadSizesFailed => 'Suuruste laadimine ebaõnnestus';

  @override
  String get loadingSizes => 'Saadaolevate suuruste laadimine…';

  @override
  String get maximum => 'Maksimum';

  @override
  String get minimum => 'Miinimum';

  @override
  String get noOffers => 'Pakkumisi veel pole';

  @override
  String get noSizeData => 'Selle toote suuruste andmeid pole veel laaditud.';

  @override
  String get notSpecified => 'Pole märgitud';

  @override
  String get now => 'Praegu';

  @override
  String get openStoreFailed => 'Poodi ei õnnestunud avada';

  @override
  String priceAboveTarget(String amount) {
    return 'Praegune hind on sihthinnast $amount kõrgem';
  }

  @override
  String get priceAlertInfo => 'Sihthind salvestatakse Baltic Dealsi serverisse. Kui hind jõuab sihthinnani, saadab rakendus push-teavituse.';

  @override
  String get priceAlertPrompt => 'Salvesta selle toote soovitud hind';

  @override
  String get priceAlreadyReached => 'Hind on juba sihttasemeni jõudnud';

  @override
  String get priceHistory => 'Hinnaajalugu';

  @override
  String get priceTrackingDisableFailed => 'Sihthinna väljalülitamine serveris ebaõnnestus. Proovi uuesti.';

  @override
  String get priceTrackingDisabled => 'Hinna jälgimine on serveris välja lülitatud';

  @override
  String get product => 'Toode';

  @override
  String get productLinkMissing => 'Tootelink puudub';

  @override
  String selectedSize(String size) {
    return 'Valitud suurus: $size';
  }

  @override
  String get selectedSizeUnavailable => 'Valitud suurus pole praegu saadaval';

  @override
  String get serverUnavailableSavedLocally => 'Server pole ajutiselt saadaval. Sihthind salvestati ainult sellesse seadmesse.';

  @override
  String get setTarget => 'Määra';

  @override
  String sizeStoreCount(String size, int count) {
    return 'Suurus $size · poode: $count';
  }

  @override
  String get sizes => 'Suurused';

  @override
  String sizesLabel(String sizes) {
    return 'Suurused: $sizes';
  }

  @override
  String get store => 'Pood';

  @override
  String get storePrices => 'Hinnad poodides';

  @override
  String get targetReached => 'Sihthind saavutatud!';

  @override
  String targetSavedServer(String price) {
    return 'Sihthind salvestati serverisse: $price';
  }

  @override
  String targetValue(String price) {
    return 'Sihthind: $price';
  }

  @override
  String triggeredAtTarget(String triggeredPrice, String targetPrice) {
    return 'Käivitus hinnaga $triggeredPrice • siht $targetPrice';
  }

  @override
  String get tryDifferentSearch => 'Proovi muuta otsingut või filtreid.';

  @override
  String get unavailableSizesGray => 'Praegu mittesaadavad suurused on hallid.';
}
