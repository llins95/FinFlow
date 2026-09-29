# Auditoria de armazenamento do FinFlow

## Arquitetura atual

O FinFlow usa uma única base de código Flutter para Android e Windows. A
lógica financeira, os modelos, o repositório local e a sincronização são
compartilhados. As diferenças nativas ficam restritas a notificações da
Carteira do Google e instalação de atualizações no Android, além do empacotador
de atualizações no Windows.

## Dados persistidos

| Camada | Conteúdo | Identificação |
| --- | --- | --- |
| Hive `financial_months` | Cópia local de cada mês e configurações Pix sincronizadas | `userId/aaaa-mm` quando há login |
| Hive `financial_month_sync_queue` | Meses alterados enquanto estão pendentes de envio | `userId/aaaa-mm` |
| Hive `app_preferences` | Tema e marcador da última exclusão recebida por usuário | chaves próprias, sem dados financeiros |
| Hive `purchases` | Formato legado, esvaziado após a migração para o mês financeiro | ID da compra antiga |
| Supabase `financial_months` | Uma linha por usuário, ano e mês; lançamentos em `entries` JSONB | chave primária `(user_id, year, month)` |
| SharedPreferences do Android | Sugestões ainda não revisadas de notificações da Carteira do Google | ID derivado da notificação |
| Cache privado | Downloads temporários de atualização | arquivo validado por SHA-256 |

Receitas, despesas, cartões e compras são `FinancialEntry`. Compras ficam no
JSON do mês em que foram realizadas e se relacionam ao cartão por
`relatedCardId`. Parcelas não são duplicadas no banco: são calculadas a partir
do valor, quantidade de parcelas, fechamento e vencimento.

Chaves e QR Code Pix usam uma entrada de configuração na linha reservada
`2100-12`. Essa linha passa pela mesma RLS, fila offline e sincronização
Realtime. Os meses financeiros navegáveis terminam em `2099-12`, evitando
colisão com a configuração. A imagem PNG é validada como 1000 × 1000 px e
armazenada em Base64 dentro dos metadados da entrada.

## Sincronização e modo offline

Toda alteração é salva primeiro no Hive e colocada na fila. O envio usa a RPC
`upsert_financial_month`; falhas deixam o item pendente e uma nova tentativa é
feita automaticamente. O Realtime atualiza a cópia local nos dois sistemas.

O controle de conflito continua sendo “última versão do mês”, usando
`client_updated_at`. As alterações agora sempre geram um horário estritamente
maior que o horário já armazenado, inclusive quando outro dispositivo estava
com o relógio adiantado. Isso evita que uma edição válida seja recusada por
parecer mais antiga.

O conflito é resolvido na granularidade do mês inteiro. Duas edições offline e
simultâneas no mesmo mês ainda podem resultar na substituição da versão mais
antiga quando ambas forem sincronizadas. Não foi introduzida uma mudança
arquitetural para granularidade por lançamento porque ela exigiria uma
migração ampla e não era necessária para as tarefas atuais.

## Isolamento e segurança

- As chaves locais e da fila agora incluem o ID do usuário. Dados de uma sessão
  não são apresentados nem enviados por outra conta.
- Chaves antigas sem escopo são migradas uma única vez para o usuário
  autenticado, preservando compatibilidade.
- A tabela Supabase usa RLS para `select`, `insert`, `update` e `delete` com
  `auth.uid() = user_id`.
- O papel `anon` não tem acesso à tabela nem às RPCs; o aplicativo usa somente
  a chave pública e a sessão autenticada.
- Número completo, validade e CVV de cartão não são armazenados. O cadastro
  contém somente nome, banco, bandeira, limite, cor e dias de fechamento e
  vencimento.
- O texto bruto das notificações detectadas permanece somente no Android e é
  apagado junto com os dados do FinFlow.

## Exclusão total

A RPC `reset_finflow_data` apaga as linhas do usuário e grava o marcador de
reinicialização na mesma transação. O marcador faz outros dispositivos
descartarem meses e filas locais antigos, evitando que dados excluídos sejam
reenviados. Clientes conectados aplicam o reset por Realtime; clientes offline
aplicam na próxima inicialização.

Há uma rotina de compatibilidade para servidores que ainda não receberam a
nova RPC. Ela usa as políticas RLS existentes, confirma a criação do marcador
antes de limpar o dispositivo e nunca apaga dados locais quando a operação
remota falha.

O tema e os arquivos necessários ao funcionamento são preservados. O estado
financeiro inicial não contém mais valores ou nomes pessoais predefinidos;
usuários novos ou reinicializados começam com um mês vazio e funcional.

## Alterações de banco

Não houve alteração de tabela nem de formato obrigatório dos registros
existentes. Foi adicionada somente a função transacional
`reset_finflow_data(jsonb, timestamptz)`. Campos novos em `entries` são
opcionais, portanto meses antigos continuam legíveis.
