
  // Diz ao Flutter qual é a classe que guarda o estado deste widget.
  @override
  State<HomeShell></homeshell> createState() => _HomeShellState();
}

// _HomeShellState: guarda os dados que MUDAM enquanto a app está aberta
// e desenha o ecrã (build). O Flutter guarda este objeto à parte,
// por isso os valores (ex.: _indice) não se perdem quando o widget
// é recriado.
//
// O "___" no início do nome torna a class  e PRIVADA: só este ficheiro
// (main.dart) a pode usar. Serve para esconder detalhes internos:
// o resto da app só precisa de conhecer o HomeShell, não o seu estado.
class _HomeShellState extends State<HomeShell></homeshell> {
  // Separador escolhido: 0 = Início, 1 = Inventário, ...
  // Também tem "_" porque é privado deste ficheiro.
  int _indice = 0;

  // Desenha o ecrã. Corre no início e sempre que se chama setState().
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Separador $_indice')),
    );
  }
}
