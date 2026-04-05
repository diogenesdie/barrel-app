// =============================================================================
// device_share.dart
//
// Modelo de compartilhamento de dispositivo ou grupo entre usuários.
// Não utiliza Hive — dados obtidos da API REST em tempo real.
//
// Status possíveis:
//   P = Pendente (aguardando aceite do destinatário)
//   A = Aceito
//   R = Revogado/Recusado
// =============================================================================

/// Representa um compartilhamento de dispositivo ou grupo entre dois usuários.
///
/// Sem persistência local — carregado do servidor a cada acesso.
/// Operações de aceite/revogação são feitas via [DeviceShareRepository].
class DeviceShare {
  final int id;
  final int ownerId;
  final String ownerName;
  final int sharedWithId;
  final String? sharedWithName;
  final int? deviceId;
  final int? groupId;
  final String? sharedItemName;
  final String status; // P = Pending, A = Accepted, R = Revoked
  final String? type; // 'device' or 'group'
  final DateTime? acceptedAt;
  final DateTime? revokedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeviceShare({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.sharedWithId,
    this.sharedWithName,
    this.deviceId,
    this.groupId,
    this.sharedItemName,
    required this.status,
    this.type,
    this.acceptedAt,
    this.revokedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Constrói um [DeviceShare] a partir do JSON retornado pela API REST.
  factory DeviceShare.fromJson(Map<String, dynamic> json) {
    return DeviceShare(
      id: json['id'],
      ownerId: json['owner_id'],
      ownerName: json['owner_name'],
      sharedWithId: json['shared_with_id'],
      sharedWithName: json['shared_with_name'],
      deviceId: json['device_id'],
      groupId: json['group_id'],
      sharedItemName: json['shared_item_name'],
      status: json['status'],
      type: json['type'],
      acceptedAt: json['accepted_at'] != null ? DateTime.parse(json['accepted_at']) : null,
      revokedAt: json['revoked_at'] != null ? DateTime.parse(json['revoked_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  /// Retorna [true] se o compartilhamento está aguardando aceite do destinatário.
  bool get isPending => status == 'P';

  /// Retorna [true] se o compartilhamento foi aceito.
  bool get isAccepted => status == 'A';

  /// Retorna [true] se o compartilhamento foi revogado ou recusado.
  bool get isRevoked => status == 'R';

  /// Retorna o tipo do compartilhamento como texto legível ('Dispositivo' ou 'Grupo').
  String get shareTypeText {
    if (deviceId != null) return 'Dispositivo';
    if (groupId != null) return 'Grupo';
    return 'Compartilhamento';
  }
}