import 'package:flutter/material.dart';

/// Тип иллюстрации для пустого состояния.
enum EmptyStateType { search, alerts, offline, product }

/// Размер виджета.
enum EmptyStateSize { normal, compact, tiny }

class EmptyState extends StatelessWidget {
  final EmptyStateType type;
  final EmptyStateSize size;
  final String? title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool hasMore;
  final bool loadingMore;
  final VoidCallback? onLoadMore;

  const EmptyState({
    super.key,
    required this.type,
    this.size = EmptyStateSize.normal,
    this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.hasMore = false,
    this.loadingMore = false,
    this.onLoadMore,
  });

  String get _assetPath {
    switch (type) {
      case EmptyStateType.search:
        return 'assets/illustrations/search.png';
      case EmptyStateType.alerts:
        return 'assets/illustrations/alerts.png';
      case EmptyStateType.offline:
        return 'assets/illustrations/offline.png';
      case EmptyStateType.product:
        return 'assets/illustrations/product.png';
    }
  }

  double get _imageSize {
    switch (size) {
      case EmptyStateSize.normal:
        return 140;
      case EmptyStateSize.compact:
        return 80;
      case EmptyStateSize.tiny:
        return 40;
    }
  }

  double get _titleSize {
    switch (size) {
      case EmptyStateSize.normal:
        return 18;
      case EmptyStateSize.compact:
        return 15;
      case EmptyStateSize.tiny:
        return 11;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case EmptyStateSize.normal:
        return const EdgeInsets.all(24);
      case EmptyStateSize.compact:
        return const EdgeInsets.all(16);
      case EmptyStateSize.tiny:
        return const EdgeInsets.all(4);
    }
  }

  String get _defaultTitle {
    switch (type) {
      case EmptyStateType.search:
        return 'Ничего не найдено';
      case EmptyStateType.alerts:
        return 'Нет алертов';
      case EmptyStateType.offline:
        return 'Нет подключения';
      case EmptyStateType.product:
        return 'Нет изображения';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedTitle = title ?? _defaultTitle;
    final showTitle = size != EmptyStateSize.tiny;

    return Center(
      child: Padding(
        padding: _padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              _assetPath,
              width: _imageSize,
              height: _imageSize,
              fit: BoxFit.contain,
              color: isDark ? Colors.white.withValues(alpha: 0.9) : null,
              colorBlendMode: isDark ? BlendMode.modulate : null,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.image_not_supported_outlined,
                size: _imageSize * 0.6,
                color: theme.disabledColor,
              ),
            ),

            if (showTitle) ...[
              const SizedBox(height: 16),
              Text(
                resolvedTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _titleSize,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],

            if (_resolvedSubtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                _resolvedSubtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: size == EmptyStateSize.tiny ? 10 : 13,
                ),
              ),
            ],

            if (_resolvedActionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(_resolvedActionLabel!),
              ),
            ],

            if (type == EmptyStateType.search && hasMore) ...[
              const SizedBox(height: 16),
              if (loadingMore)
                const CircularProgressIndicator()
              else if (onLoadMore != null)
                FilledButton.icon(
                  onPressed: onLoadMore,
                  icon: const Icon(Icons.expand_more),
                  label: const Text('Загрузить еще'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String? get _resolvedSubtitle {
    if (subtitle != null) return subtitle;
    if (type == EmptyStateType.search && hasMore) {
      return 'Попробуйте изменить поиск или фильтры.';
    }
    return null;
  }

  String? get _resolvedActionLabel {
    if (actionLabel != null) return actionLabel;
    return null;
  }
}
