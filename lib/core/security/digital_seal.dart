/// Tamper-Evident Digital Seal
/// Represents the cryptographic seal applied to an evidence payload.
class DigitalSeal {
  final String algorithm;
  final String version;
  final String evidenceHash;
  final String canonicalPayload;
  final String sealedAtUtc;
  final String keyIdentifier;
  final String? signature;

  const DigitalSeal({
    required this.algorithm,
    required this.version,
    required this.evidenceHash,
    required this.canonicalPayload,
    required this.sealedAtUtc,
    this.keyIdentifier = 'DEVICE_SEAL_KEY_V1',
    this.signature,
  });

  Map<String, dynamic> toMap() {
    return {
      'algorithm': algorithm,
      'version': version,
      'evidenceHash': evidenceHash,
      'canonicalPayload': canonicalPayload,
      'sealedAtUtc': sealedAtUtc,
      'keyIdentifier': keyIdentifier,
      'signature': signature,
    };
  }

  factory DigitalSeal.fromMap(Map<String, dynamic> map) {
    return DigitalSeal(
      algorithm: map['algorithm'] as String? ?? 'SHA-256',
      version: map['version'] as String? ?? '1.0',
      evidenceHash: map['evidenceHash'] as String,
      canonicalPayload: map['canonicalPayload'] as String,
      sealedAtUtc: map['sealedAtUtc'] as String,
      keyIdentifier: map['keyIdentifier'] as String? ?? 'DEVICE_SEAL_KEY_V1',
      signature: map['signature'] as String?,
    );
  }
}
