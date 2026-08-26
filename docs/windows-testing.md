# Teste do FinFlow no Windows 11

## O que é necessário

- Windows 11 x64 atualizado;
- acesso à internet para login, sincronização e atualização;
- uma pasta gravável pelo usuário, como
  `C:\Users\SEU_USUARIO\Apps\FinFlow`;
- a mesma conta usada no Android, caso queira validar a sincronização.

Visual Studio, Flutter e o Visual C++ Redistributable não são necessários para
testar o pacote publicado. O ZIP já contém o executável, os arquivos do Flutter
e os runtimes `msvcp140.dll`, `vcruntime140.dll` e `vcruntime140_1.dll`.

## Primeiro teste

1. Baixe `FinFlow-Windows-x64.zip` na release mais recente.
2. Confira o arquivo `FinFlow-Windows-x64.zip.sha256`, se desejar validar
   manualmente o download.
3. Extraia todo o ZIP para uma pasta do seu usuário. Não execute o programa
   diretamente de dentro do ZIP.
4. Abra `FinFlow.exe`.
5. Se o SmartScreen aparecer, confira que o arquivo veio da release oficial do
   projeto antes de escolher **Mais informações > Executar assim mesmo**.
6. Entre com a mesma conta do Android e confira os meses, cartões, compras,
   pagamentos e histórico.
7. Abra **Mais > Atualização do aplicativo > Verificar atualizações** para
   validar o canal de atualização do Windows.

## Atualização automática segura

O FinFlow somente fecha depois que o atualizador externo confirma que o ZIP foi
extraído e contém `FinFlow.exe`. Se a preparação falhar ou demorar mais que o
limite esperado, o aplicativo permanece aberto e mostra o caminho do registro.

Depois que o FinFlow fecha, o atualizador:

1. cria uma cópia de segurança da versão instalada;
2. substitui os arquivos usando novas tentativas para contornar bloqueios
   temporários do Windows ou do antivírus;
3. inicia a nova versão e confirma que ela permaneceu aberta;
4. restaura e reabre a versão anterior se qualquer etapa falhar.

Os registros ficam na pasta `%TEMP%\updates`, com nomes como
`FinFlow-Updater-[versão].log` e `FinFlow-Updater-[versão].result`.

## Funcionalidades por plataforma

| Funcionalidade | Android | Windows 11 |
| --- | --- | --- |
| Dashboard, meses, receitas e despesas | Sim | Sim |
| Cartões, faturas e compras parceladas | Sim | Sim |
| Pagamentos, exclusões, busca e histórico | Sim | Sim |
| Recorrência com mês final e saldo do mês anterior | Sim | Sim |
| Edição de limite e identificação mensal da fatura | Sim | Sim |
| Chaves Pix e QR Code PNG 1000 × 1000 | Sim | Sim |
| Exclusão total com reset sincronizado | Sim | Sim |
| Temas Fluent claro, escuro e sistema | Sim | Sim |
| Login, Hive, fila offline e Supabase Realtime | Sim | Sim |
| Verificação, download e aplicação de atualização | APK + SHA-256 | ZIP + SHA-256 e reinício automático |
| Captura de compras da Carteira Google | Sim | Não se aplica |
| Lembretes locais de fechamento e vencimento | Sim | Ainda não |

As duas limitações finais não afetam os dados sincronizados. Uma compra
confirmada no Android aparece normalmente no Windows, e todos os lançamentos
financeiros podem ser cadastrados manualmente nas duas plataformas.

## Checklist recomendado

- abrir, redimensionar e maximizar a janela;
- conferir o novo ícone no Explorer, barra de tarefas e janela;
- validar login e sincronização nos dois sentidos;
- criar, editar, pagar e excluir lançamentos;
- cadastrar uma compra parcelada e conferir as faturas futuras;
- editar o limite de um cartão e conferir o mesmo valor no Android;
- cadastrar uma recorrência com término e confirmar que ela não passa do mês;
- transferir o saldo anterior duas vezes e confirmar que existe uma só entrada;
- cadastrar uma chave Pix e substituir um QR Code PNG 1000 × 1000;
- conferir as duas etapas da exclusão total sem concluir a última etapa;
- testar os três temas;
- fechar e abrir novamente para conferir a persistência local;
- testar o botão de atualização quando uma versão posterior estiver publicada.
