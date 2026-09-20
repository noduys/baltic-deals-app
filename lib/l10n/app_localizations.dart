import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_et.dart';
import 'app_localizations_lt.dart';
import 'app_localizations_lv.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('et'),
    Locale('lt'),
    Locale('lv'),
    Locale('ru')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Baltic Deals'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @stores.
  ///
  /// In en, this message translates to:
  /// **'Stores'**
  String get stores;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @topDeals.
  ///
  /// In en, this message translates to:
  /// **'Top deals'**
  String get topDeals;

  /// No description provided for @clothing.
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get clothing;

  /// No description provided for @shoes.
  ///
  /// In en, this message translates to:
  /// **'Shoes'**
  String get shoes;

  /// No description provided for @accessories.
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get accessories;

  /// No description provided for @beauty.
  ///
  /// In en, this message translates to:
  /// **'Beauty'**
  String get beauty;

  /// No description provided for @perfume.
  ///
  /// In en, this message translates to:
  /// **'Perfume'**
  String get perfume;

  /// No description provided for @technology.
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get technology;

  /// No description provided for @homeCategory.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeCategory;

  /// No description provided for @sport.
  ///
  /// In en, this message translates to:
  /// **'Sport'**
  String get sport;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @allBrands.
  ///
  /// In en, this message translates to:
  /// **'All brands'**
  String get allBrands;

  /// No description provided for @allStores.
  ///
  /// In en, this message translates to:
  /// **'All stores'**
  String get allStores;

  /// No description provided for @any.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get any;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by product or brand'**
  String get searchHint;

  /// No description provided for @minPrice.
  ///
  /// In en, this message translates to:
  /// **'Min price'**
  String get minPrice;

  /// No description provided for @maxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max price'**
  String get maxPrice;

  /// No description provided for @desiredPrice.
  ///
  /// In en, this message translates to:
  /// **'Desired price, €'**
  String get desiredPrice;

  /// No description provided for @priceExample.
  ///
  /// In en, this message translates to:
  /// **'For example 49.99'**
  String get priceExample;

  /// No description provided for @minDiscount.
  ///
  /// In en, this message translates to:
  /// **'Minimum discount'**
  String get minDiscount;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @biggestDiscount.
  ///
  /// In en, this message translates to:
  /// **'Biggest discount'**
  String get biggestDiscount;

  /// No description provided for @maximumSavings.
  ///
  /// In en, this message translates to:
  /// **'Maximum savings'**
  String get maximumSavings;

  /// No description provided for @priceLow.
  ///
  /// In en, this message translates to:
  /// **'Lowest price'**
  String get priceLow;

  /// No description provided for @priceHigh.
  ///
  /// In en, this message translates to:
  /// **'Highest price'**
  String get priceHigh;

  /// No description provided for @byBrand.
  ///
  /// In en, this message translates to:
  /// **'By brand'**
  String get byBrand;

  /// No description provided for @multiStoreOnly.
  ///
  /// In en, this message translates to:
  /// **'Available in multiple stores'**
  String get multiStoreOnly;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get showAll;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @compareStores.
  ///
  /// In en, this message translates to:
  /// **'Compare stores'**
  String get compareStores;

  /// No description provided for @bestPrice.
  ///
  /// In en, this message translates to:
  /// **'Best price'**
  String get bestPrice;

  /// No description provided for @coupon.
  ///
  /// In en, this message translates to:
  /// **'COUPON'**
  String get coupon;

  /// No description provided for @addFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addFavorite;

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFavorite;

  /// No description provided for @trackPrice.
  ///
  /// In en, this message translates to:
  /// **'Track price drop'**
  String get trackPrice;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get systemLanguage;

  /// No description provided for @estonian.
  ///
  /// In en, this message translates to:
  /// **'Estonian'**
  String get estonian;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russian;

  /// No description provided for @loadingError.
  ///
  /// In en, this message translates to:
  /// **'Could not load products'**
  String get loadingError;

  /// No description provided for @noProducts.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProducts;

  /// No description provided for @foundProducts.
  ///
  /// In en, this message translates to:
  /// **'Found: {count}'**
  String foundProducts(int count);

  /// No description provided for @loadedProducts.
  ///
  /// In en, this message translates to:
  /// **'Loaded: {count}'**
  String loadedProducts(int count);

  /// No description provided for @discountBadge.
  ///
  /// In en, this message translates to:
  /// **'-{percent}%'**
  String discountBadge(int percent);

  /// No description provided for @storesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 store} other{{count} stores}}'**
  String storesCount(int count);

  /// No description provided for @savingsUpTo.
  ///
  /// In en, this message translates to:
  /// **'Save up to {amount} €'**
  String savingsUpTo(String amount);

  /// No description provided for @availableCount.
  ///
  /// In en, this message translates to:
  /// **'Available: {count}'**
  String availableCount(int count);

  /// No description provided for @bestPriceValue.
  ///
  /// In en, this message translates to:
  /// **'Best price: {price}'**
  String bestPriceValue(String price);

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @changeTarget.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeTarget;

  /// No description provided for @chooseSize.
  ///
  /// In en, this message translates to:
  /// **'Choose a size to compare stores'**
  String get chooseSize;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @currentPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Current price: {price}'**
  String currentPriceLabel(String price);

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @goToStore.
  ///
  /// In en, this message translates to:
  /// **'Go to store'**
  String get goToStore;

  /// No description provided for @hideFilters.
  ///
  /// In en, this message translates to:
  /// **'Hide filters'**
  String get hideFilters;

  /// No description provided for @historyPoints.
  ///
  /// In en, this message translates to:
  /// **'History points: {count}'**
  String historyPoints(int count);

  /// No description provided for @historyStarted.
  ///
  /// In en, this message translates to:
  /// **'Price history has just started. New points will appear when the price changes.'**
  String get historyStarted;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get inStock;

  /// No description provided for @invalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price'**
  String get invalidPrice;

  /// No description provided for @invalidProductLink.
  ///
  /// In en, this message translates to:
  /// **'Invalid product link'**
  String get invalidProductLink;

  /// No description provided for @loadOffersFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load offers'**
  String get loadOffersFailed;

  /// No description provided for @loadPriceHistoryFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load price history'**
  String get loadPriceHistoryFailed;

  /// No description provided for @loadSizesFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load sizes'**
  String get loadSizesFailed;

  /// No description provided for @loadingSizes.
  ///
  /// In en, this message translates to:
  /// **'Loading available sizes…'**
  String get loadingSizes;

  /// No description provided for @maximum.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get maximum;

  /// No description provided for @minimum.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get minimum;

  /// No description provided for @noOffers.
  ///
  /// In en, this message translates to:
  /// **'No offers yet'**
  String get noOffers;

  /// No description provided for @noSizeData.
  ///
  /// In en, this message translates to:
  /// **'Size data for this product is not available yet.'**
  String get noSizeData;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @openStoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the store'**
  String get openStoreFailed;

  /// No description provided for @priceAboveTarget.
  ///
  /// In en, this message translates to:
  /// **'Current price is {amount} above the target'**
  String priceAboveTarget(String amount);

  /// No description provided for @priceAlertInfo.
  ///
  /// In en, this message translates to:
  /// **'The target is saved on the Baltic Deals server. When the price reaches the target, the app will send a push notification.'**
  String get priceAlertInfo;

  /// No description provided for @priceAlertPrompt.
  ///
  /// In en, this message translates to:
  /// **'Save your desired price for this product'**
  String get priceAlertPrompt;

  /// No description provided for @priceAlreadyReached.
  ///
  /// In en, this message translates to:
  /// **'The price has already reached the target level'**
  String get priceAlreadyReached;

  /// No description provided for @priceHistory.
  ///
  /// In en, this message translates to:
  /// **'Price history'**
  String get priceHistory;

  /// No description provided for @priceTrackingDisableFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not disable the target on the server. Please try again.'**
  String get priceTrackingDisableFailed;

  /// No description provided for @priceTrackingDisabled.
  ///
  /// In en, this message translates to:
  /// **'Price tracking disabled on the server'**
  String get priceTrackingDisabled;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @productLinkMissing.
  ///
  /// In en, this message translates to:
  /// **'Product link is unavailable'**
  String get productLinkMissing;

  /// No description provided for @selectedSize.
  ///
  /// In en, this message translates to:
  /// **'Selected size: {size}'**
  String selectedSize(String size);

  /// No description provided for @selectedSizeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The selected size is currently unavailable'**
  String get selectedSizeUnavailable;

  /// No description provided for @serverUnavailableSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'The server is temporarily unavailable. The target was saved only on this device.'**
  String get serverUnavailableSavedLocally;

  /// No description provided for @setTarget.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get setTarget;

  /// No description provided for @sizeStoreCount.
  ///
  /// In en, this message translates to:
  /// **'Size {size} · stores: {count}'**
  String sizeStoreCount(String size, int count);

  /// No description provided for @sizes.
  ///
  /// In en, this message translates to:
  /// **'Sizes'**
  String get sizes;

  /// No description provided for @sizesLabel.
  ///
  /// In en, this message translates to:
  /// **'Sizes: {sizes}'**
  String sizesLabel(String sizes);

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @storePrices.
  ///
  /// In en, this message translates to:
  /// **'Store prices'**
  String get storePrices;

  /// No description provided for @targetReached.
  ///
  /// In en, this message translates to:
  /// **'Target reached!'**
  String get targetReached;

  /// No description provided for @targetSavedServer.
  ///
  /// In en, this message translates to:
  /// **'Target saved on the server: {price}'**
  String targetSavedServer(String price);

  /// No description provided for @targetValue.
  ///
  /// In en, this message translates to:
  /// **'Target: {price}'**
  String targetValue(String price);

  /// No description provided for @triggeredAtTarget.
  ///
  /// In en, this message translates to:
  /// **'Triggered at {triggeredPrice} • target {targetPrice}'**
  String triggeredAtTarget(String triggeredPrice, String targetPrice);

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try changing the search or filters.'**
  String get tryDifferentSearch;

  /// No description provided for @unavailableSizesGray.
  ///
  /// In en, this message translates to:
  /// **'Currently unavailable sizes are shown in gray.'**
  String get unavailableSizesGray;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'et', 'lt', 'lv', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'et': return AppLocalizationsEt();
    case 'lt': return AppLocalizationsLt();
    case 'lv': return AppLocalizationsLv();
    case 'ru': return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
