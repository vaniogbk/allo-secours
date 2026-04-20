class AppConfig {
  AppConfig._();

  // ── CLOUDINARY ──
  static const String cloudinaryCloudName = 'dlpanhjnh';
  static const String cloudinaryUploadPreset = 'rogerdjossou';
  static const String cloudinaryApiKey = '995598818692766';

  // URL d'upload
  static String get cloudinaryUploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload';

  // Optimisation automatique des images
  static String optimizeUrl(String url, {int width = 800}) {
    if (url.isEmpty) return '';
    return url.replaceFirst(
      '/upload/',
      '/upload/w_$width,q_auto,f_auto/',
    );
  }

  // Thumbnail pour les listes
  static String thumbnailUrl(String url) =>
      optimizeUrl(url, width: 400);
}