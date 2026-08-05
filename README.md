# FinFlow

Aplicativo pessoal de controle financeiro feito em Flutter para Android e
Windows.

## Recursos

- mês inicial: agosto de 2026;
- atualização rápida de faturas, despesas e receitas;
- resumo com total a pagar, total disponível e sobra/falta;
- valores monetários armazenados em centavos inteiros;
- persistência local com Hive;
- login pessoal por e-mail e senha;
- sincronização Android–Windows com Supabase Realtime;
- fila offline com reenvio automático;
- histórico e criação do próximo mês com itens recorrentes;
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

## Validar

```bash
flutter analyze
flutter test
```
