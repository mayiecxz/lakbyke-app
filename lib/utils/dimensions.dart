/// Centralized dimension and spacing constants.
/// All UI elements should use these values for consistent spacing and sizing.
abstract class AppDimensions {
  // Padding & Margins
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  static const double paddingXXLarge = 48.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusRound = 30.0; // For pill-shaped buttons

  // Icon Sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;

  // Button Heights
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;

  // Logo Dimensions
  static const double logoWidth = 200.0;
  static const double logoHeight = 150.0;

  // Container Ratios (responsive)
  static const double waveHeightRatio = 0.4;
  static const double waveCurveRatio = 0.8;
  static const double containerMaxWidth = 0.9; // 90% of screen width
  static const double containerMaxHeight = 0.9; // 90% of screen height

  // Elevation
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;

  // Login Modal Dimensions
  static const double loginModalWidth = 0.9; // 90% of screen
  static const double loginModalMaxHeight = 0.9; // 90% of screen
  static const double loginModalRadius = 20.0;
  static const double loginModalPadding = 24.0;

  // Form Field Dimensions
  static const double formFieldRadius = 10.0;
  static const double formFieldHeight = 20.0;

  // Dashboard Dimensions
  static const double dashboardHeaderRadius = 40.0;
  static const double dashboardIconSize = 60.0;
  static const double dashboardMetricIconSize = 40.0;
  static const double dashboardSmallIconSize = 18.0;
  static const double dashboardActionIconSize = 30.0;
  static const double dashboardActionButtonRadius = 15.0;
  static const double dashboardActionButtonPadding = 15.0;
  static const double dashboardCurvedHeaderVerticalPadding = 15.0;

  // Onboarding Screen Dimensions
  static const double spacingSmall = 20.0;
  static const double spacingMedium = 20.0;
  static const double paddingHorizontal = 32.0;
  static const double paddingBottom = 40.0;
  static const double paddingTop = 20.0;
  static const double borderRadiusLarge = 30.0;
  static const double buttonPadding = 15.0;

  // Private constructor to prevent instantiation
  AppDimensions._();
}
