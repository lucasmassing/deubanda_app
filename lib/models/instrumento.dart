class Instrumento {
  final int instrumentoId;
  final String instrumentoNome;

  Instrumento({required this.instrumentoId, required this.instrumentoNome});

  factory Instrumento.fromJson(Map<String, dynamic> json) {
    return Instrumento(
      instrumentoId: json['instrumento_id'],
      instrumentoNome: json['instrumento_nome'],
    );
  }
}

class MusicoInstrumento {
  final String musicoId;
  final int instrumentoId;
  final String? instrumentoNivel;
  final String?
  instrumentoNome;

  MusicoInstrumento({
    required this.musicoId,
    required this.instrumentoId,
    this.instrumentoNivel,
    this.instrumentoNome,
  });

  factory MusicoInstrumento.fromJson(Map<String, dynamic> json) {
    return MusicoInstrumento(
      musicoId: json['musico_id'],
      instrumentoId: json['instrumento_id'],
      instrumentoNivel: json['instrumento_nivel'],
      instrumentoNome: json['instrumentos']?['instrumento_nome'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'musico_id': musicoId,
      'instrumento_id': instrumentoId,
      'instrumento_nivel': instrumentoNivel,
    };
  }
}
