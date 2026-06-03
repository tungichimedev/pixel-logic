import 'dart:async';
import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ConsentService {
  static final ConsentService _instance = ConsentService._();
  static ConsentService get instance => _instance;
  ConsentService._();

  bool _consentGiven = false;
  bool get consentGiven => _consentGiven;

  /// Request consent (GDPR via UMP + ATT on iOS).
  /// Returns true if user gave consent for personalized ads.
  Future<bool> requestConsent() async {
    // 1. iOS ATT dialog (14.5+) — skip on simulator
    if (Platform.isIOS) {
      try {
        final attStatus = await AppTrackingTransparency.requestTrackingAuthorization()
            .timeout(const Duration(seconds: 5), onTimeout: () => TrackingStatus.notDetermined);
        _consentGiven = attStatus == TrackingStatus.authorized;
        debugPrint('ATT status: $attStatus');
      } catch (e) {
        debugPrint('ATT not available (simulator?): $e');
        _consentGiven = false;
      }
    }

    // 2. GDPR consent via Google UMP
    try {
      final completer = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () => completer.complete(), // onConsentInfoUpdateSuccess
        (error) {
          debugPrint('Consent info update error: ${error.message}');
          completer.complete();
        }, // onConsentInfoUpdateFailure
      );
      await completer.future;

      if (await ConsentInformation.instance.isConsentFormAvailable()) {
        final formCompleter = Completer<void>();
        ConsentForm.loadAndShowConsentFormIfRequired((formError) {
          if (formError != null) {
            debugPrint('Consent form error: ${formError.message}');
          }
          formCompleter.complete();
        });
        await formCompleter.future;
      }

      final status = await ConsentInformation.instance.getConsentStatus();
      if (status == ConsentStatus.obtained || status == ConsentStatus.notRequired) {
        _consentGiven = true;
      }
    } catch (e) {
      debugPrint('UMP consent error: $e');
      _consentGiven = false;
    }

    return _consentGiven;
  }

  /// Reset consent (for Settings opt-out)
  Future<void> resetConsent() async {
    ConsentInformation.instance.reset();
    _consentGiven = false;
  }
}
