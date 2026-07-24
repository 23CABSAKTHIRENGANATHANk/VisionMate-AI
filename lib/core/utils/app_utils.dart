// Shared utility helpers for the application.
class AppUtils {
  AppUtils._();

  static String formatStatus(String value) =>
      value.trim().isEmpty ? 'Ready' : value;
}
