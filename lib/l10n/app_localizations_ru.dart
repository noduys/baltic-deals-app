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
}
