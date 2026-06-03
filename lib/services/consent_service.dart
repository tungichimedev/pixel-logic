import 'dart:async';
import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConsentService {
  static final ConsentService _instance = ConsentService._();
  static ConsentService get instance => _instance;
  ConsentService._();

  bool _consentGiven = false;
  bool _consentRequested = false;
  bool get consentGiven => _consentGiven;
  bool get consentRequested => _consentRequested;

  /// Load persisted consent state (call at startup, before ads).
  Future<void> loadPersistedConsent() async {
    final prefs = await SharedPreferences.getInstance();
    _consentGiven = prefs.getBool('ad_consent_given') ?? false;
    _consentRequested = prefs.getBool('consent_requested') ?? false;
  }

  /// Request consent (ATT + GDPR/UMP). Call AFTER user has seen value
  /// (post-tutorial or post-first-puzzle, not at cold launch).
  /// Returns true if personalized ads are allowed.
  Future<bool> requestConsent() async {
    bool attAuthorized = true; // default true for non-iOS
    bool umpConsented = false;

    // 1. iOS ATT dialog (14.5+)
    if (Platform.isIOS) {
      try {
        final attStatus = await AppTrackingTransparency.requestTrackingAuthorization()
            .timeout(const Duration(seconds: 5), onTimeout: () => TrackingStatus.notDetermined);
        attAuthorized = attStatus == TrackingStatus.authorized;
        debugPrint('ATT status: $attStatus');
      } catch (e) {
        debugPrint('ATT not available: $e');
        attAuthorized = false;
      }
    }

    // 2. GDPR consent via Google UMP
    try {
      final completer = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () => completer.complete(),
        (error) {
          debugPrint('Consent info update error: ${error.message}');
          completer.complete();
        },
      );
      await completer.future.timeout(const Duration(seconds: 8), onTimeout: () {});

      if (await ConsentInformation.instance.isConsentFormAvailable()) {
        final formCompleter = Completer<void>();
        ConsentForm.loadAndShowConsentFormIfRequired((formError) {
          if (formError != null) {
            debugPrint('Consent form error: ${formError.message}');
          }
          formCompleter.complete();
        });
        await formCompleter.future.timeout(const Duration(seconds: 10), onTimeout: () {});
      }

      final status = await ConsentInformation.instance.getConsentStatus();
      umpConsented = status == ConsentStatus.obtained || status == ConsentStatus.notRequired;
    } catch (e) {
      debugPrint('UMP consent error: $e');
      umpConsented = false;
    }

    // Consent requires BOTH ATT (iOS) AND UMP to be positive
    _consentGiven = attAuthorized && umpConsented;
    _consentRequested = true;

    // Persist
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ad_consent_given', _consentGiven);
    await prefs.setBool('consent_requested', true);

    return _consentGiven;
  }

  /// Reset consent (for Settings opt-out)
  Future<void> resetConsent() async {
    ConsentInformation.instance.reset();
    _consentGiven = false;
    _consentRequested = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ad_consent_given', false);
    await prefs.setBool('consent_requested', false);
  }
}
