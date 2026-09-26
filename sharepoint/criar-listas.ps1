<#
  Cria as 4 listas do app "Controle de Expedição - MAO" no SharePoint
  e cadastra os itinerários a partir de itinerarios.csv.

  Pré-requisitos:
    Install-Module PnP.PowerShell -Scope CurrentUser
    Um App Registration (Entra ID) para o PnP — exigido desde 2024:
      Register-PnPEntraIDAppForInteractiveLogin -ApplicationName "PnP Expedicao" -Tenant suaempresa.onmicrosoft.com -Interactive
    (ou peça ao TI o ClientId de um app PnP já existente)

  Uso:
    .\criar-listas.ps1 -SiteUrl "https://suaempresa.sharepoint.com/sites/ExpedicaoMAO" -ClientId "<guid>"

  O script é idempotente: se a lista/coluna já existe, ele pula.
#>
param(
    [Parameter(Mandatory = $true)][string]$SiteUrl,
    [Parameter(Mandatory = $true)][string]$ClientId,
    [string]$CsvItinerarios = (Join-Path $PSScriptRoot "itinerarios.csv")
)

$ErrorActionPreference = "Stop"
Connect-PnPOnline -Url $SiteUrl -ClientId $ClientId -Interactive

function New-Lista($nome, $tituloExibicao) {
    if (-not (Get-PnPList -Identity $nome -ErrorAction SilentlyContinue)) {
        New-PnPList -Title $nome -Template GenericList -OnQuickLaunch | Out-Null
        Write-Host "Lista criada: $nome"
    }
    # Renomeia a coluna Title para algo legível (o nome interno continua "Title")
    Set-PnPField -List $nome -Identity "Title" -Values @{ Title = $tituloExibicao } | Out-Null
}

function Add-Coluna($lista, $nome, $tipo, [switch]$Indexar, [switch]$Unica) {
    if (-not (Get-PnPField -List $lista -Identity $nome -ErrorAction SilentlyContinue)) {
        Add-PnPField -List $lista -DisplayName $nome -InternalName $nome -Type $tipo -AddToDefaultView | Out-Null
    }
    if ($Indexar -or $Unica) {
        Set-PnPField -List $lista -Identity $nome -Values @{ Indexed = $true } | Out-Null
    }
    if ($Unica) {
        Set-PnPField -List $lista -Identity $nome -Values @{ EnforceUniqueValues = $true } | Out-Null
    }
}

# ---------------------------------------------------------------- Itinerarios
New-Lista "Itinerarios" "Doca"
Add-Coluna "Itinerarios" "Ordem"            Number  -Unica
Add-Coluna "Itinerarios" "Bairros"          Text
Add-Coluna "Itinerarios" "Itinerario"       Text
Add-Coluna "Itinerarios" "CodigoItinerario" Text    -Indexar
Add-Coluna "Itinerarios" "Matricula"        Text    -Indexar
Add-Coluna "Itinerarios" "Zona"             Text
Add-Coluna "Itinerarios" "Ativo"            Boolean
Set-PnPField -List "Itinerarios" -Identity "Ativo" -Values @{ DefaultValue = "1" } | Out-Null

# ---------------------------------------------------------------- Bipagens (1 linha por NF bipada)
New-Lista "Bipagens" "ChaveAcesso"
Set-PnPField -List "Bipagens" -Identity "Title" -Values @{ Indexed = $true } | Out-Null
Add-Coluna "Bipagens" "Categoria"  Text    -Indexar   # FATURADA | INSUCESSO | RESGATE | MARKETPLACE
Add-Coluna "Bipagens" "DataRef"    Text    -Indexar   # yyyy-mm-dd
Add-Coluna "Bipagens" "MesRef"     Text    -Indexar   # yyyy-mm
Add-Coluna "Bipagens" "Ordem"      Number  -Indexar   # linha do itinerário (lista Itinerarios)
Add-Coluna "Bipagens" "Doca"       Text
Add-Coluna "Bipagens" "Itinerario" Text
Add-Coluna "Bipagens" "Matricula"  Text
Add-Coluna "Bipagens" "Usuario"    Text
Add-Coluna "Bipagens" "Lote"       Text

# ---------------------------------------------------------------- ContagemDiaria (= aba FATURAMENTO do dia)
New-Lista "ContagemDiaria" "Chave"          # DataRef|Ordem
Set-PnPField -List "ContagemDiaria" -Identity "Title" -Values @{ Indexed = $true; EnforceUniqueValues = $true } | Out-Null
Add-Coluna "ContagemDiaria" "DataRef"    Text     -Indexar
Add-Coluna "ContagemDiaria" "MesRef"     Text     -Indexar
Add-Coluna "ContagemDiaria" "Data"       DateTime
Add-Coluna "ContagemDiaria" "Ordem"      Number
Add-Coluna "ContagemDiaria" "Doca"       Text
Add-Coluna "ContagemDiaria" "Bairros"    Text
Add-Coluna "ContagemDiaria" "Itinerario" Text
Add-Coluna "ContagemDiaria" "Codigo"     Text
Add-Coluna "ContagemDiaria" "Matricula"  Text
Add-Coluna "ContagemDiaria" "Faturadas"  Number
Add-Coluna "ContagemDiaria" "Insucessos" Number
Add-Coluna "ContagemDiaria" "Resgates"   Number
Add-Coluna "ContagemDiaria" "MP"         Number
Add-Coluna "ContagemDiaria" "Total"      Number
Set-PnPField -List "ContagemDiaria" -Identity "Data" -Values @{ DisplayFormat = 0 } | Out-Null  # somente data

# ---------------------------------------------------------------- ResumoDiario (quadro lateral da planilha)
New-Lista "ResumoDiario" "DataRef"
Set-PnPField -List "ResumoDiario" -Identity "Title" -Values @{ Indexed = $true; EnforceUniqueValues = $true } | Out-Null
Add-Coluna "ResumoDiario" "Data"              DateTime
Add-Coluna "ResumoDiario" "Disponiveis"       Number
Add-Coluna "ResumoDiario" "PresasJ1BNFE"      Number
Add-Coluna "ResumoDiario" "FrotasDisponiveis" Number
Add-Coluna "ResumoDiario" "FrotasManutencao"  Number
Add-Coluna "ResumoDiario" "Observacao"        Note
Set-PnPField -List "ResumoDiario" -Identity "Data" -Values @{ DisplayFormat = 0 } | Out-Null

# ---------------------------------------------------------------- Carga dos itinerários
if (Test-Path $CsvItinerarios) {
    $existentes = @(Get-PnPListItem -List "Itinerarios" -PageSize 500 | ForEach-Object { [int]$_["Ordem"] })
    Import-Csv $CsvItinerarios -Delimiter ";" -Encoding UTF8 | ForEach-Object {
        if ($existentes -notcontains [int]$_.Ordem) {
            Add-PnPListItem -List "Itinerarios" -Values @{
                Title            = $_.Doca
                Ordem            = [int]$_.Ordem
                Bairros          = $_.Bairros
                Itinerario       = $_.Itinerario
                CodigoItinerario = $_.CodigoItinerario
                Matricula        = $_.Matricula
                Zona             = $_.Zona
                Ativo            = $true
            } | Out-Null
            Write-Host "Itinerário cadastrado: Doca $($_.Doca) - $($_.Bairros)"
        }
    }
}

Write-Host "`nPronto. Listas: Itinerarios, Bipagens, ContagemDiaria, ResumoDiario" -ForegroundColor Green
