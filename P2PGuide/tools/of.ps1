# Oracle Fusion UIA helpers (uip rpa uia). Usage: $env:OFTAB="b1234"; . ./P2PGuide/tools/of.ps1
# Find the tab ref first with Get-Tabs. See OracleFusion_Automation_Playbook.md section 10.
$P = "C:/UiPath/OracleFusion_AgenticTesting"
$W = "$env:TEMP/ofuia/app"
$T = "$env:TEMP/ofuia/text"
New-Item -ItemType Directory -Force $T | Out-Null
$B = if ($env:OFTAB) { $env:OFTAB } else { "b1255" }

# Capture the tab tree and grep it
function Get-Snap([string]$pattern = '.', [int]$max = 40) {
  uip rpa uia snapshot capture $B --folder-path "$W" --project-dir "$P" | Select-String 'Title:|URL:|Application snapshot'
  Select-String -Path "$W/tree.yml" -Pattern $pattern | Select-Object -First $max | ForEach-Object { $_.Line.Trim() }
}
# Grep the last tree without re-capturing
function Find-Ref([string]$pattern, [int]$max = 40) {
  Select-String -Path "$W/tree.yml" -Pattern $pattern | Select-Object -First $max | ForEach-Object { $_.Line.Trim() }
}
function Invoke-Click([string]$ref) { uip rpa uia interact click $ref --input-method DebuggerApi --project-dir "$P" }
function Set-Text([string]$ref, [string]$text) { uip rpa uia interact type $ref $text --input-method DebuggerApi --clear-before-mode SingleLine --project-dir "$P" }
# Read visible page text (read-only) and save it
function Read-Page([string]$name, [int]$chars = 6000) {
  $out = uip rpa uia interact browser eval $B "() => document.title + '\n' + location.href.split('?')[0] + '\n' + document.body.innerText" --project-dir "$P"
  $txt = ($out -join "`n") -replace "(\r?\n\s*){3,}", "`n`n"
  if ($name) { [IO.File]::WriteAllText("$T/$name.txt", $txt) }
  $txt.Substring(0, [Math]::Min($chars, $txt.Length))
}
# Re-capture top level; return @{Win=wN; Tabs=@(title=bN)} for Oracle Chrome tabs
function Get-Tabs {
  $top = "$env:TEMP/ofuia/top"
  uip rpa uia snapshot capture --folder-path "$top" --project-dir "$P" | Out-Null
  $win = $null; $res = [ordered]@{}
  foreach ($ln in Get-Content "$top/window-tree.yml") {
    if ($ln -match 'Window "(.*)" \[ref=(w\d+)\]') { $wt = $matches[1]; $wr = $matches[2] }
    if ($ln -match 'BrowserTab "(.*)" \[ref=(b\d+)\]' -and $wt -match 'Google Chrome' ) {
      $tt = $matches[1]; $br = $matches[2]
      if ($tt -match 'Oracle|BPM|Worklist|Security|Setup|Approv') { $res[$br] = "$tt  (window $wr)"; $win = $wr }
    }
  }
  $res; "WIN=$win"
}
function Wait-Page([string]$expect, [int]$timeoutSec = 150) {
  $sw = [Diagnostics.Stopwatch]::StartNew()
  while ($sw.Elapsed.TotalSeconds -lt $timeoutSec) {
    $out = (uip rpa uia interact browser eval $B "() => document.body.innerText" --project-dir "$P") -join "`n"
    if ($out -match $expect) { return "ready after $([int]$sw.Elapsed.TotalSeconds)s" }
    Start-Sleep -Seconds 5
  }
  "TIMEOUT waiting for: $expect"
}
function Open-Task([string]$q, [string]$n) {
  Get-Snap 'InputBox "Search"|Search task types' 2 | Out-Null
  $sb=(Find-Ref 'InputBox "Search"' 1) -replace '.*ref=(e\d+).*','$1'; $go=(Find-Ref 'Search task types' 1) -replace '.*ref=(e\d+).*','$1'
  Set-Text $sb $q | Out-Null; Invoke-Click $go | Out-Null; Start-Sleep 8
  Get-Snap 'zzz' 1 | Out-Null
  $r=(Find-Ref "Text `"$n`"" 1) -replace '.*ref=(e\d+).*','$1'; Invoke-Click $r | Out-Null; Start-Sleep 12
  Get-Snap 'zzz' 1 | Out-Null
  $a=(Find-Ref 'Link "Assignees"' 1) -replace '.*ref=(e\d+).*','$1'; Invoke-Click $a | Out-Null; Start-Sleep 15
}
function Invoke-HwClick([string]$ref) { uip rpa uia interact click $ref --input-method HardwareEvents --project-dir "$P" }
$EV = "C:/UiPath/OracleFusion_AgenticTesting/P2PGuide"
# Save page text as evidence and queue a screenshot name
function Save-Evidence([string]$name) {
  $out = uip rpa uia interact browser eval $B "() => document.title + '\n' + location.href.split('?')[0] + '\n' + document.body.innerText" --project-dir "$P"
  $txt = ($out -join "`n") -replace "(\r?\n\s*){3,}", "`n`n"
  [IO.File]::WriteAllText("$EV/text/$name.txt", $txt)
  Add-Content -Path "$EV/pending-shots.txt" -Value "$name|$B"
  "saved $name ($($txt.Length) chars)"
}
function Get-PageText { (uip rpa uia interact browser eval $B "() => document.body.innerText" --project-dir "$P") -join "`n" }
function Get-R([string]$pat) { Get-Snap 'zzz' 1 | Out-Null; (Find-Ref $pat 1) -replace '.*ref=(e\d+).*','$1' }
function Pick-LovRow([string]$field, [string]$text, [string]$rowText) {
  $f = Get-R "DropDown `"$field`" \[ref=e\d+\](?! \[invisible\])"
  uip rpa uia interact type $f $text --input-method DebuggerApi --project-dir "$P" | Out-Null; Start-Sleep 6
  Get-Snap 'zzz' 1 | Out-Null; $l = Get-Content "$W/tree.yml"
  $i = ($l | Select-String ([regex]::Escape($rowText)) | Select-Object -First 1).LineNumber
  if (-not $i) { return "no option $rowText for $field" }
  $row = ($l[([Math]::Max(0,$i-14))..($i)] | Select-String 'TableRow[^\n]*ref=(e\d+)' | Select-Object -Last 1).Line -replace '.*ref=(e\d+).*','$1'
  Invoke-Click $row | Out-Null; Start-Sleep 4; "picked $field"
}
# Create a noncatalog request and stop at the cart; returns cart text
function New-NoncatalogToCart([string]$desc, [string]$price) {
  uip rpa uia interact browser eval $B "() => { location.href = '/fscmUI/redwood/procurement/requisitions'; return 'ok' }" --project-dir "$P" | Out-Null
  Wait-Page 'Create Noncatalog Request' 150 | Out-Null
  Invoke-Click (Get-R 'Button \[ref=e\d+\]: Create Noncatalog Request') | Out-Null; Wait-Page 'Item Description' 150 | Out-Null; Start-Sleep 3
  Set-Text (Get-R 'InputBox "Item Description"') $desc | Out-Null
  Pick-LovRow 'Category' 'Desktop' 'Desktops'
  Pick-LovRow 'UOM' 'Each' 'Text "Ea"'
  Set-Text (Get-R 'InputBox "Price" \[ref=e\d+\](?! \[invisible\])') $price | Out-Null; Start-Sleep 2
  Pick-LovRow 'Supplier' 'Dell' 'Other name: Dell Inc'
  Get-Snap 'DropDown "(Category|UOM|Supplier|Supplier Site)" \[ref=e\d+\] \[items|InputBox "(Price|Item Description)"' 8
}
function Open-Cart {
  Invoke-Click (Get-R 'TabPage "Cart"') | Out-Null; Wait-Page 'Approval Amount' 150 | Out-Null; Start-Sleep 4
  $pg = Get-PageText; $pg.Substring(0, [Math]::Min(1400, $pg.Length))
}
function Get-Approvers([string]$req, [string]$evName) {
  uip rpa uia interact browser eval $B "() => { location.href = '/fscmUI/redwood/procurement/requisitions'; return 'ok' }" --project-dir "$P" | Out-Null
  Wait-Page "Requisition $req" 150 | Out-Null
  Invoke-Click (Get-R "Text `"Requisition $req`"") | Out-Null; Wait-Page 'Approval Amount' 150 | Out-Null; Start-Sleep 4
  Invoke-Click (Get-R 'Button "More Actions"') | Out-Null; Start-Sleep 3
  Invoke-Click (Get-R 'MenuItem "View Approvers"') | Out-Null; Wait-Page 'Approvers' 120 | Out-Null; Start-Sleep 8
  if ($evName) { Save-Evidence $evName | Out-Null }
  $pg = Get-PageText; $i = $pg.IndexOf('Approvers'); $pg.Substring($i, [Math]::Min(1500, $pg.Length - $i))
}

# Withdraw a pending requisition (Edit > withdraw dialog > Save for Later). Writes: announce first.
function Withdraw-Req([string]$req) {
  uip rpa uia interact browser eval $B "() => { location.href = '/fscmUI/redwood/procurement/requisitions'; return 'ok' }" --project-dir "$P" | Out-Null
  Wait-Page "Requisition $req" 180 | Out-Null; Start-Sleep 3
  Invoke-Click (Get-R "Text `"Requisition $req`"") | Out-Null; Wait-Page 'Approval Amount' 150 | Out-Null; Start-Sleep 4
  $pg=Get-PageText; if ($pg -notmatch "${req}Pending approval") { return "$req not pending" }
  Invoke-Click (Get-R 'Button "Edit" \[ref=e\d+\](?! \[)') | Out-Null; Start-Sleep 4
  Get-Snap 'zzz' 1 | Out-Null; $l = Get-Content "$W/tree.yml"
  $i = ($l | Select-String 'withdrawWarningDialog_layer' | Select-Object -First 1).LineNumber
  $ed = ($l[$i..($i+40)] | Select-String 'Button "Edit" \[ref=(e\d+)\]' | Select-Object -First 1).Line -replace '.*ref=(e\d+).*','$1'
  Invoke-Click $ed | Out-Null; Wait-Page "Requisition $req" 150 | Out-Null; Start-Sleep 5
  Invoke-Click (Get-R 'Button "More Actions" \[ref=e\d+\](?! \[invisible\])') | Out-Null; Start-Sleep 3
  Invoke-Click (Get-R 'MenuItem "Save for Later"') | Out-Null; Start-Sleep 4
  Invoke-Click (Get-R 'Button "Save for Later" \[ref=e\d+\](?! \[invisible\])') | Out-Null; Start-Sleep 10
  (Get-PageText).Substring(0,200)
}
# Cancel an Approved or Withdrawn requisition (More Actions > Cancel). Writes: announce first.
function Cancel-Req([string]$req, [string]$reason = "Test UiPath cleanup") {
  uip rpa uia interact browser eval $B "() => { location.href = '/fscmUI/redwood/procurement/requisitions'; return 'ok' }" --project-dir "$P" | Out-Null
  Wait-Page "Requisition $req" 180 | Out-Null; Start-Sleep 3
  Invoke-Click (Get-R "Text `"Requisition $req`"") | Out-Null; Wait-Page 'Approval Amount' 150 | Out-Null; Start-Sleep 4
  $pg=Get-PageText; if ($pg -notmatch "${req}(Approved|Withdrawn)") { return "$req not Approved/Withdrawn" }
  Invoke-Click (Get-R 'Button "More Actions" \[ref=e\d+\](?! \[invisible\])') | Out-Null; Start-Sleep 3
  Invoke-Click (Get-R 'MenuItem "Cancel"') | Out-Null; Start-Sleep 5
  Get-Snap 'zzz' 1 | Out-Null; $l = Get-Content "$W/tree.yml"
  $i = ($l | Select-String 'cancel-header-dialog' | Select-Object -First 1).LineNumber
  if (-not $i) { return "$req no cancel dialog" }
  $blk = $l[$i..($i+80)]
  $rs = ($blk | Select-String 'InputBox "Cancellation Reason" \[ref=(e\d+)\]' | Select-Object -First 1).Line -replace '.*ref=(e\d+).*','$1'
  $ok = ($blk | Select-String 'Button "Cancel Requisition" \[ref=(e\d+)\]' | Select-Object -First 1).Line -replace '.*ref=(e\d+).*','$1'
  Set-Text $rs $reason | Out-Null; Start-Sleep 2; Invoke-Click $ok | Out-Null; Start-Sleep 12
  (Get-PageText).Substring(0,200)
}
