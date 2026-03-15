# Test completo del sistema Cucinometro
# Testa tutte le funzionalità end-to-end

param(
    [string]$WebUrl = "http://localhost:8002",
    [string]$ApiUrl = "http://localhost:8000/api"
)

Write-Host "Test Completo Sistema Cucinometro" -ForegroundColor Cyan
Write-Host "Web: $WebUrl" -ForegroundColor Cyan
Write-Host "API: $ApiUrl" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Yellow

$global:tests = @()

function Test-WebPage {
    param([string]$Url, [string]$Name)
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            $global:tests += @{Name = $Name; Status = "PASS"; Details = "HTTP $($response.StatusCode)"}
            Write-Host "PASS: $Name" -ForegroundColor Green
            return $true
        } else {
            $global:tests += @{Name = $Name; Status = "FAIL"; Details = "HTTP $($response.StatusCode)"}
            Write-Host "FAIL: $Name (HTTP $($response.StatusCode))" -ForegroundColor Red
            return $false
        }
    } catch {
        $global:tests += @{Name = $Name; Status = "FAIL"; Details = $_.Exception.Message}
        Write-Host "FAIL: $Name ($($_.Exception.Message))" -ForegroundColor Red
        return $false
    }
}

function Test-ApiEndpoint {
    param([string]$Url, [string]$Method = "GET", [string]$Name)
    try {
        $response = Invoke-WebRequest -Uri $Url -Method $Method -UseBasicParsing -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            $global:tests += @{Name = $Name; Status = "PASS"; Details = "HTTP $($response.StatusCode)"}
            Write-Host "PASS: $Name" -ForegroundColor Green
            return $true
        } else {
            $global:tests += @{Name = $Name; Status = "FAIL"; Details = "HTTP $($response.StatusCode)"}
            Write-Host "FAIL: $Name (HTTP $($response.StatusCode))" -ForegroundColor Red
            return $false
        }
    } catch {
        $global:tests += @{Name = $Name; Status = "FAIL"; Details = $_.Exception.Message}
        Write-Host "FAIL: $Name ($($_.Exception.Message))" -ForegroundColor Red
        return $false
    }
}

Write-Host ""
Write-Host "Test Pagine Web:" -ForegroundColor Cyan
$null = Test-WebPage "$WebUrl/" "Homepage"
$null = Test-WebPage "$WebUrl/create-meal/" "Crea Pasto"
$null = Test-WebPage "$WebUrl/decide-dishwasher/" "Decidi Lavapiatti"
$null = Test-WebPage "$WebUrl/create-member/" "Crea Membro"
$null = Test-WebPage "$WebUrl/statistics/" "Statistiche"

Write-Host ""
Write-Host "Test API Endpoints:" -ForegroundColor Cyan
$null = Test-ApiEndpoint "$ApiUrl/health" "GET" "API Health"
$null = Test-ApiEndpoint "$ApiUrl/members" "GET" "API Lista Membri"
$null = Test-ApiEndpoint "$ApiUrl/meals" "GET" "API Lista Pasti"

# Test creazione membro via API
Write-Host ""
Write-Host "Test Creazione Membro via API:" -ForegroundColor Cyan
try {
    $testName = "TestUser_$(Get-Random)"
    $body = @{name = $testName} | ConvertTo-Json
    $response = Invoke-WebRequest -Uri "$ApiUrl/members" -Method POST -Body $body -ContentType "application/json" -UseBasicParsing

    if ($response.StatusCode -eq 201) {
        $global:tests += @{Name = "API Crea Membro"; Status = "PASS"; Details = "Membro '$testName' creato"}
        Write-Host "PASS: Creazione membro '$testName' riuscita" -ForegroundColor Green
    } else {
        $global:tests += @{Name = "API Crea Membro"; Status = "FAIL"; Details = "HTTP $($response.StatusCode)"}
        Write-Host "FAIL: Creazione membro fallita (HTTP $($response.StatusCode))" -ForegroundColor Red
    }
} catch {
    $global:tests += @{Name = "API Crea Membro"; Status = "FAIL"; Details = $_.Exception.Message}
    Write-Host "FAIL: Creazione membro fallita ($($_.Exception.Message))" -ForegroundColor Red
}

# Risultati finali
Write-Host ""
Write-Host "=" * 50 -ForegroundColor Yellow
Write-Host "RISULTATI FINALI" -ForegroundColor Cyan

$passed = ($global:tests | Where-Object { $_.Status -eq "PASS" }).Count
$total = $global:tests.Count
$successRate = [math]::Round(($passed / $total) * 100, 1)

Write-Host "Test totali: $total" -ForegroundColor White
Write-Host "Test passati: $passed" -ForegroundColor Green
Write-Host "Test falliti: $($total - $passed)" -ForegroundColor Red
Write-Host "Tasso di successo: $successRate%" -ForegroundColor $(if ($successRate -ge 90) { "Green" } elseif ($successRate -ge 70) { "Yellow" } else { "Red" })

if ($passed -eq $total) {
    Write-Host ""
    Write-Host "TUTTI I TEST SUPERATI! Sistema funzionante!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Alcuni test falliti. Dettagli:" -ForegroundColor Yellow
    foreach ($test in ($global:tests | Where-Object { $_.Status -eq "FAIL" })) {
        Write-Host "   FAIL: $($test.Name): $($test.Details)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=" * 50 -ForegroundColor Yellow