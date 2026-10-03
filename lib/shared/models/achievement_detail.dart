/// Rich achievement detail fetched from Supabase on demand.
/// Extends the lightweight local registry data with photos, hours, etc.
class AchievementDetail {
  final String id;
  final String? description;
  final Map<String, String> openingHours;
  final String? coverPhotoUrl;
  final List<String> photoUrls;
  final String? website;
  final String? phone;
  final String? city;
  final String? country;
  final DateTime? updatedAt;

  const AchievementDetail({
    required this.id,
    this.description,
    this.openingHours = const {},
    this.coverPhotoUrl,
    this.photoUrls = const [],
    this.website,
    this.phone,
    this.city,
    this.country,
    this.updatedAt,
  });

  factory AchievementDetail.fromJson(Map<String, dynamic> json) {
    final rawHours = json['opening_hours'];
    final hours = <String, String>{};
    if (rawHours is Map) {
      for (final entry in rawHours.entries) {
        hours[entry.key.toString()] = entry.value.toString();
      }
    }

    final rawPhotos = json['photo_urls'];
    final photos = <String>[];
    if (rawPhotos is List) {
      for (final url in rawPhotos) {
        if (url is String && url.isNotEmpty) photos.add(url);
      }
    }

    return AchievementDetail(
      id: json['id'] as String,
      description: json['description'] as String?,
      openingHours: hours,
      coverPhotoUrl: json['cover_photo_url'] as String?,
      photoUrls: photos,
      website: json['website'] as String?,
      phone: json['phone'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}
