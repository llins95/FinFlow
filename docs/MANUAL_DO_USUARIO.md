# Manual do Usuário — FinFlow

Este manual descreve as funções disponíveis no FinFlow para Android e Windows. Os nomes dos botões seguem os textos atuais do aplicativo.

## 1. Entrar e criar conta

### E-mail
Informe o e-mail da sua conta FinFlow. A mesma conta pode ser usada no Android e no Windows para sincronizar os dados.

### Senha
Informe sua senha. O ícone de olho mostra ou oculta a senha digitada.

### Entrar
Acessa uma conta já existente.

### Criar minha conta
Troca a tela para o modo de cadastro.

### Criar conta
Cria uma nova conta com e-mail e senha. Dependendo da configuração da conta, pode ser necessário confirmar o e-mail antes do primeiro acesso.

### Já tenho uma conta
Volta do cadastro para a tela de login.

---

## 2. Navegação principal

No Android, as áreas principais aparecem na barra inferior. No Windows, em telas maiores, aparecem em uma barra lateral.

- **Início:** visão geral do mês, faturas, despesas, receitas, saldo anterior e vencimentos.
- **Cartões:** cadastro e edição dos cartões e das faturas.
- **Compra:** registra uma compra, simula parcelas e permite importar sugestões detectadas da Carteira do Google no Android.
- **Histórico:** consulta meses anteriores e compras já registradas.
- **Chaves Pix:** guarda chaves Pix e um QR Code Pix personalizado.
- **Mais:** conta, sincronização, Carteira do Google, Despesas Água/Luz, segurança, aparência, atualização e exclusão dos dados.

---

## 3. Aba Início

### Setas do mês
- **Seta para a esquerda:** abre o mês anterior.
- **Seta para a direita:** abre o próximo mês disponível ou cria a continuação necessária.

### Lupa — Buscar compra ou mês
Abre a busca para localizar compras e períodos cadastrados.

### Total a pagar
Mostra quanto ainda está pendente em despesas e faturas no mês aberto.

### Total disponível
Soma receitas e saldo trazido do mês anterior.

### Sobra / Falta
Compara o total disponível com todos os compromissos financeiros do mês.

Ao tocar nesse cartão, o FinFlow mostra:
- total disponível;
- total de compromissos do mês;
- valor final de sobra ou falta;
- quanto já foi marcado como pago;
- quanto ainda está pendente;
- cada despesa e fatura que compõe o cálculo, com o respectivo valor e situação.

**Importante:** o valor de **Falta** considera todos os compromissos cadastrados no mês, inclusive os que já foram marcados como pagos. A indicação **Total a pagar** mostra somente o que ainda está pendente.

### Progresso do mês
Mostra a proporção entre contas pagas e compromissos totais.

- **Pago:** total marcado como pago.
- **Pendente:** total ainda não marcado como pago.

### Próximos vencimentos
Mostra até três despesas ou faturas pendentes que possuem dia de vencimento cadastrado.

### Faturas dos cartões
Lista as faturas do mês.

- Tocar no valor/fatura abre a edição.
- O valor pode incluir compras e parcelas adicionadas automaticamente pelo FinFlow.
- O controle de pago/pendente altera o progresso e o total pendente do mês.

### Despesas
Lista gastos que não são faturas de cartão.

- **Adicionar:** cria uma nova despesa.
- **Tocar no lançamento:** edita nome, valor, repetição e vencimento quando disponíveis.
- **Pago/Pendente:** altera a situação da despesa.
- **Excluir:** remove o lançamento daquele mês.

### Adicionar/Atualizar saldo do mês anterior
Traz para o mês aberto o saldo calculado no mês anterior sem criar duplicação.

Se o saldo já tiver sido trazido, o botão muda para **Atualizar saldo do mês anterior**.

### Receitas e saldo anterior
Mostra dinheiro disponível para o mês.

- **Adicionar:** cria uma receita.
- **Tocar no lançamento:** edita o lançamento.
- **Excluir:** remove o lançamento.

### Repetir nos próximos meses
Ao criar ou editar uma receita/despesa recorrente, permite levar o lançamento para os meses seguintes. Quando uma data/mês final é definida, a repetição termina nesse período.

---

## 4. Aba Cartões

### + / Adicionar cartão
Cria um cartão novo.

Campos principais:
- **Nome do cartão:** nome usado no FinFlow.
- **Banco:** instituição do cartão.
- **Bandeira:** por exemplo, Visa ou Mastercard.
- **Limite:** limite cadastrado para referência.
- **Dia de fechamento:** dia em que a fatura fecha.
- **Dia de vencimento:** dia de pagamento da fatura.
- **Cor do cartão:** cor visual usada no mini cartão.
- **Cartão ativo:** define se o cartão continua sendo levado aos meses seguintes.

### Mini cartão
Mostra visualmente a cor e a bandeira cadastradas.

### Editar fatura
Botão com ícone de alteração de valor. Permite informar/ajustar o total da fatura do mês.

Quando existem compras registradas pelo FinFlow, o total exibido já inclui essas parcelas. O aplicativo não permite reduzir manualmente a fatura para um valor menor do que as compras automáticas já vinculadas.

### Editar cartão
Botão com lápis. Altera dados permanentes do cartão, como nome, banco, bandeira, limite, fechamento, vencimento, cor e situação ativo/inativo.

### Limite
Mostra o limite cadastrado do cartão.

### Fecha
Mostra o dia de fechamento da fatura.

### Vence
Mostra o dia de vencimento.

### Melhor dia
É calculado a partir do fechamento e indica um dia favorável para que uma nova compra caia na fatura seguinte.

### Cartão inativo
Permanece visível no mês atual, mas não é copiado para o próximo mês.

---

## 5. Aba Compra

Use esta área para registrar compras feitas no cartão.

### Ícone de alerta — Importar da Carteira do Google
Disponível no Android. Abre a tela **Compras detectadas**.

O FinFlow não acessa diretamente a conta ou o histórico completo da Carteira do Google. Ele detecta notificações de compra emitidas pelo aplicativo Carteira do Google no próprio Android. A compra sempre precisa ser revisada antes de ser salva.

### Cartão
Escolhe em qual cartão a compra foi feita.

### Descrição da compra
Nome do produto, serviço ou estabelecimento.

### Valor da compra
Valor total da compra.

### Parcelas
Quantidade de parcelas, de 1 até 99.

### Seleção rápida
Atalho para escolher rapidamente de 1x até 24x.

### Data da compra
Data real em que a compra ocorreu. Ela é usada junto com o fechamento do cartão para decidir em qual fatura a primeira parcela entra.

### Simular parcelas
Calcula antes de salvar:
- primeira fatura;
- distribuição das parcelas;
- valor de cada parcela;
- meses em que serão cobradas;
- prazo aproximado até o pagamento.

### Salvar compra
Confirma a compra e inclui suas parcelas nas faturas corretas. A compra também entra na sincronização da conta.

### Nova compra
Depois de salvar, limpa os campos para registrar outra compra.

---

## 6. Compras detectadas — Carteira do Google

Esta função existe somente no Android.

### Como funciona
1. Abra **Compra** e toque no ícone de importação, ou vá em **Mais > Compras pela Carteira do Google**.
2. Na primeira utilização, toque em **Abrir configurações**.
3. Autorize o FinFlow no acesso às notificações do Android.
4. Faça uma nova compra usando a Carteira do Google.
5. Abra novamente **Compras detectadas** ou atualize a tela.
6. Toque na sugestão desejada.
7. Confira descrição, valor, cartão e parcelas.
8. Salve a compra.

### Atualizar
Ícone de seta circular. Relê as sugestões guardadas no aparelho.

### Confirmar compra
Ícone de confirmação ao lado da lixeira. Seleciona a sugestão e retorna à tela de adicionar compra com os dados preenchidos para revisão.

### Descartar
Ícone de lixeira ao lado da sugestão. Remove aquela sugestão somente do aparelho, sem criar compra no FinFlow.

### Privacidade
O texto bruto da notificação fica somente no aparelho. Somente a compra revisada e salva entra no FinFlow e na sincronização.

### Limitações importantes
- Não importa automaticamente todo o histórico antigo da Carteira do Google.
- A detecção depende de o Android permitir ao FinFlow ler as notificações.
- A notificação precisa conter um valor em reais para ser reconhecida como candidata a compra.
- No Windows, as compras devem ser registradas manualmente. Depois de salvas no Android, elas podem sincronizar para o Windows.

---

## 7. Aba Histórico

Possui duas subabas: **Meses** e **Compras**.

### Histórico > Meses
Mostra um resumo de cada mês criado.

- **A pagar:** valor ainda pendente.
- **Disponível:** receitas e saldo anterior.
- **Sobra/Falta:** resultado financeiro do mês.
- **Tocar em Sobra/Falta:** abre a explicação completa do cálculo e lista despesas/faturas que formam o valor.
- **Abrir mês:** abre aquele período na aba Início.
- **Mês atual:** indica que o período já está aberto e, por isso, não precisa ser aberto novamente.

### Histórico > Compras
Mostra todas as compras cadastradas.

Cada item informa:
- descrição;
- cartão;
- data da compra;
- valor total;
- quantidade de parcelas.

Ações:
- **Tocar na compra:** abre a edição.
- **Lixeira:** solicita confirmação e exclui a compra.
- **Toque longo:** também abre a confirmação de exclusão.

Ao editar uma compra, o FinFlow recalcula a distribuição nas faturas quando necessário.

---

## 8. Aba Chaves Pix

### Adicionar chave
Botão flutuante que cadastra uma nova chave Pix.

Cada chave pode ter tipo, valor e um título para facilitar a identificação.

### Tocar na chave
Abre a edição.

### Copiar chave
Ícone de cópia. Coloca o valor da chave na área de transferência.

### Editar chave
Ícone de lápis. Altera os dados cadastrados.

### Excluir chave
Ícone de lixeira. Pede confirmação e remove a chave.

### QR Code Pix personalizado
Permite guardar uma imagem PNG do seu QR Code Pix.

- **Cadastrar:** adiciona o QR Code quando ainda não existe.
- **Alterar:** substitui a imagem existente.

A imagem pode ser sincronizada com a conta FinFlow.

---

## 9. Aba Mais

### Conta pessoal
Mostra a conta/e-mail atualmente conectado.

### Sincronização
Mostra a situação da sincronização. Quando disponível, o botão de sincronizar força uma nova tentativa de enviar/receber alterações.

### Compras pela Carteira do Google
No Android, abre a mesma tela de compras detectadas disponível na aba Compra. No Windows, informa que a função não está disponível.

### Despesas Água/Luz
Abre um controle doméstico independente para acompanhar as contas de água e energia elétrica por mês e por ano.

Na parte superior, use as setas para escolher o **ano**. Depois escolha uma das duas abas:
- **Água:** mostra os valores de água dos 12 meses daquele ano.
- **Luz:** mostra os valores de energia dos 12 meses daquele ano.

Para cadastrar ou alterar um valor, toque no mês desejado, informe o valor da conta e toque em **Salvar**. Um valor anual é exibido no final da lista somente para facilitar a consulta dentro dessa própria função.

**Importante:** Água/Luz é um controle isolado. Esses valores não entram em **Total a pagar**, **Total disponível**, **Sobra/Falta**, despesas, faturas, cartões, compras nem histórico financeiro. Eles só aparecem dentro de **Despesas Água/Luz**.

### Segurança
Lembra que cada conta acessa seus próprios dados e que o FinFlow não guarda número completo do cartão nem CVV.

### QR Code Pix personalizado
Atalho para cadastrar, alterar ou visualizar o QR Code Pix salvo.

### Aparência
Escolhe o tema visual:
- **Sistema:** acompanha o tema do aparelho/Windows.
- **Claro:** força tema claro.
- **Escuro:** força tema escuro.

### Atualização do aplicativo
Verifica a versão instalada e se existe uma versão mais nova.

Dependendo da plataforma e do estado da atualização, podem aparecer botões como:
- **Verificar atualização**;
- **Baixar e instalar**;
- **Autorizar instalação** no Android;
- **Baixar, atualizar e reiniciar** no Windows.

No Android, o sistema pode pedir permissão para instalar atualização proveniente do próprio FinFlow.

### Sair da conta
Encerra a sessão atual. Os dados já salvos localmente permanecem no aparelho e podem voltar a sincronizar no próximo login.

### Apagar meus dados do FinFlow
Apaga receitas, despesas, cartões, faturas, compras, histórico, chaves Pix, QR Code e o controle local de Água/Luz.

Por segurança:
1. o FinFlow mostra uma primeira confirmação;
2. depois exige que seja digitado **APAGAR**;
3. somente então executa a exclusão.

Quando a sincronização está ativa, a exclusão também é aplicada à conta e aos outros dispositivos para os dados sincronizados. Essa ação não pode ser desfeita.

---

## 10. Pago, pendente, sobra e falta

- **Pago:** compromisso marcado como quitado.
- **Pendente:** compromisso que ainda não foi marcado como pago.
- **Total a pagar:** soma somente compromissos pendentes.
- **Total disponível:** receitas + saldo anterior.
- **Compromissos do mês:** soma todas as despesas e faturas do período, pagas ou pendentes.
- **Sobra:** disponível maior ou igual aos compromissos.
- **Falta:** compromissos maiores do que o disponível.

Fórmula usada no resumo:

`Total disponível - Compromissos do mês = Sobra/Falta`

---

## 11. Android x Windows

As informações financeiras e funções de cadastro devem permanecer equivalentes nas duas plataformas.

Diferenças principais:
- **Carteira do Google:** detecção de compras somente no Android.
- **Atualização:** o processo de instalação é diferente em cada sistema.
- **Navegação:** Android usa normalmente a barra inferior; Windows usa barra lateral quando existe espaço suficiente.

O controle **Despesas Água/Luz** existe nas duas plataformas e permanece separado dos cálculos financeiros.

As compras confirmadas no Android podem ser sincronizadas e visualizadas no Windows usando a mesma conta.
