param(
  [Parameter(Mandatory = $true)]
  [string]$php,
  [Parameter(Mandatory = $true)]
  [string]$path
)

(Get-Content $path\config.w32) -replace '/sdl', '' | Set-Content $path\config.w32
