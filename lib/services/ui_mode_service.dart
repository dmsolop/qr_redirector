enum UiMode { foregroundDisabled, foregroundAuto }

class UiModeService {
  // Route-driven mode (determined by current screen)
  static UiMode _routeMode = UiMode.foregroundAuto;

  // Temporary override (e.g., while alert is visible)
  static UiMode? _overrideMode;

  static void setRouteMode(UiMode mode) {
    _routeMode = mode;
  }

  static void pushOverride(UiMode mode) {
    _overrideMode = mode;
  }

  static void clearOverride() {
    _overrideMode = null;
  }

  static UiMode get effectiveMode => _overrideMode ?? _routeMode;

  static bool get isForegroundAuto => effectiveMode == UiMode.foregroundAuto;
}

