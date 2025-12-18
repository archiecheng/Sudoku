
import 'package:flutter/foundation.dart';

abstract class AdManager {
  Future<void> showInterstitialAd();
  Future<bool> showRewardedAd();
}

class DummyAdManager implements AdManager {
  @override
  Future<void> showInterstitialAd() async {
    debugPrint("AdManager: Showing Interstitial Ad (Simulated)");
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<bool> showRewardedAd() async {
    debugPrint("AdManager: Showing Rewarded Ad (Simulated)");
    await Future.delayed(const Duration(seconds: 1));
    return true; // Reward granted
  }
}

abstract class PurchaseManager {
  Future<void> restorePurchases();
  Future<bool> buyNoAds();
  bool get isNoAdsPurchased;
}

class DummyPurchaseManager implements PurchaseManager {
  bool _isNoAds = false;

  @override
  Future<void> restorePurchases() async {
    debugPrint("PurchaseManager: Restoring purchases...");
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<bool> buyNoAds() async {
     debugPrint("PurchaseManager: Buying No Ads...");
     await Future.delayed(const Duration(milliseconds: 500));
     _isNoAds = true;
     return true;
  }

  @override
  bool get isNoAdsPurchased => _isNoAds;
}
