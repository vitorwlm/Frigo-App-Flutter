// * LEGENDA DOS COMENTÁRIOS (cores da extensão Better Comments no VS Code)
// *   * verde   = fluxo: o que o ecrã/ficheiro faz, de onde vem e para onde vai
// *   ? azul    = porquê: porque usei esta solução
// *   ! vermelho = cuidado: o que parte se mudar (mounted, dispose, RLS…)
// *   TODO laranja = o que falta fazer
//
// * FLUXO DA APP (começa aqui)
// * main() liga o Supabase → MyApp → _PortaoLogin decide o 1.º ecrã:
// *   sem sessão → Login (screens/login.dart)
// *   com sessão → _Arranque carrega os dados (data/frigorifico.dart)
// *              → BoasVindas (só depois de criar conta) ou HomeShell
// * HomeShell = barra de baixo com os 5 separadores:
// *   Início · Inventário · Receitas · Impacto · Compras

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/secrets.dart';
import 'data/frigorifico.dart';
import 'services/nuvem.dart';
import 'theme/app_theme.dart';
import 'screens/adicionar_sheet.dart';
import 'screens/homepage.dart';
import 'screens/impacto.dart';
import 'screens/inventario.dart';
import 'screens/lista_compras.dart';
import 'screens/login.dart';
import 'screens/onboarding.dart';
import 'screens/receitas.dart';

// ? async porque o Supabase tem de estar pronto antes do 1.º ecrã:
// ? o _PortaoLogin já vai perguntar se há sessão
Future<void> main() async {
  // ? Uso ensureInitialized porque o Supabase é um plugin que guarda a sessão
  // ? no telemóvel, e os plugins só funcionam depois disto
  WidgetsFlutterBinding.ensureInitialized();
  // ? ícones da barra de estado escuros, porque o fundo da app é claro
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Frigu',
      // ? tema num só sítio (theme/app_theme.dart) para todos os ecrãs
      // ? ficarem iguais ao Figma sem repetir cores e letras
      theme: appTheme,
      // ? Para comparar os widgets com o Figma: importa 'screens/galeria.dart'
      // ? e troca a linha de baixo por home: const Galeria(),
      home: const _PortaoLogin(),
    );
  }
}

// * 1.º passo do fluxo: sem sessão → Login; com sessão → _Arranque.
// * Usei StreamBuilder (e não um if no arranque) porque assim a app muda
// * sozinha de ecrã quando a sessão muda: entrar, sair ou a sessão expirar.
class _PortaoLogin extends StatelessWidget {
  const _PortaoLogin();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, _) {
        final sessao = supabase.auth.currentSession;
        if (sessao == null) return const Login();
        // ? key com o id do utilizador: se entrar outra conta, o Flutter cria
        // ? um _Arranque novo e os dados voltam a ser carregados para ela
        return _Arranque(key: ValueKey(sessao.user.id));
      },
    );
  }
}

// * 2.º passo: carrega os dados do Supabase uma vez (rodinha enquanto espera)
// * e depois abre as Boas-vindas ou a HomeShell
class _Arranque extends StatefulWidget {
  const _Arranque({super.key});

  @override
  State<_Arranque> createState() => _ArranqueState();
}

class _ArranqueState extends State<_Arranque> {
  // ? Future guardado no estado porque, se o criasse dentro do build, o
  // ? FutureBuilder voltava a pedir os dados ao Supabase a cada redesenho
  //TODO verificar a sintaxe do late final
  late final Future<void> _carregar = frigorifico.carregar();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _carregar,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // ? ListenableBuilder porque o frigorifico avisa quando verBoasVindas
        // ? muda: depois de criar conta mostra as Boas-vindas, no fim passa à app
        return ListenableBuilder(
          listenable: frigorifico,
          builder: (context, _) => frigorifico.verBoasVindas
              ? const BoasVindas()
              : const HomeShell(),
        );
      },
    );
  }
}

// * 3.º passo: a "casca" da app, com a barra de baixo e os 5 separadores.
// * StatefulWidget porque tem de lembrar qual separador está aberto (_indice).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

// ? _ no nome = privado a este ficheiro (ninguém de fora precisa do estado)
//TODO ver entao pq por _ vs por sem se for indiferente
class _HomeShellState extends State<HomeShell> {
  int _indice = 0;

  final List<Widget> _ecras = const [
    Homepage(),
    Inventario(),
    Receitas(),
    Impacto(),
    ListaCompras(),
  ];

  // ? O botão flutuante muda com o separador: no Início e no Inventário
  // ? adiciona um alimento, nas Compras adiciona à lista; nos outros não há
  //TODO verificar o porque de Widget?
  Widget? _botaoAdicionar(BuildContext context) {
    if (_indice == 0 || _indice == 1) {
      return FloatingActionButton.extended(
        onPressed: () => mostrarAdicionar(context),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      );
    }
    if (_indice == 4) {
      return FloatingActionButton.extended(
        onPressed: () => mostrarNovaCompra(context),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _botaoAdicionar(context),
      // ? IndexedStack em vez de trocar o body: só mostra o ecrã do _indice,
      // ? mas os outros continuam vivos e não perdem o scroll nem os filtros
      body: IndexedStack(index: _indice, children: _ecras),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) {
          setState(() {
            _indice = i;
          });
        },
        // ! tem de estar pela mesma ordem que _ecras (o índice liga os dois)
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.kitchen), label: 'Inventário'),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu),
            label: 'Receitas',
          ),
          NavigationDestination(icon: Icon(Icons.eco), label: 'Impacto'),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart),
            label: 'Compras',
          ),
        ],
      ),
    );
  }
}
