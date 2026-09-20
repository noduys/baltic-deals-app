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

  @override
  String availableCount(int count) {
    return 'Pieejami: $count';
  }

  @override
  String bestPriceValue(String price) {
    return 'Labākā cena: $price';
  }

  @override
  String get category => 'Kategorija';

  @override
  String get changeTarget => 'Mainīt';

  @override
  String get chooseSize => 'Izvēlies izmēru, lai salīdzinātu veikalus';

  @override
  String get country => 'Valsts';

  @override
  String currentPriceLabel(String price) {
    return 'Pašreizējā cena: $price';
  }

  @override
  String get filters => 'Filtri';

  @override
  String get gender => 'Dzimums';

  @override
  String get goToStore => 'Doties uz veikalu';

  @override
  String get hideFilters => 'Paslēpt filtrus';

  @override
  String historyPoints(int count) {
    return 'Vēstures punkti: $count';
  }

  @override
  String get historyStarted => 'Cenu vēsture tikko sākta. Jauni punkti parādīsies, kad cena mainīsies.';

  @override
  String get inStock => 'Ir noliktavā';

  @override
  String get invalidPrice => 'Ievadi derīgu cenu';

  @override
  String get invalidProductLink => 'Nederīga preces saite';

  @override
  String get loadOffersFailed => 'Neizdevās ielādēt piedāvājumus';

  @override
  String get loadPriceHistoryFailed => 'Neizdevās ielādēt cenu vēsturi';

  @override
  String get loadSizesFailed => 'Neizdevās ielādēt izmērus';

  @override
  String get loadingSizes => 'Ielādē pieejamos izmērus…';

  @override
  String get maximum => 'Maksimums';

  @override
  String get minimum => 'Minimums';

  @override
  String get noOffers => 'Piedāvājumu vēl nav';

  @override
  String get noSizeData => 'Šai precei izmēru dati vēl nav ielādēti.';

  @override
  String get notSpecified => 'Nav norādīts';

  @override
  String get now => 'Tagad';

  @override
  String get openStoreFailed => 'Neizdevās atvērt veikalu';

  @override
  String priceAboveTarget(String amount) {
    return 'Pašreizējā cena ir par $amount augstāka par mērķi';
  }

  @override
  String get priceAlertInfo => 'Mērķa cena tiek saglabāta Baltic Deals serverī. Kad cena sasniegs mērķi, lietotne nosūtīs push paziņojumu.';

  @override
  String get priceAlertPrompt => 'Saglabā vēlamo cenu šai precei';

  @override
  String get priceAlreadyReached => 'Cena jau ir sasniegusi mērķa līmeni';

  @override
  String get priceHistory => 'Cenu vēsture';

  @override
  String get priceTrackingDisableFailed => 'Neizdevās izslēgt mērķi serverī. Mēģini vēlreiz.';

  @override
  String get priceTrackingDisabled => 'Cenas izsekošana serverī ir izslēgta';

  @override
  String get product => 'Prece';

  @override
  String get productLinkMissing => 'Preces saite nav pieejama';

  @override
  String selectedSize(String size) {
    return 'Izvēlētais izmērs: $size';
  }

  @override
  String get selectedSizeUnavailable => 'Izvēlētais izmērs pašlaik nav pieejams';

  @override
  String get serverUnavailableSavedLocally => 'Serveris īslaicīgi nav pieejams. Mērķis saglabāts tikai šajā ierīcē.';

  @override
  String get setTarget => 'Iestatīt';

  @override
  String sizeStoreCount(String size, int count) {
    return 'Izmērs $size · veikali: $count';
  }

  @override
  String get sizes => 'Izmēri';

  @override
  String sizesLabel(String sizes) {
    return 'Izmēri: $sizes';
  }

  @override
  String get store => 'Veikals';

  @override
  String get storePrices => 'Cenas veikalos';

  @override
  String get targetReached => 'Mērķa cena sasniegta!';

  @override
  String targetSavedServer(String price) {
    return 'Mērķis saglabāts serverī: $price';
  }

  @override
  String targetValue(String price) {
    return 'Mērķis: $price';
  }

  @override
  String triggeredAtTarget(String triggeredPrice, String targetPrice) {
    return 'Nostrādāja pie $triggeredPrice • mērķis $targetPrice';
  }

  @override
  String get tryDifferentSearch => 'Pamēģini mainīt meklēšanu vai filtrus.';

  @override
  String get unavailableSizesGray => 'Pašlaik nepieejamie izmēri ir parādīti pelēki.';
}
