/// NEXORA API Endpoints Configuration
class ApiEndpoints {
  ApiEndpoints._();

  static const String defaultBaseUrl = 'http://127.0.0.1:8000';

  static String baseUrl = defaultBaseUrl;

  static String get login => '$baseUrl/auth/login';
  static String get me => '$baseUrl/auth/me';
  static String get evidence => '$baseUrl/evidence';
  static String evidenceById(String id) => '$baseUrl/evidence/$id';
  static String evidenceVerify(String id) => '$baseUrl/evidence/$id/verify';
  static String get sync => '$baseUrl/sync';
  static String get audit => '$baseUrl/audit';
  static String get referenceProfiles => '$baseUrl/reference-profiles';
  static String get citizenTips => '$baseUrl/citizen-tips';
  static String get health => '$baseUrl/health';
}
