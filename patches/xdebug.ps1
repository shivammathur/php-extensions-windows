param(
  [Parameter(Mandatory = $true)]
  [string]$php,
  [Parameter(Mandatory = $true)]
  [string]$path
)

if($php -match '8.6') {
    (Get-Content "$path\config.w32" -Raw) -replace ([regex]::Escape('80600')), '80700' | Set-Content "$path\config.w32" -Encoding UTF8
}
