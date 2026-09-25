import 'package:equatable/equatable.dart';

/// Vínculo entre quem é acompanhado (monitored) e quem acompanha (viewer).
class FamilyLinkEntity extends Equatable {
  const FamilyLinkEntity({
    required this.id,
    required this.monitoredUserId,
    required this.viewerUserId,
    required this.status,
    this.monitoredUserName,
    this.viewerUserName,
    this.monitoredUserPhone,
    this.createdAt,
  });

  final String id;
  final String monitoredUserId;
  final String viewerUserId;
  final String status;
  final String? monitoredUserName;
  final String? viewerUserName;

  /// Telefone da pessoa acompanhada (botão "Ligar" do painel da família).
  final String? monitoredUserPhone;
  final DateTime? createdAt;

  bool get isAccepted => status == 'accepted';
  bool get isPending => status == 'pending';

  @override
  List<Object?> get props => [
    id,
    monitoredUserId,
    viewerUserId,
    status,
    monitoredUserName,
    viewerUserName,
    monitoredUserPhone,
    createdAt,
  ];
}
