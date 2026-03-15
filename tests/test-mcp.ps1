param(
    [string]$McpUrl = "http://localhost:8080/mcp",
    [string]$ApiHealthUrl = "http://localhost:8000/api/health",
    [string]$RequesterName = "mauro",
    [string]$QuestionText = "oggi abbiamo mangiato io, daniela e alessandra, chi lava i piatti?"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:Failures = 0

function Write-Pass([string]$msg) {
    Write-Host "[PASS] $msg" -ForegroundColor Green
}

function Write-Fail([string]$msg) {
    Write-Host "[FAIL] $msg" -ForegroundColor Red
    $script:Failures++
}

function Write-Info([string]$msg) {
    Write-Host "[INFO] $msg" -ForegroundColor Cyan
}

function Parse-McpEnvelope([string]$rawContent) {
    $match = [regex]::Match($rawContent, "(?ms)^data:\s*(\{.*\})\s*$")
    if (-not $match.Success) {
        throw "Unexpected MCP response format. Raw content: $rawContent"
    }

    return ($match.Groups[1].Value | ConvertFrom-Json)
}

function Initialize-McpSession([string]$url) {
    $initBody = @{
        jsonrpc = "2.0"
        id = 1
        method = "initialize"
        params = @{
            protocolVersion = "2025-03-26"
            capabilities = @{}
            clientInfo = @{
                name = "mcp-test-script"
                version = "1.0"
            }
        }
    } | ConvertTo-Json -Depth 6

    $initResp = Invoke-WebRequest -UseBasicParsing -Uri $url -Method POST -Headers @{
        Accept = "application/json, text/event-stream"
        "Content-Type" = "application/json"
    } -Body $initBody

    $sessionId = $initResp.Headers["mcp-session-id"]
    if (-not $sessionId) {
        throw "MCP initialize did not return mcp-session-id header"
    }

    $headers = @{
        Accept = "application/json, text/event-stream"
        "Content-Type" = "application/json"
        "mcp-session-id" = $sessionId
    }

    $initializedBody = @{
        jsonrpc = "2.0"
        method = "notifications/initialized"
        params = @{}
    } | ConvertTo-Json -Depth 4

    Invoke-WebRequest -UseBasicParsing -Uri $url -Method POST -Headers $headers -Body $initializedBody | Out-Null

    return $headers
}

function Invoke-McpRequest([string]$url, [hashtable]$headers, [string]$method, [hashtable]$params, [int]$id = 100) {
    $body = @{
        jsonrpc = "2.0"
        id = $id
        method = $method
        params = $params
    } | ConvertTo-Json -Depth 8

    $resp = Invoke-WebRequest -UseBasicParsing -Uri $url -Method POST -Headers $headers -Body $body
    return Parse-McpEnvelope -rawContent $resp.Content
}

try {
    Write-Info "Checking API health at $ApiHealthUrl"
    $health = Invoke-WebRequest -UseBasicParsing -Uri $ApiHealthUrl -Method GET
    if ($health.StatusCode -eq 200) {
        Write-Pass "API Gateway health is OK"
    } else {
        Write-Fail "API Gateway health returned status $($health.StatusCode)"
    }
} catch {
    Write-Fail "Cannot reach API Gateway health endpoint: $($_.Exception.Message)"
}

$headers = $null
try {
    Write-Info "Initializing MCP session at $McpUrl"
    $headers = Initialize-McpSession -url $McpUrl
    Write-Pass "MCP session initialized"
} catch {
    Write-Fail "Unable to initialize MCP session: $($_.Exception.Message)"
}

if (-not $headers) {
    Write-Host "\nMCP tests aborted because session initialization failed." -ForegroundColor Yellow
    exit 1
}

try {
    Write-Info "Listing MCP tools"
    $toolsResp = Invoke-McpRequest -url $McpUrl -headers $headers -method "tools/list" -params @{} -id 2
    $toolNames = @($toolsResp.result.tools | ForEach-Object { $_.name })

    if ($toolNames -contains "choose_dishwasher") {
        Write-Pass "Tool choose_dishwasher found"
    } else {
        Write-Fail "Tool choose_dishwasher missing"
    }

    if ($toolNames -contains "choose_dishwasher_from_text") {
        Write-Pass "Tool choose_dishwasher_from_text found"
    } else {
        Write-Fail "Tool choose_dishwasher_from_text missing"
    }
} catch {
    Write-Fail "tools/list failed: $($_.Exception.Message)"
}

try {
    Write-Info "Testing choose_dishwasher_from_text with requester_name"
    $callResp = Invoke-McpRequest -url $McpUrl -headers $headers -method "tools/call" -params @{
        name = "choose_dishwasher_from_text"
        arguments = @{
            question_text = $QuestionText
            requester_name = $RequesterName
            meal_kind = "dinner"
            explain = $true
        }
    } -id 3

    if ($callResp.result.isError) {
        Write-Fail "choose_dishwasher_from_text returned error"
    } else {
        $contentText = $callResp.result.content[0].text
        $payload = $contentText | ConvertFrom-Json

        if ($payload.parsed_participants.Count -ge 1) {
            Write-Pass "Parsed participants extracted: $($payload.parsed_participants -join ', ')"
        } else {
            Write-Fail "No participants parsed"
        }

        if ($payload.decision.dishwasher) {
            Write-Pass "Dishwasher selected: $($payload.decision.dishwasher)"
        } else {
            Write-Fail "Dishwasher missing in response"
        }
    }
} catch {
    Write-Fail "choose_dishwasher_from_text test failed: $($_.Exception.Message)"
}

try {
    Write-Info "Testing choose_dishwasher (structured args)"
    $callResp = Invoke-McpRequest -url $McpUrl -headers $headers -method "tools/call" -params @{
        name = "choose_dishwasher"
        arguments = @{
            participants = @("mauro", "daniela", "alessandra")
            meal_kind = "dinner"
            explain = $true
        }
    } -id 4

    if ($callResp.result.isError) {
        Write-Fail "choose_dishwasher returned error"
    } else {
        $contentText = $callResp.result.content[0].text
        $payload = $contentText | ConvertFrom-Json
        if ($payload.dishwasher) {
            Write-Pass "Structured flow dishwasher selected: $($payload.dishwasher)"
        } else {
            Write-Fail "Structured flow missing dishwasher"
        }
    }
} catch {
    Write-Fail "choose_dishwasher test failed: $($_.Exception.Message)"
}

try {
    Write-Info "Negative test: 'io' without requester_name must fail"
    $callResp = Invoke-McpRequest -url $McpUrl -headers $headers -method "tools/call" -params @{
        name = "choose_dishwasher_from_text"
        arguments = @{
            question_text = "oggi abbiamo mangiato io e daniela"
            meal_kind = "dinner"
            explain = $false
        }
    } -id 5

    if ($callResp.result.isError) {
        Write-Pass "Correctly failed when requester_name is missing"
    } else {
        Write-Fail "Expected error when requester_name is missing, but call succeeded"
    }
} catch {
    Write-Fail "Negative test (missing requester_name) failed unexpectedly: $($_.Exception.Message)"
}

try {
    Write-Info "Negative test: no known names must fail"
    $callResp = Invoke-McpRequest -url $McpUrl -headers $headers -method "tools/call" -params @{
        name = "choose_dishwasher_from_text"
        arguments = @{
            question_text = "oggi ha cucinato il vicino"
            meal_kind = "dinner"
            explain = $false
        }
    } -id 6

    if ($callResp.result.isError) {
        Write-Pass "Correctly failed when no participants can be extracted"
    } else {
        Write-Fail "Expected failure when no participants can be extracted, but call succeeded"
    }
} catch {
    Write-Fail "Negative test (no names) failed unexpectedly: $($_.Exception.Message)"
}

Write-Host ""
if ($script:Failures -eq 0) {
    Write-Host "All MCP tests passed." -ForegroundColor Green
    exit 0
}

Write-Host "$script:Failures test(s) failed." -ForegroundColor Red
exit 1
