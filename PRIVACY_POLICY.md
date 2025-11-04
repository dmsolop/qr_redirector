# Privacy Policy

**Last updated:** October 31, 2025

## Developer Information

**Developer:** Dmytro Solop  
**Contact:** dmtsolop@gmail.com 
**Application:** LinkFlow (ua.dmtsol.qrredirector)

## Overview

LinkFlow is a utility application that processes deep links and redirects them to configured URLs in your web browser. This privacy policy explains how the application handles your data.

## Data Collection and Storage

**No Data Collection:** LinkFlow does not collect, store, or transmit any personal data to external servers or third parties.

**Local Storage Only:** All application data, including:
- Project configurations (regex patterns, URL templates)
- Application settings
- Preference data

is stored exclusively on your device using Android's SharedPreferences. This data never leaves your device.

## Permissions Used

The application requests the following permissions for its core functionality:

- **INTERNET:** Required to open URLs in your web browser after QR code processing.
- **FOREGROUND_SERVICE:** Allows the application to run a background service that listens for deep link intents, enabling QR code processing even when the app is not in the foreground.
- **WAKE_LOCK:** Ensures the background service operates reliably when processing QR codes.
- **USE_BIOMETRIC / USE_FINGERPRINT:** Used exclusively for local device owner verification when accessing application settings. Biometric data is processed entirely by your device's operating system and is never accessed by the application or transmitted anywhere.

## Biometric Authentication

LinkFlow uses your device's biometric authentication (Face ID, Touch ID, or device password) only to verify that you are the device owner before allowing access to application settings. All biometric processing is handled by your device's operating system. The application does not:
- Access your biometric data
- Store biometric information
- Transmit biometric data to any external service

## Deep Links

The application processes deep links with the custom scheme `reich://`. These links are processed locally on your device and redirected to configured URLs in your web browser. No information about scanned QR codes or deep links is collected or transmitted.

## Data Sharing

LinkFlow does not share any data with third parties, analytics services, advertising networks, or any external services.

## Data Deletion

All data stored by LinkFlow is stored locally on your device. To delete all application data:
1. Uninstall the application from your device

All locally stored preferences and configurations will be removed with the application.

## Children's Privacy

LinkFlow does not knowingly collect any information from children under 13. The application does not collect any information from anyone.

## Changes to This Privacy Policy

We may update this Privacy Policy from time to time. Any changes will be posted on this page with an updated "Last updated" date. You are advised to review this Privacy Policy periodically for any changes.

## Contact Us

If you have any questions about this Privacy Policy, please contact us at: [Ваш email]

---

**Note:** This privacy policy applies to LinkFlow version 1.0.0 and later.

