# Script di test automatizzato per Kong Gateway
# Esegue test sugli endpoint API attraverso Kong (porta 8000)

param(
    [string]$KongUrl = "http://localhost:8000"
)

Write-Host "Avvio test automatizzati per Kong Gateway" -ForegroundColor Cyan
Write-Host "URL Kong: $KongUrl" -ForegroundColor Cyan
Write-Host "Data: $(Get-Date)" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Yellow

$testResults = @()
$totalTests = 0
$passedTests = 0

function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Method = "GET",
        [string]$Uri,
        [string]$Body = $null,
        [int]$ExpectedStatusCode = 200,
        [scriptblock]$ContentValidator = $null
    )

    $script:totalTests++
    Write-Host ""
    Write-Host "Test: $Name" -ForegroundColor White
    Write-Host "   $Method $Uri" -ForegroundColor Gray

    try {
        $params = @{
            Uri = $Uri
            Method = $Method
            UseBasicParsing = $true
            TimeoutSec = 10
        }

        if ($Body) {
            $params.Headers = @{"Content-Type" = "application/json"}
            $params.Body = $Body
        }

        $response = Invoke-WebRequest @params

        if ($response.StatusCode -eq $ExpectedStatusCode) {
            Write-Host "   Status: $($response.StatusCode) (atteso: $ExpectedStatusCode)" -ForegroundColor Green

            if ($ContentValidator) {
                $isValid = & $ContentValidator $response.Content
                if ($isValid) {
                    Write-Host "   Contenuto valido" -ForegroundColor Green
                    $script:passedTests++
                    $testResults += @{Name = $Name; Result = "PASS"; Details = "Status OK, Content Valid"}
                } else {
                    Write-Host "   Contenuto non valido" -ForegroundColor Red
                    $testResults += @{Name = $Name; Result = "FAIL"; Details = "Content validation failed"}
                }
            } else {
                $script:passedTests++
                $testResults += @{Name = $Name; Result = "PASS"; Details = "Status OK"}
            }
        } else {
            Write-Host "   Status: $($response.StatusCode) (atteso: $ExpectedStatusCode)" -ForegroundColor Red
            $testResults += @{Name = $Name; Result = "FAIL"; Details = "Wrong status code: $($response.StatusCode)"}
        }
    }
    catch {
        Write-Host "   Errore: $($_.Exception.Message)" -ForegroundColor Red
        $testResults += @{Name = $Name; Result = "FAIL"; Details = $_.Exception.Message}
    }
}

# Validatori di contenuto
function Test-HealthResponse {
    param([string]$content)
    try {
        $json = $content | ConvertFrom-Json
        return $json.status -eq "ok"
    } catch {
        return $false
    }
}

function Test-MemberResponse {
    param([string]$content)
    try {
        $json = $content | ConvertFrom-Json
        return $json.name -and $json.id
    } catch {
        return $false
    }
}

function Test-MealResponse {
    param([string]$content)
    try {
        $json = $content | ConvertFrom-Json
        return $json.id -and $json.date -and $json.participants
    } catch {
        return $false
    }
}

function Test-MealsListResponse {
    param([string]$content)
    try {
        $json = $content | ConvertFrom-Json
        return $json -is [array] -or ($json | Get-Member -Name id)
    } catch {
        return $false
    }
}

function Test-DecideDishwasherResponse {
    param([string]$content)
    try {
        $json = $content | ConvertFrom-Json
        return $json.dishwasher -and $json.explanation
    } catch {
        return $false
    }
}

# Esegui i test
Write-Host ""
Write-Host "Test degli endpoint..." -ForegroundColor Cyan

# 1. Health Check
Test-Endpoint -Name "Health Check" -Uri "$KongUrl/api/health" -ContentValidator ${function:Test-HealthResponse}

# 2. Lista Membri
Test-Endpoint -Name "Lista Membri" -Uri "$KongUrl/api/members" -ContentValidator ${function:Test-MealsListResponse}

# 3. Creazione Membro
$testMemberName = "TestUser_$(Get-Random)"
Test-Endpoint -Name "Creazione Membro" -Method "POST" -Uri "$KongUrl/api/members" -Body "{`"name`": `"$testMemberName`"}" -ExpectedStatusCode 201 -ContentValidator ${function:Test-MemberResponse}

# 4. Lista Pasti
Test-Endpoint -Name "Lista Pasti" -Uri "$KongUrl/api/meals" -ContentValidator ${function:Test-MealsListResponse}

# 5. Creazione Pasto
$testDate = (Get-Date).ToString("yyyy-MM-dd")
Test-Endpoint -Name "Creazione Pasto" -Method "POST" -Uri "$KongUrl/api/meals" -Body "{`"date`": `"$testDate`", `"kind`": `"dinner`", `"participants`": [`"Mario`", `"Luigi`"]}" -ExpectedStatusCode 201 -ContentValidator ${function:Test-MealResponse}

# 6. Decide Dishwasher
Test-Endpoint -Name "Decide Dishwasher" -Method "POST" -Uri "$KongUrl/api/meals/decide-dishwasher" -Body "{`"date`": `"$testDate`", `"kind`": `"dinner`", `"participants`": [`"Mario`", `"Luigi`"]}" -ContentValidator ${function:Test-DecideDishwasherResponse}

# 7. Test endpoint per ID (se abbiamo creato un pasto)
try {
    $mealsResponse = Invoke-WebRequest -Uri "$KongUrl/api/meals" -Method GET -UseBasicParsing
    $meals = $mealsResponse.Content | ConvertFrom-Json
    if ($meals -and $meals.Count -gt 0) {
        $testMealId = $meals[0].id
        Test-Endpoint -Name "Pasto per ID ($testMealId)" -Uri "$KongUrl/api/meals/$testMealId" -ContentValidator ${function:Test-MealResponse}
    } else {
        Write-Host ""
        Write-Host "Nessun pasto trovato per testare endpoint per ID" -ForegroundColor Yellow
    }
} catch {
    Write-Host ""
    Write-Host "Impossibile ottenere lista pasti per test ID: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 8. Test endpoint non esistente (dovrebbe dare 404)
Test-Endpoint -Name "Endpoint Inesistente" -Uri "$KongUrl/api/nonexistent" -ExpectedStatusCode 404

# Risultati finali
Write-Host ""
Write-Host "==================================================" -ForegroundColor Yellow
Write-Host "RISULTATI FINALI" -ForegroundColor Cyan
Write-Host "Test totali: $totalTests" -ForegroundColor White
Write-Host "Test passati: $passedTests" -ForegroundColor Green
Write-Host "Test falliti: $($totalTests - $passedTests)" -ForegroundColor Red

$successRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 1) } else { 0 }
$color = if ($successRate -eq 100) { "Green" } elseif ($successRate -ge 80) { "Yellow" } else { "Red" }
Write-Host "Tasso di successo: $successRate%" -ForegroundColor $color

if ($passedTests -eq $totalTests) {
    Write-Host ""
    Write-Host "TUTTI I TEST SUPERATI! Kong funziona correttamente." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Alcuni test sono falliti. Controlla la configurazione di Kong." -ForegroundColor Red

    Write-Host ""
    Write-Host "DETTAGLI DEI TEST FALLITI:" -ForegroundColor Yellow
    foreach ($result in $testResults | Where-Object { $_.Result -eq "FAIL" }) {
        Write-Host "   FALLITO: $($result.Name): $($result.Details)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Yellow