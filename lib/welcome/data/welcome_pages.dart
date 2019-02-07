import 'package:flutter/material.dart';

class PageViewModel {
  final Color color;
  final String heroAssetPath;
  final String title;
  final String body;
  final String iconAssetPath;

  PageViewModel(
    this.color,
    this.heroAssetPath,
    this.title,
    this.body,
    this.iconAssetPath,
  );
}

List<PageViewModel> welcomePages(BuildContext context) {
  return [
    new PageViewModel(
      const Color(0xFF678FB4),
      'assets/hotels.png',
      'Hotels',
      'All hotels and hostels are sorted by hospitality rating',
      'assets/key.png',
    ),
    new PageViewModel(
      const Color(0xFF65B0B4),
      'assets/banks.png',
      'Banks',
      'All bank accounts on your phone',
      'assets/wallet.png',
    ),
    new PageViewModel(
      const Color(0xFF9B90BC),
      'assets/stores.png',
      'Store',
      'All local stores are categorized for your convenience',
      'assets/shopping_cart.png',
    ),
  ];
}
