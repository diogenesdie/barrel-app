class DeviceShare {
  final int id;
  final int ownerId;
  final String ownerName;
  final int sharedWithId;
  final int? deviceId;
  final int? groupId;
  final String status; // P = Pending, A = Accepted, R = Revoked
  final DateTime? acceptedAt;
  final DateTime? revokedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeviceShare({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.sharedWithId,
    this.deviceId,
    this.groupId,
    required this.status,
    this.acceptedAt,
    this.revokedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeviceShare.fromJson(Map<String, dynamic> json) {
    return DeviceShare(
      id: json['id'],
      ownerId: json['owner_id'],
      ownerName: json['owner_name'],
      sharedWithId: json['shared_with_id'],
      deviceId: json['device_id'],
      groupId: json['group_id'],
      status: json['status'],
      acceptedAt: json['accepted_at'] != null ? DateTime.parse(json['accepted_at']) : null,
      revokedAt: json['revoked_at'] != null ? DateTime.parse(json['revoked_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  bool get isPending => status == 'P';
  bool get isAccepted => status == 'A';
  bool get isRevoked => status == 'R';

  String get shareTypeText {
    if (deviceId != null) return 'Dispositivo';
    if (groupId != null) return 'Grupo';
    return 'Compartilhamento';
  }
}