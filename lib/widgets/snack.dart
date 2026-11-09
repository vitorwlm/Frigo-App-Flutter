import 'package:flutter/material.dart';

// * Mensagens em baixo (SnackBar), num só sítio para todas serem iguais.

// ? Mensagem com o botão "Anular" (ecrã 11 do Figma): em vez de perguntar
// ? "tens a certeza?" antes de cada Usei, deixa desfazer depois (mais rápido)
void mostrarAnular(BuildContext context, String mensagem, VoidCallback desfazer) {
  final messenger = ScaffoldMessenger.of(context);
  // ? tira a anterior para não ficarem em fila (a pessoa quer ver a última)
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(mensagem),
      action: SnackBarAction(label: 'Anular', onPressed: desfazer),
    ),
  );
}

// ? Mensagem simples, sem botão
void mostrarMensagem(BuildContext context, String mensagem) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(mensagem)));
}
