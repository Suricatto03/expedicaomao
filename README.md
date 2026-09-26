# Controle de Expedição — Baús MAO

App em **Power Apps + SharePoint** que junta num lugar só o que hoje está espalhado:

| Antes | Agora |
|---|---|
| App "Controle de Notas Fiscais" (bipagem) | Tela **Bipar Notas**: status, NF, itinerário (bipado ou pela grade com todas as docas) e envio |
| Aba FATURAMENTO do dia, digitada à mão | Lista **ContagemDiaria**, preenchida sozinha a cada envio, e a tela **Painel do Dia** |
| Aba mensal (09.2026) | Tudo guardado por data. Painel com seletor de data e consulta `HistoricoMensal` |
| Quadro lateral (disponíveis, presas, %) | Tela **Fechamento do Dia** e a lista **ResumoDiario** |
| INDICADOR (Excel + SAP) | Continua no Excel, mas lendo as listas via Power Query (`powerquery/consultas.pq`) |

```
 Bipadora ──► Power Apps ──► SharePoint ─────────────► Excel (INDICADOR) / Power BI
             ├ Bipar Notas     ├ Itinerarios (cadastro)
             ├ Painel do Dia   ├ Bipagens (1 linha por NF)
             ├ Detalhe/Estorno ├ ContagemDiaria (doca × dia)
             └ Fechamento      └ ResumoDiario (dados do SAP/frota)
```

## Arquivos

| Caminho | O que é |
|---|---|
| `docs/GUIA.md` | **Passo a passo completo** (comece por aqui) |
| `sharepoint/criar-listas.ps1` | Cria as 4 listas, índices e carrega os itinerários |
| `sharepoint/itinerarios.csv` | 41 linhas de doca/itinerário/código/matrícula tiradas da planilha |
| `powerapps/App.pa.yaml` | Fórmulas globais (cores, categorias, admins) e OnStart |
| `powerapps/scr*.pa.yaml` | As 5 telas, prontas para *Colar código* no Power Apps Studio |
| `powerquery/consultas.pq` | Consultas para o Excel ler as listas |

## Regras de negócio

- Uma NF só pode ser registrada **uma vez por dia** (em qualquer doca). Em outro dia ela pode voltar, por
  exemplo um insucesso que retorna.
- A chave de acesso é validada: 44 dígitos e dígito verificador (módulo 11).
- `TOTAL = Faturadas + Insucessos + Resgates + MP`
- `Total antigas = Insucessos + Resgates`
- `% Faturamento = Faturadas ÷ Disponíveis`
- A contagem da doca é sempre **recontada** a partir das NFs (não é "somar +1"), então estornos e vários
  coletores simultâneos não desalinham os números.
