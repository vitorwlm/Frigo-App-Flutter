import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/app_theme.dart';
import 'screens/adicionar_sheet.dart';
import 'screens/homepage.dart';
import 'screens/impacto.dart';
import 'screens/inventario.dart';
import 'screens/lista_compras.dart';
import 'screens/receitas.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Frigu',
      // tema global, vem de theme/app_theme.dart
      theme: appTheme,
      // para comparar os widgets com o Figma: importa 'screens/galeria.dart'
      // e troca a linha de baixo por home: const Galeria(),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

// _ = privado a este ficheiro
class _HomeShellState extends State<HomeShell> {
  int _indice = 0;

  final List<Widget> _ecras = const [
    Homepage(),
    Inventario(),
    Receitas(),
    Impacto(),
    ListaCompras(),
  ];

  // botão flutuante: alimento no Início e no Inventário, compra nas Compras
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
      // mostra so o ecra do _indice e os outros nao perdem o estado
      body: IndexedStack(index: _indice, children: _ecras),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) {
          setState(() {
            _indice = i;
          });
        },
        // tem de estar pela mesma ordem que _ecras
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
