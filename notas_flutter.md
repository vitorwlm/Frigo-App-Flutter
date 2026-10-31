# Notas: o que a app usa e não foi dado nas aulas (até à aula 9)

| Onde | O quê | Em resumo |
|---|---|---|
| main.dart | `_nome` | Privado ao **ficheiro** (não à classe, ao contrário de Java). |
| main.dart | `theme:` no MaterialApp | Tema global; todos os widgets o usam. |
| main.dart | `NavigationBar` | Barra de baixo. Mesmo padrão do contador (aula 5): `selectedIndex` + `onDestinationSelected` com `setState`. |
| main.dart | `IndexedStack` | Cria todos os ecrãs e mostra só o do `index`; os outros não perdem o estado. Com `_ecras[_indice]` eram recriados a cada troca. |
| app_colors.dart | `static const` | Pertence à classe, não a um objeto: `AppColors.primary500` sem `AppColors()`. Constante desde a compilação. |
| app_colors.dart | `Color(0xFF0E7C86)` | Cor em hexadecimal. `0x` = hexadecimal, `FF` = opacidade total, `0E7C86` = a cor do Figma. |
| app_theme.dart | variável fora de classe | Pode ser importada por qualquer ficheiro. |
| app_theme.dart | `ThemeData`, `useMaterial3` | Aspeto por defeito de todos os widgets; Material 3 = versão atual do Material. |
| app_theme.dart | `ColorScheme.fromSeed` | Gera os tons a partir de uma cor base (vem no template do `flutter create`). |
| app_theme.dart | `AppBarTheme`, `CardThemeData` | Estilo de todas as AppBar / Card, sem repetir em cada ecrã. |
| app_theme.dart | `RoundedRectangleBorder`, `BorderSide` | Forma com cantos arredondados; linha da borda. |
| app_typography.dart | `TextTheme` | Estilos com nomes fixos. `bodyMedium` = texto normal; a NavigationBar usa `labelMedium`. |
| app_typography.dart | `FontWeight.w400`–`w700` | Espessura: w400 normal, w700 = bold. |
| app_typography.dart | `height`, `letterSpacing` | Altura da linha (× tamanho da letra); espaço entre letras. |
| app_card.dart | `VoidCallback?` | Tipo de função sem argumentos nem retorno (como no `onPressed`). `?` = pode ser null. |
| app_card.dart | `clipBehavior: Clip.antiAlias` | Corta o que sai dos cantos arredondados. |
| app_card.dart | `InkWell` | Torna qualquer widget clicável, com o efeito de toque. |
| primary_button.dart | `ElevatedButton.styleFrom` | Muda cor de fundo, cor do texto, padding, forma e letra do botão. |
| status_card.dart | `this.isAlert = false` | Parâmetro opcional com valor por defeito. |
| status_card.dart | `Theme.of(context)` | Vai buscar o tema do MaterialApp. |
| pubspec.yaml | `fonts:` | Fontes em `assets/fonts`; `family` = nome no código, `weight` = espessura de cada ficheiro. |
