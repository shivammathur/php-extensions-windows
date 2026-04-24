param(
  [Parameter(Mandatory = $true)]
  [string]$php,
  [Parameter(Mandatory = $true)]
  [string]$path
)

if($php -match '8\.6') {
    $pcov = Get-Content "$path\pcov.c" -Raw
    $pcov = $pcov -replace ([regex]::Escape('INI_BOOL("pcov.enabled")')), 'zend_ini_bool_literal("pcov.enabled")'
    $pcov = $pcov -replace ([regex]::Escape('INI_INT("pcov.initial.memory")')), 'zend_ini_long_literal("pcov.initial.memory")'
    $pcov = $pcov -replace ([regex]::Escape('INI_INT("pcov.initial.files")')), 'zend_ini_long_literal("pcov.initial.files")'
    $pcov = $pcov -replace ([regex]::Escape('INI_STR("pcov.directory")')), '((char *) zend_ini_string_literal("pcov.directory"))'
    $pcov = $pcov -replace ([regex]::Escape('INI_STR("pcov.exclude")')), '((char *) zend_ini_string_literal("pcov.exclude"))'
    $pcov | Set-Content "$path\pcov.c" -Encoding UTF8
}
