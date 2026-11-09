// * Registo do que aconteceu a cada alimento. O frigorifico cria um Evento em
// * cada usar() ou deitarFora(), e o ecrã Impacto soma-os para mostrar o que
// * foi aproveitado e o que foi para o lixo (ODS 12.3).
// * enum porque só há dois tipos possíveis e o compilador avisa se faltar um
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
  // ? em kg para o Impacto conseguir somar alimentos com unidades diferentes
  final double pesoKg;
  // ? só nos deitados fora: 'Passou a validade', 'Estragou-se antes'…
  // ? (o Impacto mostra os motivos mais comuns)
  final String? motivo;
}

// ? Aviso dos sensores (porta, temperatura), para o ecrã Avisos.
// ? Criado no frigorifico a partir da tabela "eventos" do Supabase
// ? (ou de exemplo, enquanto a placa não envia nada).
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

// ? Uma vez que a porta esteve aberta (ecrã 20): o gráfico do Histórico da
// ? temperatura marca-as para se ver porque é que a temperatura subiu
class AberturaPorta {
  const AberturaPorta({
    required this.inicio,
    required this.duracao,
    required this.maxTemp,
  });

  final DateTime inicio;
  final Duration duracao;
  // ? temperatura mais alta na hora seguinte (o pico que a abertura causou)
  final double maxTemp;
}
