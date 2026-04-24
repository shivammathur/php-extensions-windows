param(
  [Parameter(Mandatory = $true)]
  [string]$php,
  [Parameter(Mandatory = $true)]
  [string]$path
)

if($php -match '8\.6') {
    $init = Get-Content "$path\init.cpp" -Raw
    $init = $init -replace ([regex]::Escape('SQLSRV_G( warnings_return_as_errors ) = INI_BOOL( warnings_as_errors );')), 'SQLSRV_G( warnings_return_as_errors ) = zend_ini_parse_bool(zend_ini_str(warnings_as_errors, sizeof(warnings_as_errors) - 1, false));'
    $init = $init -replace ([regex]::Escape('SQLSRV_G( log_severity ) = INI_INT( severity );')), 'SQLSRV_G( log_severity ) = zend_ini_long(severity, sizeof(severity) - 1, false);'
    $init = $init -replace ([regex]::Escape('SQLSRV_G( log_subsystems ) = INI_INT( subsystems );')), 'SQLSRV_G( log_subsystems ) = zend_ini_long(subsystems, sizeof(subsystems) - 1, false);'
    $init = $init -replace ([regex]::Escape('SQLSRV_G( buffered_query_limit ) = INI_INT( buffered_limit );')), 'SQLSRV_G( buffered_query_limit ) = zend_ini_long(buffered_limit, sizeof(buffered_limit) - 1, false);'
    $init = $init -replace ([regex]::Escape('SQLSRV_G(set_locale_info) = INI_INT(set_locale_info);')), 'SQLSRV_G(set_locale_info) = zend_ini_long(set_locale_info, sizeof(set_locale_info) - 1, false);'
    $init | Set-Content "$path\init.cpp" -Encoding UTF8
}

(Get-Content $path\config.w32) -replace '/sdl', '' | Set-Content $path\config.w32
