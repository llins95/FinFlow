# FinFlow

Aplicativo pessoal de controle financeiro feito em Flutter para Android e
Windows.

## Recursos

- mês inicial: agosto de 2026;
- atualização rápida de faturas, despesas e receitas;
- cadastro e edição de cartões, limites, datas e ativação mensal;
- compras à vista ou parceladas usando os cartões cadastrados;
- detecção opcional de compras da Carteira do Google no Android;
- calendário de parcelas com rateio exato em centavos;
- resumo com total a pagar, total disponível e sobra/falta;
- valores monetários armazenados em centavos inteiros;
- persistência local com Hive;
- login pessoal por e-mail e senha;
- sincronização Android–Windows com Supabase Realtime;
- fila offline com reenvio automático;
- histórico e criação do próximo mês com itens recorrentes;
- migração automática das compras antigas salvas no Hive;
- dados protegidos por RLS e isolados por usuário.

## Configurar o Supabase

O aplicativo recebe somente a URL e a chave pública do projeto em tempo de
execução. Nunca use a chave `service_role` no cliente.

```bash
flutter pub get

flutter run -d windows \
  --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=SUA-CHAVE-PUBLICA
```

No PowerShell, use uma única linha ou substitua `\` pelo caractere de
continuação `` ` ``.

Para executar no Android, troque `windows` pelo identificador exibido em:

```bash
flutter devices
```

## Banco de dados

As migrações versionadas estão em `supabase/migrations`. Elas criam a tabela
`financial_months`, as políticas RLS, a função de gravação com controle de
versão e a publicação Realtime.

As compras fazem parte do JSON do mês financeiro. Por isso, usam a mesma fila
offline e a mesma sincronização sem exigir uma segunda tabela.

## Compras detectadas no Android

Na aba **Compra**, toque no ícone de notificações e conceda ao FinFlow o
**Acesso às notificações** na tela do Android. O serviço considera somente
alertas da Carteira do Google que contenham um valor em reais.

Cada alerta vira apenas uma sugestão: descrição, valor, cartão e parcelas podem
ser revisados antes de salvar. O texto bruto da notificação fica localmente no
Android e não é enviado ao Supabase. Depois da confirmação, somente o registro
normal da compra é sincronizado. O acesso pode ser revogado a qualquer momento
nas configurações do sistema.

## Validar

```bash
flutter analyze
flutter test
flutter build apk --debug
```
