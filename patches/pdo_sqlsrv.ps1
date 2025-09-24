param(
  [Parameter(Mandatory = $true)]
  [string]$php,
  [Parameter(Mandatory = $true)]
  [string]$path
)

if($php -match '8.[5-6]') {
    (Get-Content "$path\php_pdo_sqlsrv_int.h" -Raw) -replace ([regex]::Escape('zval_ptr_dtor( &dbh->query_stmt_zval );')), 'OBJ_RELEASE(dbh->query_stmt_obj);dbh->query_stmt_obj = NULL;' | Set-Content "$path\php_pdo_sqlsrv_int.h" -Encoding UTF8
    (Get-Content "$path\pdo_dbh.cpp" -Raw) -replace ([regex]::Escape('pdo_error_mode prev_err_mode')), 'uint8_t prev_err_mode' | Set-Content "$path\pdo_dbh.cpp" -Encoding UTF8
}
(Get-Content $path\config.w32) -replace '/sdl', '' | Set-Content $path\config.w32
