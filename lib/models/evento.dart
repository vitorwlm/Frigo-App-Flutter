// Registo do que aconteceu a cada alimento (para o ecrã Impacto)
enum TipoEvento { usado, deitadoFora }

class Evento {
  const Evento({
    required this.itemId,
    required this.nome,
    required this.tipo,
    required this.data,
    required this.pesoKg,
    this.motivo,
  });

  final String itemId;
  final String nome;
  final TipoEvento tipo;
  final DateTime data;
  final double pesoKg;
  // só nos deitados fora: 'Passou a validade', 'Estragou-se antes'…
  final String? motivo;
}
