# Frigu — Frigorífico Inteligente

App móvel em Flutter para um mini frigorífico inteligente que acompanha a temperatura e o inventário, ajudando a reduzir o desperdício alimentar.

Projeto Interdisciplinar 2 (PI2) do CTeSP em Design e Tecnologias para Aplicações Móveis — ESMAD, Politécnico do Porto, 2026/2027. Alinhado com o **ODS 12: Produção e consumo sustentáveis**.

> 🚧 Em desenvolvimento. Entrega final: janeiro de 2027.

## Funcionalidades

| Ecrã | Descrição | Estado |
|---|---|---|
| Início | Estado do frigorífico e temperatura atual | Em curso |
| Inventário | Alimentos dentro do frigorífico | Planeado |
| Receitas | Sugestões com os alimentos disponíveis | Planeado |
| Impacto | Desperdício evitado | Planeado |
| Compras | Lista de compras | Planeado |
| Admin | Definições do frigorífico | Planeado |

## Tecnologias

- [Flutter](https://flutter.dev) e Dart
- Material 3 com tema próprio (paleta e tipografia do Figma, fonte Montserrat)
- [fl_chart](https://pub.dev/packages/fl_chart) para gráficos
- Planeado: Supabase (dados) e ESP32-S3 com câmara (hardware do frigorífico)

## Como correr

Requisitos: [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado (`flutter doctor` sem erros).

```bash
git clone https://github.com/vitorwlm/app.git
cd app
flutter pub get
flutter run
```

## Estrutura

```
lib/
├── main.dart        # arranque da app e barra de navegação
├── screens/         # um ficheiro por ecrã
├── theme/           # cores, tipografia e tema
├── widgets/         # componentes reutilizáveis (cartões, botões)
└── services/        # ligação a dados (em breve)
assets/fonts/        # Montserrat
```

## Equipa

- Vítor — hardware, API, app e relatório
- Nuno — UX, apoio ao hardware, app e relatório
