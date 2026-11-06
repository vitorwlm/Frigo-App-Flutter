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

// Aviso dos sensores (porta, temperatura), para o ecrã Avisos.
// Mais tarde vem da tabela "eventos" do Supabase.
class AlertaSensor {
  const AlertaSensor({
    required this.titulo,
    required this.detalhe,
    required this.data,
  });

  final String titulo;
  final String detalhe;
  final DateTime data;
}

// Uma vez que a porta esteve aberta (ecrã 20)
class AberturaPorta {
  const AberturaPorta({
    required this.inicio,
    required this.duracao,
    required this.maxTemp,
  });

  final DateTime inicio;
  final Duration duracao;
  // temperatura mais alta na hora seguinte
  final double maxTemp;
}
