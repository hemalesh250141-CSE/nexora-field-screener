/// Anonymous Citizen Watch Community Tip Model
class CitizenTip {
  final String tipId; // e.g. TIP-2026-91823
  final String category;
  final String description;
  final double? optionalLatitude;
  final double? optionalLongitude;
  final String? optionalMediaHash;
  final String submittedAtUtc;
  final String status; // 'SUBMITTED', 'TRIAGED', 'ASSIGNED'

  const CitizenTip({
    required this.tipId,
    required this.category,
    required this.description,
    this.optionalLatitude,
    this.optionalLongitude,
    this.optionalMediaHash,
    required this.submittedAtUtc,
    this.status = 'SUBMITTED',
  });

  Map<String, dynamic> toMap() {
    return {
      'tipId': tipId,
      'category': category,
      'description': description,
      'optionalLatitude': optionalLatitude,
      'optionalLongitude': optionalLongitude,
      'optionalMediaHash': optionalMediaHash,
      'submittedAtUtc': submittedAtUtc,
      'status': status,
    };
  }

  factory CitizenTip.fromMap(Map<String, dynamic> map) {
    return CitizenTip(
      tipId: map['tipId'] as String,
      category: map['category'] as String,
      description: map['description'] as String,
      optionalLatitude: (map['optionalLatitude'] as num?)?.toDouble(),
      optionalLongitude: (map['optionalLongitude'] as num?)?.toDouble(),
      optionalMediaHash: map['optionalMediaHash'] as String?,
      submittedAtUtc: map['submittedAtUtc'] as String,
      status: map['status'] as String? ?? 'SUBMITTED',
    );
  }
}
