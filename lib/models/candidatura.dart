class Candidatura {
  final String? candidaturaId;
  final String candidatoId;
  final String projetoId;
  final String candidaturaStatus;
  final DateTime? candidaturaData;

  Candidatura({
    this.candidaturaId,
    required this.candidatoId,
    required this.projetoId,
    this.candidaturaStatus = 'PENDENTE',
    this.candidaturaData,
  });

  factory Candidatura.fromJson(Map<String, dynamic> json) {
    return Candidatura(
      candidaturaId: json['candidatura_id'],
      candidatoId: json['candidato_id'],
      projetoId: json['projeto_id'],
      candidaturaStatus: json['candidatura_status'],
      candidaturaData: json['candidatura_data'] != null
          ? DateTime.parse(json['candidatura_data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'candidato_id': candidatoId,
      'projeto_id': projetoId,
      'candidatura_status': candidaturaStatus,
    };
  }
}
