// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Baltic Deals';

  @override
  String get home => 'Главная';

  @override
  String get stores => 'Магазины';

  @override
  String get favorites => 'Избранное';

  @override
  String get settings => 'Настройки';

  @override
  String get topDeals => 'ТОП скидки';

  @override
  String get clothing => 'Одежда';

  @override
  String get shoes => 'Обувь';

  @override
  String get accessories => 'Аксессуары';

  @override
  String get beauty => 'Красота';

  @override
  String get perfume => 'Парфюмерия';

  @override
  String get technology => 'Техника';

  @override
  String get homeCategory => 'Дом';

  @override
  String get sport => 'Спорт';

  @override
  String get all => 'Все';

  @override
  String get allBrands => 'Все бренды';

  @override
  String get allStores => 'Все магазины';

  @override
  String get any => 'Любая';

  @override
  String get searchHint => 'Поиск по товару или бренду';

  @override
  String get minPrice => 'Цена от';

  @override
  String get maxPrice => 'Цена до';

  @override
  String get desiredPrice => 'Желаемая цена, €';

  @override
  String get priceExample => 'Например 49.99';

  @override
  String get minDiscount => 'Минимальная скидка';

  @override
  String get sort => 'Сортировка';

  @override
  String get biggestDiscount => 'Самая большая скидка';

  @override
  String get maximumSavings => 'Максимальная экономия';

  @override
  String get priceLow => 'Сначала дешевле';

  @override
  String get priceHigh => 'Сначала дороже';

  @override
  String get byBrand => 'По бренду';

  @override
  String get multiStoreOnly => 'Есть в нескольких магазинах';

  @override
  String get reset => 'Сбросить';

  @override
  String get refresh => 'Обновить';

  @override
  String get retry => 'Повторить';

  @override
  String get loadMore => 'Загрузить ещё';

  @override
  String get showAll => 'Показать все';

  @override
  String get details => 'Подробнее';

  @override
  String get compareStores => 'Сравнить магазины';

  @override
  String get bestPrice => 'Лучшая цена';

  @override
  String get coupon => 'КУПОН';

  @override
  String get addFavorite => 'Добавить в избранное';

  @override
  String get removeFavorite => 'Убрать из избранного';

  @override
  String get trackPrice => 'Отслеживать снижение цены';

  @override
  String get disable => 'Отключить';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get open => 'Открыть';

  @override
  String get language => 'Язык';

  @override
  String get systemLanguage => 'Язык устройства';

  @override
  String get estonian => 'Эстонский';

  @override
  String get english => 'Английский';

  @override
  String get russian => 'Русский';

  @override
  String get loadingError => 'Не удалось загрузить товары';

  @override
  String get noProducts => 'Товары не найдены';

  @override
  String foundProducts(int count) {
    return 'Найдено: $count';
  }

  @override
  String loadedProducts(int count) {
    return 'Загружено: $count';
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
      other: '$count магазина',
      many: '$count магазинов',
      few: '$count магазина',
      one: '1 магазин',
    );
    return '$_temp0';
  }

  @override
  String savingsUpTo(String amount) {
    return 'Экономия до $amount €';
  }

  @override
  String availableCount(int count) {
    return 'Доступно: $count';
  }

  @override
  String bestPriceValue(String price) {
    return 'Лучшая цена: $price';
  }

  @override
  String get category => 'Категория';

  @override
  String get changeTarget => 'Изменить';

  @override
  String get chooseSize => 'Выбери размер, чтобы сравнить магазины';

  @override
  String get country => 'Страна';

  @override
  String currentPriceLabel(String price) {
    return 'Текущая цена: $price';
  }

  @override
  String get filters => 'Фильтры';

  @override
  String get gender => 'Пол';

  @override
  String get goToStore => 'Перейти в магазин';

  @override
  String get hideFilters => 'Скрыть фильтры';

  @override
  String historyPoints(int count) {
    return 'Точек истории: $count';
  }

  @override
  String get historyStarted => 'История только начала собираться. Новые точки появятся при изменении цены.';

  @override
  String get inStock => 'В наличии';

  @override
  String get invalidPrice => 'Введите корректную цену';

  @override
  String get invalidProductLink => 'Некорректная ссылка на товар';

  @override
  String get loadOffersFailed => 'Не удалось загрузить предложения';

  @override
  String get loadPriceHistoryFailed => 'Не удалось загрузить историю цены';

  @override
  String get loadSizesFailed => 'Не удалось загрузить размеры';

  @override
  String get loadingSizes => 'Загружаем доступные размеры…';

  @override
  String get maximum => 'Максимум';

  @override
  String get minimum => 'Минимум';

  @override
  String get noOffers => 'Предложений пока нет';

  @override
  String get noSizeData => 'Данные о размерах для этого товара пока не загружены.';

  @override
  String get notSpecified => 'Не указано';

  @override
  String get now => 'Сейчас';

  @override
  String get openStoreFailed => 'Не удалось открыть магазин';

  @override
  String priceAboveTarget(String amount) {
    return 'Текущая цена выше цели на $amount';
  }

  @override
  String get priceAlertInfo => 'Цель сохраняется на сервере Baltic Deals. Когда цена достигнет цели, приложение отправит push-уведомление.';

  @override
  String get priceAlertPrompt => 'Сохраним желаемую цену для этого товара';

  @override
  String get priceAlreadyReached => 'Цена уже достигла заданного уровня';

  @override
  String get priceHistory => 'История цены';

  @override
  String get priceTrackingDisableFailed => 'Не удалось отключить цель на сервере. Попробуйте ещё раз.';

  @override
  String get priceTrackingDisabled => 'Отслеживание цены отключено на сервере';

  @override
  String get product => 'Товар';

  @override
  String get productLinkMissing => 'Ссылка на товар отсутствует';

  @override
  String selectedSize(String size) {
    return 'Выбран размер: $size';
  }

  @override
  String get selectedSizeUnavailable => 'Выбранный размер сейчас недоступен';

  @override
  String get serverUnavailableSavedLocally => 'Сервер временно недоступен. Цель сохранена только на этом устройстве.';

  @override
  String get setTarget => 'Задать';

  @override
  String sizeStoreCount(String size, int count) {
    return 'Размер $size · магазинов: $count';
  }

  @override
  String get sizes => 'Размеры';

  @override
  String sizesLabel(String sizes) {
    return 'Размеры: $sizes';
  }

  @override
  String get store => 'Магазин';

  @override
  String get storePrices => 'Цены в магазинах';

  @override
  String get targetReached => 'Цена достигнута!';

  @override
  String targetSavedServer(String price) {
    return 'Цель сохранена на сервере: $price';
  }

  @override
  String targetValue(String price) {
    return 'Цель: $price';
  }

  @override
  String triggeredAtTarget(String triggeredPrice, String targetPrice) {
    return 'Сработало при $triggeredPrice • цель $targetPrice';
  }

  @override
  String get tryDifferentSearch => 'Попробуй изменить поиск или фильтры.';

  @override
  String get unavailableSizesGray => 'Недоступные сейчас размеры показаны серым.';
}
