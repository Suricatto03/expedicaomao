# Guia de implantação — Controle de Expedição MAO

Tempo estimado: 1h30 a 2h na primeira vez.

---

## 1. Criar as listas no SharePoint

### Opção A: script (recomendada)

1. Crie (ou escolha) um site do SharePoint, por exemplo `https://suaempresa.sharepoint.com/sites/ExpedicaoMAO`.
2. No PowerShell 7:
   ```powershell
   Install-Module PnP.PowerShell -Scope CurrentUser
   # só na 1ª vez; se o TI bloquear, peça a eles um ClientId de app PnP
   Register-PnPEntraIDAppForInteractiveLogin -ApplicationName "PnP Expedicao" -Tenant suaempresa.onmicrosoft.com -Interactive
   cd sharepoint
   .\criar-listas.ps1 -SiteUrl "https://suaempresa.sharepoint.com/sites/ExpedicaoMAO" -ClientId "<ClientId gerado acima>"
   ```
3. O script cria as 4 listas, os índices e já cadastra os 41 itinerários de `itinerarios.csv`.

### Opção B: manual

Crie as listas abaixo em **Novo > Lista > Lista em branco**. Os nomes das colunas precisam ser **exatamente**
estes: sem acento e sem espaço, porque o app usa esses nomes.

**Itinerarios** (cadastro, 1 linha por doca/bairro)

| Coluna | Tipo | Obs. |
|---|---|---|
| Title | (padrão) | nº da doca, ex.: `04` |
| Ordem | Número | **único, indexado.** É a chave da linha (a mesma doca aparece em mais de uma linha) |
| Bairros | Texto | |
| Itinerario | Texto | `01`, `21/31`… |
| CodigoItinerario | Texto | código de barras do itinerário (`004#7G9!2k5@`) |
| Matricula | Texto | responsável |
| Zona | Texto | opcional (Norte, Leste…) |
| Ativo | Sim/Não | padrão Sim. Desmarque para esconder do app |

Depois, abra a lista em **Editar em modo de grade** e cole o conteúdo de `sharepoint/itinerarios.csv`.

**Bipagens** (1 linha por NF bipada)

| Coluna | Tipo | Índice |
|---|---|---|
| Title | (padrão) = chave de acesso (44 dígitos) | ✔ |
| Categoria | Texto (`FATURADA`, `INSUCESSO`, `RESGATE`, `MARKETPLACE`) | ✔ |
| DataRef | Texto `aaaa-mm-dd` | ✔ |
| MesRef | Texto `aaaa-mm` | ✔ |
| Ordem | Número | ✔ |
| Doca, Itinerario, Matricula, Usuario, Lote | Texto | |

**ContagemDiaria** (a aba FATURAMENTO do dia; o app mantém atualizada)

| Coluna | Tipo |
|---|---|
| Title | (padrão) = `DataRef|Ordem`, **único + indexado** |
| DataRef, MesRef | Texto, indexados |
| Data | Data (somente data) |
| Ordem | Número |
| Doca, Bairros, Itinerario, Codigo, Matricula | Texto |
| Faturadas, Insucessos, Resgates, MP, Total | Número |

**ResumoDiario** (o quadro lateral da planilha)

| Coluna | Tipo |
|---|---|
| Title | (padrão) = `DataRef`, **único + indexado** |
| Data | Data |
| Disponiveis, PresasJ1BNFE, FrotasDisponiveis, FrotasManutencao | Número |
| Observacao | Várias linhas de texto |

> **Índices são obrigatórios.** Com cerca de 2.000 NFs por dia, a lista Bipagens passa de 5.000 itens em
> 3 dias. Sem índice em `Title`, `DataRef` e `Ordem`, o SharePoint bloqueia os filtros.
> O índice fica em **Configurações da lista > Colunas indexadas**.

---

## 2. Criar o app no Power Apps

1. Em [make.powerapps.com](https://make.powerapps.com), vá em **Criar > Aplicativo de tela em branco**, com
   formato **Telefone** (640 × 1136).
2. **Dados > Adicionar dados > SharePoint**, escolha o site e marque as 4 listas.
3. **Configurações > Geral > Limite de linhas de dados**: `2000`.
4. **App** (topo da árvore de controles):
   - propriedade **Formulas**: cole o bloco `Formulas` de `powerapps/App.pa.yaml`, sem o `=` inicial se o
     editor reclamar;
   - propriedade **OnStart**: cole o bloco `OnStart`;
   - em `Administradores`, troque pelo(s) seu(s) e-mail(s), em minúsculas. Só esses usuários veem a lixeira
     de estorno.
5. Crie 5 telas com estes nomes exatos: `scrInicio`, `scrBipagem`, `scrPainel`, `scrDetalhe`, `scrFechamento`.
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
