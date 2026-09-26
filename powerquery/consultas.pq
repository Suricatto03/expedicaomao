// ============================================================================
// Consultas Power Query para a planilha FATURAMENTO BAIA 13.xlsx
// Excel > Dados > Obter Dados > Consulta em Branco > Editor Avançado > colar.
// Troque a URL do site em pSite (uma vez só).
// ============================================================================


// ---------------------------------------------------------------- pSite (parâmetro)
"https://suaempresa.sharepoint.com/sites/ExpedicaoMAO" meta [IsParameterQuery = true, Type = "Text", IsParameterQueryRequired = true]


// ---------------------------------------------------------------- ContagemDiaria
// Base de tudo: 1 linha por doca por dia (o app mantém esta lista atualizada).
let
    Fonte    = SharePoint.Tables(pSite, [ApiVersion = 15]),
    Lista    = Fonte{[Title = "ContagemDiaria"]}[Items],
    Colunas  = Table.SelectColumns(Lista,
                 {"DataRef", "MesRef", "Ordem", "Doca", "Bairros", "Itinerario", "Codigo",
                  "Matricula", "Faturadas", "Insucessos", "Resgates", "MP", "Total"}),
    Tipos    = Table.TransformColumnTypes(Colunas, {
                 {"DataRef", type date}, {"Ordem", Int64.Type},
                 {"Faturadas", Int64.Type}, {"Insucessos", Int64.Type},
                 {"Resgates", Int64.Type}, {"MP", Int64.Type}, {"Total", Int64.Type}})
in
    Tipos


// ---------------------------------------------------------------- FaturamentoDoDia
// Reproduz a aba "FATURAMENTO 3T" para a data digitada na célula nomeada pData
// (crie uma célula com a data e dê a ela o nome pData em Fórmulas > Definir Nome).
// Traz TODAS as docas, inclusive as que ficaram zeradas.
let
    Data       = Date.From(Excel.CurrentWorkbook(){[Name = "pData"]}[Content]{0}[Column1]),
    Itins      = Table.SelectColumns(
                   SharePoint.Tables(pSite, [ApiVersion = 15]){[Title = "Itinerarios"]}[Items],
                   {"Ordem", "Title", "Bairros", "Itinerario", "CodigoItinerario", "Matricula"}),
    DoDia      = Table.SelectRows(ContagemDiaria, each [DataRef] = Data),
    Junta      = Table.NestedJoin(Itins, {"Ordem"}, DoDia, {"Ordem"}, "C", JoinKind.LeftOuter),
    Expande    = Table.ExpandTableColumn(Junta, "C", {"Faturadas", "Insucessos", "Resgates", "MP", "Total"}),
    Zeros      = Table.ReplaceValue(Expande, null, 0, Replacer.ReplaceValue,
                   {"Faturadas", "Insucessos", "Resgates", "MP", "Total"}),
    Ordena     = Table.Sort(Zeros, {{"Ordem", Order.Ascending}}),
    Renomeia   = Table.RenameColumns(Ordena, {
                   {"Title", "DOCA"}, {"Bairros", "BAIRROS"}, {"Itinerario", "ITINERÁRIO"},
                   {"CodigoItinerario", "CÓDIGO"}, {"Matricula", "MATRÍCULA"},
                   {"Faturadas", "FATURADAS"}, {"Insucessos", "INSUCESSOS"},
                   {"Resgates", "RESGATES"}, {"MP", "MP"}, {"Total", "TOTAL"}}),
    Final      = Table.RemoveColumns(Renomeia, {"Ordem"})
in
    Final


// ---------------------------------------------------------------- HistoricoMensal
// Substitui a aba "09.2026": totais por dia no mês digitado na célula pMes (ex.: 2026-09).
let
    Mes     = Text.From(Excel.CurrentWorkbook(){[Name = "pMes"]}[Content]{0}[Column1]),
    DoMes   = Table.SelectRows(ContagemDiaria, each [MesRef] = Mes),
    PorDia  = Table.Group(DoMes, {"DataRef"}, {
                {"Faturadas",  each List.Sum([Faturadas]),  Int64.Type},
                {"Insucessos", each List.Sum([Insucessos]), Int64.Type},
                {"Resgates",   each List.Sum([Resgates]),   Int64.Type},
                {"MP",         each List.Sum([MP]),         Int64.Type},
                {"Total",      each List.Sum([Total]),      Int64.Type}}),
    Resumo  = Table.SelectColumns(
                SharePoint.Tables(pSite, [ApiVersion = 15]){[Title = "ResumoDiario"]}[Items],
                {"Title", "Disponiveis", "PresasJ1BNFE", "FrotasDisponiveis", "FrotasManutencao"}),
    ResumoT = Table.TransformColumnTypes(Resumo, {{"Title", type date}}),
    Junta   = Table.NestedJoin(PorDia, {"DataRef"}, ResumoT, {"Title"}, "R", JoinKind.LeftOuter),
    Expande = Table.ExpandTableColumn(Junta, "R",
                {"Disponiveis", "PresasJ1BNFE", "FrotasDisponiveis", "FrotasManutencao"}),
    Pct     = Table.AddColumn(Expande, "% Faturamento",
                each if [Disponiveis] = null or [Disponiveis] = 0 then null else [Faturadas] / [Disponiveis],
                Percentage.Type),
    Ordena  = Table.Sort(Pct, {{"DataRef", Order.Ascending}})
in
    Ordena


// ---------------------------------------------------------------- NotasPorItinerario
// Alimenta o gráfico "NOTAS POR ITINERÁRIO" do INDICADOR (data em pData).
let
    Data   = Date.From(Excel.CurrentWorkbook(){[Name = "pData"]}[Content]{0}[Column1]),
    DoDia  = Table.SelectRows(ContagemDiaria, each [DataRef] = Data),
    Grupo  = Table.Group(DoDia, {"Itinerario"}, {{"Notas", each List.Sum([Total]), Int64.Type}}),
    Ordena = Table.Sort(Grupo, {{"Itinerario", Order.Ascending}})
in
    Ordena
