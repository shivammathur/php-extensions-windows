param(
  [Parameter(Mandatory = $true)]
  [string]$php,
  [Parameter(Mandatory = $true)]
  [string]$path
)

if($php -match '^8\.7$') {
    $config = Get-Content "$path\config.w32" -Raw
    $config = $config -replace 'XDEBUG_PHP_VERSION >= 80700', 'XDEBUG_PHP_VERSION >= 80800'
    $config = $config -replace '< 8\.7\.0', '< 8.8.0'
    $config | Set-Content "$path\config.w32" -Encoding UTF8 -NoNewline
}
