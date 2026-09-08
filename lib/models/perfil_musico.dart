class PerfilMusico {
  final String perfilId;
  final String perfilNome;
  final String? perfilBio;
  final String? perfilCep;
  final double? perfilCoordenadas; // REAL no banco equivale a double no Dart
  final String? perfilCidade;
  final String? perfilObjetivo;
  final String? perfilArtistaReferencia;

  PerfilMusico({
    required this.perfilId,
    required this.perfilNome,
    this.perfilBio,
    this.perfilCep,
    this.perfilCoordenadas,
    this.perfilCidade,
    this.perfilObjetivo,
    this.perfilArtistaReferencia,
  });

  factory PerfilMusico.fromJson(Map<String, dynamic> json) {
    return PerfilMusico(
      perfilId: json['perfil_id'] ?? '',
      perfilNome: json['perfil_nome'] ?? '',
      perfilBio: json['perfil_bio'],
      perfilCep: json['perfil_cep'],
      perfilCoordenadas: json['perfil_coordenadas']?.toDouble(),
      perfilCidade: json['perfil_cidade'],
      perfilObjetivo: json['perfil_objetivo'],
      perfilArtistaReferencia: json['perfil_artista_referencia'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'perfil_id': perfilId,
      'perfil_nome': perfilNome,
      'perfil_bio': perfilBio,
      'perfil_cep': perfilCep,
      'perfil_coordenadas': perfilCoordenadas,
      'perfil_cidade': perfilCidade,
      'perfil_objetivo': perfilObjetivo,
      'perfil_artista_referencia': perfilArtistaReferencia,
    };
  }
}
