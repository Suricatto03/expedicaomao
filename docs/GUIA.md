# Guia de implantação — Controle de Expedição MAO

Tempo estimado: 1h30 a 2h na primeira vez.

---

## 1. Criar o banco de dados (listas do SharePoint): só cliques

Use o site que a equipe já tem: **https://bemol.sharepoint.com/sites/faturamentoexpmanaus**
(é onde está a FATURAMENTO BAIA 13.xlsx). Você precisa ter permissão de *Editar* ou ser *Proprietário* desse
site. Se aparecer "sem permissão" em algum passo, peça isso ao dono do site.

### 1.1 Subir o arquivo modelo

1. Baixe `modelos/Expedicao_BancoDeDados.xlsx`. Ele já tem 4 abas prontas, e a aba **Itinerarios** vem com as
   41 docas da sua planilha.
2. Confira a coluna **CodigoItinerario**: os códigos foram digitados a partir de uma foto.
3. Arraste o arquivo para **Documentos** do site faturamentoexpmanaus.

### 1.2 Criar as 4 listas (repita 4 vezes, uma por aba)

1. No site, clique em **+ Novo > Lista**.
2. Escolha **Do Excel** e selecione `Expedicao_BancoDeDados.xlsx`.
3. Em **Selecione uma tabela**, escolha a primeira: `Itinerarios`.
4. A tela mostra cada coluna com um tipo. Ajuste assim:

   | Lista | Colunas que devem ser **Número** | Coluna **Data** | Coluna **Sim/Não** | Todas as outras |
   |---|---|---|---|---|
   | Itinerários | Ordem, Ativo (1 = ativo, 0 = inativo) | — | — | Linha única de texto |
   | Bipagens | Ordem | — | — | Linha única de texto |
   | ContagemDiaria | Ordem, Faturadas, Insucessos, Resgates, MP, Total | Data | — | Linha única de texto |
   | ResumoDiario | Disponiveis, PresasJ1BNFE, FrotasDisponiveis, FrotasManutencao | Data | — | Linha única de texto |

   **Atenção:** `Doca`, `Matricula`, `DataRef` e `Itinerario` têm que ficar como **texto**. Se ficarem como
   número, o "04" vira "4".
   **Título:** o assistente exige que UMA coluna seja "Título". Deixe como Título: `Ordem` (Itinerários),
   `Categoria` (Bipagens, e depois crie a coluna Categoria), `Chave` (ContagemDiaria) e `DataRef` (ResumoDiario).
5. **Avançar**. Em nome, digite exatamente o nome da tabela (`Itinerarios`, `Bipagens`, `ContagemDiaria`,
   `ResumoDiario`). **Criar**.

Pronto: esse é o banco de dados. Dá para abrir cada lista e ver os dados como numa planilha.

### 1.3 Ligar os índices (5 minutos, evita travar quando passar de 5.000 NFs)

Em cada lista: ⚙️ (canto superior direito) **> Configurações da lista > Colunas indexadas > Criar novo índice**.

| Lista | Criar índice em |
|---|---|
| Bipagens | ChaveAcesso, DataRef, Ordem, NumeroNF |
| ContagemDiaria | Chave, DataRef |
| ResumoDiario | DataRef |

> Alternativa para o TI: o script `sharepoint/criar-listas.ps1` faz o item 1 inteiro automaticamente.

## 2. Criar o app no Power Apps

1. Em [make.powerapps.com](https://make.powerapps.com), vá em **Criar > Aplicativo de tela em branco**, com
   formato **Telefone** (640 × 1136).
2. **Dados > Adicionar dados >** digite **SharePoint** **>** escolha o site `faturamentoexpmanaus` e marque
   as 4 listas.
3. **Configurações > Geral > Limite de linhas de dados**: `2000`.
4. **App** (topo da árvore de controles):
   - propriedade **Formulas**: cole o bloco `Formulas` de `powerapps/App.pa.yaml`, sem o `=` inicial se o
     editor reclamar;
   - propriedade **OnStart**: cole o bloco `OnStart`;
   - em `Administradores`, troque pelo(s) seu(s) e-mail(s), em minúsculas. Só esses usuários veem a lixeira
     de estorno.
5. Crie 6 telas com estes nomes exatos: `scrInicio`, `scrBipagem`, `scrPainel`, `scrDetalhe`, `scrFechamento`, `scrConsulta`.
   Deixe `scrInicio` como a primeira.
6. Para cada tela, abra o arquivo `powerapps/<tela>.pa.yaml`:
   - copie os itens da seção `Children:` (tudo abaixo dela, **desde o primeiro `- `**);
   - no Studio, clique com o botão direito na tela na árvore e escolha **Colar código** (*Paste code*);
   - copie `OnVisible` (e `Fill`) de `Properties:` para a tela.

   Se aparecer erro de versão de controle ao colar (ex.: `Label@2.5.1`), troque pelo número da sua versão.
   Para descobrir, insira um controle igual, clique com o botão direito, escolha **Copiar código** e veja a
   versão. Também dá para criar o controle à mão e colar só as fórmulas: os nomes e as posições estão todos
   no YAML.
7. Rode o **OnStart** (menu `…` do App > *Executar OnStart*), dê **F5** e teste.
8. **Publicar** e **Compartilhar** com a equipe (dê a eles permissão de *Editar* no site do SharePoint).

---

## 3. Como usar no dia a dia

### Bipagem (tela "BIPAR NOTAS")

1. Toque no **Status** (Faturada / Insucesso / Resgate / Marketplace). O status vale para as próximas NFs e
   pode ser trocado no meio. Cada NF guarda o status do momento em que foi bipada.
2. Bipe as NFs. Cada leitura entra na lista na hora e o app verifica:
   - se tem 44 dígitos e se o **dígito verificador** confere (pega leitura errada);
   - se a NF já está na lista;
   - se a NF **já foi registrada hoje** em qualquer doca, e em qual.
3. Bipe o **código do itinerário** (ex.: `004#7G9!2k5@`) no mesmo campo ou toque em **LISTA** para escolher
   pela grade com todas as docas. Se o código servir para mais de uma doca (ex.: itinerário 01 = docas 04 e
   05), o app abre só essas docas para você tocar na certa. A **matrícula** do responsável também funciona.
4. **ENVIAR**. As NFs vão para `Bipagens` e a contagem da doca é **recalculada do zero** em `ContagemDiaria`.
   Por isso a contagem nunca fica desalinhada, mesmo com vários coletores ao mesmo tempo.

A bipadora precisa estar em modo *teclado* (keyboard wedge) com sufixo **ENTER**, que é o padrão da maioria.
É o ENTER que dispara a leitura.

### Consultar NF

- Digite o **número da NF** (com ou sem os zeros) e, se quiser, a **série**. Também dá para bipar a chave.
- Mostra todas as vezes que a NF foi bipada: data e hora, doca, itinerário, matrícula, status e quem bipou.

### Painel do Dia

- Mostra a mesma visão da aba **FATURAMENTO**: todas as docas com F / I / R / MP / TOTAL, mais os
  indicadores (total para expedir, disponíveis, % faturamento, total antigas).
- Atualiza sozinho a cada 60 s. Escolha outra data para ver dias anteriores (o histórico fica todo guardado).
- Toque numa doca para ver **as NFs bipadas**, quem bipou e a hora. Os administradores podem **estornar** uma
  NF bipada errada (a contagem é recalculada).

### Fechamento do Dia

- Digite o que vem do SAP: **Disponíveis para faturamento**, **Presas J1BNFE/VF04**, **Frotas disponíveis**
  e **Em manutenção**.
- O quadro-resumo calcula sozinho: total para expedir, antigas, % faturamento e capacidade prevista.

---

## 4. Planilha / indicador (Excel)

A planilha continua existindo, mas **não precisa mais digitar** a aba FATURAMENTO:

1. Abra `powerquery/consultas.pq`.
2. No Excel: **Dados > Obter Dados > De Outras Fontes > Consulta em Branco > Editor Avançado**. Crie uma
   consulta para cada bloco do arquivo (`pSite`, `ContagemDiaria`, `FaturamentoDoDia`, `HistoricoMensal`,
   `NotasPorItinerario`) com esses nomes.
3. Crie duas células nomeadas: `pData` (a data) e `pMes` (texto `2026-09`).
4. Carregue `FaturamentoDoDia` numa aba. Ela sai com as mesmas colunas da FATURAMENTO 3T.
   `HistoricoMensal` substitui a aba mensal (09.2026). As fórmulas do **INDICADOR** passam a apontar para
   essas tabelas.
5. **Dados > Atualizar Tudo** busca os números mais recentes do app.

As abas que vêm do SAP (**VBAP**, zoneamento, montagem, frotas) continuam como estão. Só a contagem manual
sai da planilha.

---

## 5. Próximos passos (opcional)

- **Power BI**: conectar nas mesmas listas e publicar o painel INDICADOR para a gerência, com atualização
  automática.
- **Power Automate**: enviar o resumo do dia por e-mail/Teams às 22h (gatilho *Recorrência*, *Obter itens*
  em ContagemDiaria filtrando `DataRef eq 'aaaa-mm-dd'`, montar a tabela HTML e enviar).
- **Coletor sem bipadora**: dá para usar a câmera do celular com o controle *Leitor de código de barras*
  jogando o valor lido na mesma fórmula do `txtChave`.
