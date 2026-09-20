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
}
