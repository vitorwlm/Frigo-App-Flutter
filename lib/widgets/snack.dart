import 'package:flutter/material.dart';

// Mensagem em baixo com o botão "Anular" (ecrã 11 do Figma)
void mostrarAnular(BuildContext context, String mensagem, VoidCallback desfazer) {
  final messenger = ScaffoldMessenger.of(context);
  // tira a anterior para não ficarem em fila
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(mensagem),
      action: SnackBarAction(label: 'Anular', onPressed: desfazer),
    ),
  );
}

void mostrarMensagem(BuildContext context, String mensagem) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(mensagem)));
}
