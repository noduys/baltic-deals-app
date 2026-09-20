// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Baltic Deals';

  @override
  String get home => 'Home';

  @override
  String get stores => 'Stores';

  @override
  String get favorites => 'Favorites';

  @override
  String get settings => 'Settings';

  @override
  String get topDeals => 'Top deals';

  @override
  String get clothing => 'Clothing';

  @override
  String get shoes => 'Shoes';

  @override
  String get accessories => 'Accessories';

  @override
  String get beauty => 'Beauty';

  @override
  String get perfume => 'Perfume';

  @override
  String get technology => 'Technology';

  @override
  String get homeCategory => 'Home';

  @override
  String get sport => 'Sport';

  @override
  String get all => 'All';

  @override
  String get allBrands => 'All brands';

  @override
  String get allStores => 'All stores';

  @override
  String get any => 'Any';

  @override
  String get searchHint => 'Search by product or brand';

  @override
  String get minPrice => 'Min price';

  @override
  String get maxPrice => 'Max price';

  @override
  String get desiredPrice => 'Desired price, €';

  @override
  String get priceExample => 'For example 49.99';

  @override
  String get minDiscount => 'Minimum discount';

  @override
  String get sort => 'Sort';

  @override
  String get biggestDiscount => 'Biggest discount';

  @override
  String get maximumSavings => 'Maximum savings';

  @override
  String get priceLow => 'Lowest price';

  @override
  String get priceHigh => 'Highest price';

  @override
  String get byBrand => 'By brand';

  @override
  String get multiStoreOnly => 'Available in multiple stores';

  @override
  String get reset => 'Reset';

  @override
  String get refresh => 'Refresh';

  @override
  String get retry => 'Retry';

  @override
  String get loadMore => 'Load more';

  @override
  String get showAll => 'Show all';

  @override
  String get details => 'Details';

  @override
  String get compareStores => 'Compare stores';

  @override
  String get bestPrice => 'Best price';

  @override
  String get coupon => 'COUPON';

  @override
  String get addFavorite => 'Add to favorites';

  @override
  String get removeFavorite => 'Remove from favorites';

  @override
  String get trackPrice => 'Track price drop';

  @override
  String get disable => 'Disable';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get open => 'Open';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'Device language';

  @override
  String get estonian => 'Estonian';

  @override
  String get english => 'English';

  @override
  String get russian => 'Russian';

  @override
  String get loadingError => 'Could not load products';

  @override
  String get noProducts => 'No products found';

  @override
  String foundProducts(int count) {
    return 'Found: $count';
  }

  @override
  String loadedProducts(int count) {
    return 'Loaded: $count';
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
      other: '$count stores',
      one: '1 store',
    );
    return '$_temp0';
  }

  @override
  String savingsUpTo(String amount) {
    return 'Save up to $amount €';
  }

  @override
  String availableCount(int count) {
    return 'Available: $count';
  }

  @override
  String bestPriceValue(String price) {
    return 'Best price: $price';
  }

  @override
  String get category => 'Category';

  @override
  String get changeTarget => 'Change';

  @override
  String get chooseSize => 'Choose a size to compare stores';

  @override
  String get country => 'Country';

  @override
  String currentPriceLabel(String price) {
    return 'Current price: $price';
  }

  @override
  String get filters => 'Filters';

  @override
  String get gender => 'Gender';

  @override
  String get goToStore => 'Go to store';

  @override
  String get hideFilters => 'Hide filters';

  @override
  String historyPoints(int count) {
    return 'History points: $count';
  }

  @override
  String get historyStarted => 'Price history has just started. New points will appear when the price changes.';

  @override
  String get inStock => 'In stock';

  @override
  String get invalidPrice => 'Enter a valid price';

  @override
  String get invalidProductLink => 'Invalid product link';

  @override
  String get loadOffersFailed => 'Could not load offers';

  @override
  String get loadPriceHistoryFailed => 'Could not load price history';

  @override
  String get loadSizesFailed => 'Could not load sizes';

  @override
  String get loadingSizes => 'Loading available sizes…';

  @override
  String get maximum => 'Maximum';

  @override
  String get minimum => 'Minimum';

  @override
  String get noOffers => 'No offers yet';

  @override
  String get noSizeData => 'Size data for this product is not available yet.';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get now => 'Now';

  @override
  String get openStoreFailed => 'Could not open the store';

  @override
  String priceAboveTarget(String amount) {
    return 'Current price is $amount above the target';
  }

  @override
  String get priceAlertInfo => 'The target is saved on the Baltic Deals server. When the price reaches the target, the app will send a push notification.';

  @override
  String get priceAlertPrompt => 'Save your desired price for this product';

  @override
  String get priceAlreadyReached => 'The price has already reached the target level';

  @override
  String get priceHistory => 'Price history';

  @override
  String get priceTrackingDisableFailed => 'Could not disable the target on the server. Please try again.';

  @override
  String get priceTrackingDisabled => 'Price tracking disabled on the server';

  @override
  String get product => 'Product';

  @override
  String get productLinkMissing => 'Product link is unavailable';

  @override
  String selectedSize(String size) {
    return 'Selected size: $size';
  }

  @override
  String get selectedSizeUnavailable => 'The selected size is currently unavailable';

  @override
  String get serverUnavailableSavedLocally => 'The server is temporarily unavailable. The target was saved only on this device.';

  @override
  String get setTarget => 'Set';

  @override
  String sizeStoreCount(String size, int count) {
    return 'Size $size · stores: $count';
  }

  @override
  String get sizes => 'Sizes';

  @override
  String sizesLabel(String sizes) {
    return 'Sizes: $sizes';
  }

  @override
  String get store => 'Store';

  @override
  String get storePrices => 'Store prices';

  @override
  String get targetReached => 'Target reached!';

  @override
  String targetSavedServer(String price) {
    return 'Target saved on the server: $price';
  }

  @override
  String targetValue(String price) {
    return 'Target: $price';
  }

  @override
  String triggeredAtTarget(String triggeredPrice, String targetPrice) {
    return 'Triggered at $triggeredPrice • target $targetPrice';
  }

  @override
  String get tryDifferentSearch => 'Try changing the search or filters.';

  @override
  String get unavailableSizesGray => 'Currently unavailable sizes are shown in gray.';
}
