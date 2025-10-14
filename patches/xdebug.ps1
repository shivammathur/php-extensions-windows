param(
  [Parameter(Mandatory = $true)]
  [string]$php,
  [Parameter(Mandatory = $true)]
  [string]$path
)

if($php -match '8.6') {
    (Get-Content "$path\config.w32" -Raw) -replace ([regex]::Escape('80600')), '80700' | Set-Content "$path\config.w32" -Encoding UTF8
    $profiler = "$path\src\profiler\profiler.c"
    $content = Get-Content $profiler -Raw -Encoding UTF8
    $patched = [regex]::Replace(
    $content,
    'ZSTR_INIT_LITERAL\s*\(\s*tmp_name\s*,\s*(?:false|0)\s*\)\s*;',
    'zend_string_init(tmp_name, strlen(tmp_name), 0);'
    )

    if ($patched -ne $content) { Set-Content $profiler -Value $patched -Encoding UTF8 }
}

if($php -match '8.[5-6]') {
    $maps = "$path\src\lib\maps\maps.c"
    $content = Get-Content $maps -Raw -Encoding UTF8
    $patched = [regex]::Replace($content,
        '(^\s*#\s*include\s*<stdlib\.h>\s*\r?\n)(?!\s*#\s*include\s*"php\.h")',
        '$1#include "php.h"' + "`r`n",
        [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $patched = [regex]::Replace(
    $patched,
    '\bcase\s+GLOB_NOMATCH\s*:',
    'case PHP_GLOB_NOMATCH:',
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )
    if ($patched -ne $content) { Set-Content $maps -Value $patched -Encoding UTF8 }
}
