# FinFlow

Aplicativo pessoal de controle financeiro feito em Flutter para Android e
Windows.

## Primeira versão financeira

- mês inicial: agosto de 2026;
- atualização rápida das faturas de cartão;
- despesas fixas e avulsas;
- receitas e saldo do mês anterior;
- resumo com total a pagar, total disponível e sobra/falta;
- valores armazenados em centavos inteiros;
- persistência local com Hive;
- criação do próximo mês com lançamentos recorrentes;
- compras parceladas e calendário preservados do protótipo original.

## Próximas etapas

- login pessoal;
- sincronização Android–Windows com Supabase;
- fila offline para sincronizar ao reconectar;
- histórico financeiro mensal e configurações editáveis.

## Executar

```bash
flutter pub get
flutter run -d windows
```

Para validar:

```bash
flutter analyze
flutter test
```
