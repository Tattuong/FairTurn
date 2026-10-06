import 'package:fairturn/core/constants/iap_constants.dart';
import 'package:fairturn/core/services/iap_config_service.dart';
import 'package:fairturn/models/shop_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FairTurn IAP ids and N299 endpoint', () {
    expect(IapConstants.productPrefix, 'ft');
    expect(IapConstants.remoteConfigUrl,
        'https://api2.blwsmartware.net/N299.json');
    expect(IapConstants.coinPackIds.first, 'ft_pack_1');
    expect(IapConstants.coinPackIds.last, 'ft_pack_10');
    expect(IapConstants.coinPackIds, hasLength(10));
    expect(IapConstants.removeAdsProductId, 'ft_remove_ads');
    expect(IapConstants.proProductId, 'ft_pro');
    expect(IapConstants.allProductIds,
        containsAll([...IapConstants.coinPackIds, 'ft_remove_ads', 'ft_pro']));
    expect(IapConstants.coinsForProduct('ft_pack_5'), 500);
    expect(IapConstants.freeArchiveLimit, 8);
    expect(IapConstants.proArchiveLimit, 99);
  });

  test('disable=1 hides billing only', () {
    final off = IapRemoteConfig.fromJson({'disable': 1, 'name': 'FairTurn'});
    expect(off.billingDisabled, isTrue);
    final on = IapRemoteConfig.fromJson(
        {'disable': 0, 'name': 'FairTurn', 'code': 'FULL_IAP'});
    expect(on.billingDisabled, isFalse);
    expect(on.name, 'FairTurn');
  });

  test('shop catalog extras can be applied and reverted', () {
    expect(
        ShopCatalog.items.where((e) => e.id.startsWith('theme_')), isNotEmpty);
    expect(ShopCatalog.find(ShopCatalog.featPro), isNotNull);
    expect(ShopCatalog.find('remove_ads'), isNotNull);
    expect(ShopCatalog.find(ShopCatalog.featHint), isNotNull);
    expect(ShopCatalog.find(ShopCatalog.featSound), isNotNull);
    expect(ShopCatalog.isDefaultId(ShopCatalog.defaultThemeId), isTrue);
  });
}
