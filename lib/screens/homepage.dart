import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/expiring_card.dart';
import '../widgets/recipe_card.dart';
import '../widgets/status_card.dart';
import 'admin.dart';
import 'detalhes.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // DateTime.now().hour = hora atual (0 a 23)
    final int hora = DateTime.now().hour;
    String saudacao;
    if (hora < 12) {
      saudacao = 'Bom dia,';
    } else if (hora < 20) {
      saudacao = 'Boa tarde,';
    } else {
      saudacao = 'Boa noite,';
    }

    // SafeArea evita que o conteudo fique por baixo da barra do telemovel
    return SafeArea(
      child: SingleChildScrollView(
        // espaco em baixo para o botao Adicionar nao tapar a receita
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      saudacao,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                    Text('Vítor', style: textTheme.headlineSmall),
                  ],
                ),
                const Spacer(),
                IconButton(
                  // IconButton.styleFrom funciona como o do ElevatedButton
                  style: IconButton.styleFrom(backgroundColor: AppColors.white),
                  icon: const Icon(Icons.notifications_none),
                  onPressed: () => debugPrint('alertas'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(backgroundColor: AppColors.white),
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Admin()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            StatusCard(
              status: 'Temperatura ideal',
              temperature: 4.2,
              humidity: 62,
              detalhe: 'Alvo 2–5 °C · Porta fechada · há 2 min',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Detalhes()),
                );
              },
            ),
            const SizedBox(height: 20),
            ExpiringCard(
              // debugPrint escreve na consola, so para testar
              onVerTudo: () => debugPrint('inventario'),
              items: [
                ExpiringItem(
                  nome: 'Iogurte natural',
                  quantidade: '2 unidades',
                  dias: 0,
                  onUsei: () => debugPrint('usei iogurte'),
                ),
                ExpiringItem(
                  nome: 'Ovos',
                  quantidade: '6 unidades',
                  dias: 1,
                  onUsei: () => debugPrint('usei ovos'),
                ),
                ExpiringItem(
                  nome: 'Espinafres',
                  quantidade: '200 g',
                  dias: 4,
                  onUsei: () => debugPrint('usei espinafres'),
                  ultimo: true,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Sugestão para hoje', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            RecipeCard(
              etiqueta: 'RECEITA DO DIA',
              titulo: 'Omelete de espinafres',
              minutos: 15,
              aExpirar: 2,
              onTap: () => debugPrint('receita'),
            ),
          ],
        ),
      ),
    );
  }
}
