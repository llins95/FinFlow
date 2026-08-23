# FinFlow

Aplicativo pessoal de controle financeiro feito em Flutter para Android e
Windows.

## Recursos

- mês inicial: agosto de 2026;
- atualização rápida de faturas, despesas e receitas;
- cadastro e edição de cartões, limites, datas e ativação mensal;
- compras à vista ou parceladas usando os cartões cadastrados;
- parcelas somadas automaticamente à fatura do mês de vencimento;
- busca por compra ou mês com a sequência completa de parcelas;
- pagamentos mensais de despesas e faturas, sem alterar o valor cadastrado;
- exclusão de compras, receitas e saldo anterior;
- lembretes de fechamento e vencimento no Android;
- dashboard de valores pagos, pendentes e próximos vencimentos;
- Microsoft Fluent Design com temas claro, escuro e padrão do sistema;
- detecção opcional de compras da Carteira do Google no Android;
- verificação, download e instalação de atualizações no Android e Windows;
- calendário de parcelas com rateio exato em centavos;
- resumo com total a pagar, total disponível e sobra/falta;
- valores monetários armazenados em centavos inteiros;
- persistência local com Hive;
- login pessoal por e-mail e senha;
- sincronização Android–Windows com Supabase Realtime;
- fila offline com reenvio automático;
- histórico e criação do próximo mês com itens recorrentes;
- repetição de receitas e despesas com mês final opcional;
- identificação explícita do mês de cada fatura;
- preservação do valor de saldo anterior ao navegar para os meses seguintes;
- miniatura do cartão com a cor cadastrada e a marca da bandeira nas faturas;
- gerenciamento de chaves Pix e QR Code PNG personalizado;
- exclusão total protegida por duas confirmações;
- migração automática das compras antigas salvas no Hive;
- dados protegidos por RLS e isolados por usuário.

## Identidade do aplicativo

O master do ícone está em
`assets/branding/finflow-icon-master-v2.png`. O símbolo combina a letra
**F** com três barras de crescimento e usa o gradiente azul, ciano e verde da
identidade do FinFlow. No Android, o símbolo do ícone adaptativo permanece
dentro da área segura para não ser ampliado ou cortado pelo formato escolhido
no aparelho.

Para regenerar todos os tamanhos do Android e o `.ico` multirresolução do
Windows:

```bash
bash tool/generate_app_icons.sh
```

O script requer ImageMagick e mantém os assets das duas plataformas derivados
do mesmo master.

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
O valor manual da fatura continua preservado; na interface, ele é somado apenas
às parcelas que vencem no mês aberto.

O detalhamento das camadas locais, sincronização, modo offline, RLS e rotina de
exclusão está em `docs/data-storage-audit.md`.

## Compras detectadas no Android

Na aba **Compra**, toque no ícone de notificações e conceda ao FinFlow o
**Acesso às notificações** na tela do Android. O serviço considera somente
alertas da Carteira do Google que contenham um valor em reais.

Cada alerta vira apenas uma sugestão: descrição, valor, cartão e parcelas podem
ser revisados antes de salvar. O texto bruto da notificação fica localmente no
Android e não é enviado ao Supabase. Depois da confirmação, somente o registro
normal da compra é sincronizado. O acesso pode ser revogado a qualquer momento
nas configurações do sistema.

## Atualizações no Android

Ao abrir o aplicativo, o FinFlow consulta a release mais recente deste
repositório. Quando o `versionCode` publicado for maior que o instalado, o app
exibe um aviso e também disponibiliza a atualização em **Mais > Atualização do
aplicativo**.

O APK é baixado para o cache privado, conferido com SHA-256 e entregue ao
instalador oficial do Android. Na primeira vez, o Android solicita que o usuário
autorize o FinFlow como fonte de instalação. Nenhuma instalação é silenciosa.

As releases são assinadas sempre com o mesmo keystore, mantido somente nos
Repository Secrets. Os nomes e o procedimento estão em
`docs/android-signing.md`.

## Windows 11

O executável usa o nome `FinFlow.exe`, o novo ícone e uma janela inicial de
1280×800, centralizada, com tamanho mínimo de 900×640. Em telas largas, a
navegação inferior muda automaticamente para uma barra lateral.

Para compilar no Windows com Visual Studio e o workload **Desenvolvimento para
desktop com C++**:

```powershell
flutter build windows --release --dart-define=SUPABASE_URL="https://SEU-PROJETO.supabase.co" --dart-define=SUPABASE_PUBLISHABLE_KEY="SUA-CHAVE-PUBLICA"
```

O GitHub Actions também prepara `FinFlow-Windows-x64.zip` e seu SHA-256. Nas
publicações, o pacote é anexado à mesma release do APK Android e inclui os
runtimes do Visual C++ necessários para funcionar em outro computador.

Em **Mais > Atualização do aplicativo**, o Windows verifica a release mais
recente, baixa o ZIP, confere o SHA-256, fecha o FinFlow, substitui os arquivos
e abre o aplicativo novamente. A pasta onde o ZIP foi extraído precisa permitir
gravação pelo usuário.

O roteiro do primeiro teste e a comparação de funcionalidades estão em
`docs/windows-testing.md`.

## Validar

```bash
flutter analyze
flutter test
flutter build apk --debug
# Execute em um ambiente Windows:
flutter build windows --release
```
