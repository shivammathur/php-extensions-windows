param(
  [Parameter(Mandatory = $true)]
  [string]$php,
  [Parameter(Mandatory = $true)]
  [string]$path
)

if($php -match '^8\.[6-7]$') {
    $stream = Get-Content "$path\shared\core_stream.cpp" -Raw
    $stream = $stream -replace ([regex]::Escape('php_stream_context* STREAMS_DC')), 'php_stream_context* context STREAMS_DC'
    $stream = $stream -replace ([regex]::Escape('php_stream_wrapper_log_error(wrapper, options,')), 'php_stream_wrapper_log_warn(wrapper, context, options, InvalidParam,'
    $stream | Set-Content "$path\shared\core_stream.cpp" -Encoding UTF8 -NoNewline
}

if($php -eq '8.7') {
    # Include child_init_func and keep the module properties positional for C++.
    (Get-Content "$path\pdo_init.cpp") -replace 'STANDARD_MODULE_PROPERTIES_EX', 'NULL, 0, 0, NULL, 0, ZEND_MODULE_BUILD_ID' | Set-Content "$path\pdo_init.cpp"
}

(Get-Content $path\config.w32) -replace '/sdl', '' | Set-Content $path\config.w32
