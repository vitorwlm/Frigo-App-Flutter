import 'package:flutter/material.dart';

import '../data/frigorifico.dart';
import '../services/nuvem.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_button.dart';

// * ECRÃ LOGIN — o 1.º ecrã quando não há sessão (aberto pelo _PortaoLogin).
// * Fluxo: Entrar → signInWithPassword → o _PortaoLogin vê a sessão e abre a
// * app; Criar conta → signUp → Boas-vindas (onboarding.dart).
// * Entrar e Criar conta no mesmo ecrã, porque só muda um campo (Nome) e
// * assim não há dois ecrãs quase iguais. O Figma ainda não tem este ecrã:
// * segue o estilo das Boas-vindas.
class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // ? false = Entrar, true = Criar conta
  bool _registar = false;
  // ? desliga os botões enquanto espera pelo Supabase (evita 2 contas)
  bool _aEnviar = false;
  bool _verPalavraPasse = false;
  String? _erro;

  // ? GlobalKey dá acesso ao Form para validar todos os campos de uma vez,
  // ? em vez de verificar cada controller à mão
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _palavraPasse = TextEditingController();

  // ! os controllers têm de ser libertados quando o ecrã fecha, senão ficam
  // ! na memória
  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _palavraPasse.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    // ? corre os validator de cada campo; para se algum falhar, assim não
    // ? gasto um pedido ao Supabase com um email mal escrito
    if (!_form.currentState!.validate()) return;
    setState(() {
      _aEnviar = true;
      _erro = null;
    });
    try {
      final email = _email.text.trim();
      final pass = _palavraPasse.text;
      if (_registar) {
        // ? o nome vai em data porque o perfil é criado pelo trigger
        // ? criar_perfil no Supabase, que o lê daqui para a tabela perfis
        final r = await supabase.auth.signUp(
          email: email,
          password: pass,
          data: {'nome': _nome.text.trim()},
        );
        if (r.session == null) {
          // ? sem sessão = o projeto pede confirmação por email: volta ao
          // ? modo Entrar e explica o que fazer
          setState(() {
            _registar = false;
            _erro = 'Conta criada. Confirma o email e depois entra.';
          });
        } else {
          // ? a seguir ao registo mostra as Boas-vindas (o main.dart lê isto)
          frigorifico.verBoasVindas = true;
        }
      } else {
        await supabase.auth.signInWithPassword(email: email, password: pass);
      }
      // ? Não faço Navigator.push: com sessão, o _PortaoLogin do main.dart
      // ? troca de ecrã sozinho
    } catch (e) {
      setState(() => _erro = erroEmPortugues(e));
    } finally {
      // ! mounted: se já trocou de ecrã, este State já não existe
      if (mounted) setState(() => _aEnviar = false);
    }
  }

  // ? um só método para o aspeto dos 3 campos, para não repetir as bordas
  InputDecoration _campo(String rotulo, IconData icone, {Widget? sufixo}) {
    final borda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: const BorderSide(color: AppTokens.border),
    );
    return InputDecoration(
      labelText: rotulo,
      prefixIcon: Icon(icone),
      suffixIcon: sufixo,
      filled: true,
      fillColor: AppTokens.bgSurface,
      border: borda,
      enabledBorder: borda,
      focusedBorder: borda.copyWith(
        borderSide: const BorderSide(color: AppTokens.statusBrand, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.midsmall),
            children: [
              const SizedBox(height: AppSpacing.mid),
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: AppTokens.bgTonal,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: const Icon(
                  Icons.kitchen_outlined,
                  size: 72,
                  color: AppTokens.textBrand,
                ),
              ),
              const SizedBox(height: AppSpacing.mid),
              Text(
                _registar ? 'Criar conta' : 'Entrar no Frigu',
                style: textTheme.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                _registar
                    ? 'Uma conta para ver o teu frigorífico em qualquer telemóvel.'
                    : 'Vê o que tens no frigorífico e o que expira primeiro.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppTokens.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.mid),
              // ? ...[ ] espalha vários widgets dentro do if (o Nome e o espaço)
              if (_registar) ...[
                TextFormField(
                  controller: _nome,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: _campo('Nome', Icons.person_outline),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Escreve o teu nome'
                      : null,
                ),
                const SizedBox(height: AppSpacing.midsmall),
              ],
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: _campo('Email', Icons.mail_outline),
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Escreve um email válido'
                    : null,
              ),
              const SizedBox(height: AppSpacing.midsmall),
              TextFormField(
                controller: _palavraPasse,
                obscureText: !_verPalavraPasse,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _enviar(),
                decoration: _campo(
                  'Palavra-passe',
                  Icons.lock_outline,
                  sufixo: IconButton(
                    tooltip: _verPalavraPasse ? 'Esconder' : 'Mostrar',
                    icon: Icon(
                      _verPalavraPasse
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _verPalavraPasse = !_verPalavraPasse),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6)
                    ? 'Pelo menos 6 caracteres'
                    : null,
              ),
              if (_erro != null) ...[
                const SizedBox(height: AppSpacing.midsmall),
                Text(
                  _erro!,
                  style: textTheme.bodySmall?.copyWith(
                    // ? a mensagem de conta criada não é um erro: vai a teal
                    color: _erro!.startsWith('Conta criada')
                        ? AppTokens.textBrand
                        : AppTokens.textDanger,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.mid),
              AppButton(
                texto: _aEnviar
                    ? 'Um momento…'
                    : (_registar ? 'Criar conta' : 'Entrar'),
                expandir: true,
                onPressed: _aEnviar ? null : _enviar,
              ),
              const SizedBox(height: AppSpacing.small),
              AppButton(
                texto: _registar
                    ? 'Já tenho conta · Entrar'
                    : 'Não tenho conta · Criar conta',
                tipo: BotaoTipo.ghost,
                expandir: true,
                onPressed: _aEnviar
                    ? null
                    : () => setState(() {
                        _registar = !_registar;
                        _erro = null;
                      }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
