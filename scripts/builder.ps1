param (
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    [string]
    $extension,
    [Parameter(Position = 1, Mandatory = $true)]
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    [string]
    $repo,
    [Parameter(Position = 2, Mandatory = $true)]
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    [string]
    $branch,
    [Parameter(Position = 3, Mandatory = $true)]
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    [string]
    $dev_repo,
    [Parameter(Position = 4, Mandatory = $true)]
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    [string]
    $dev_branch,
    [Parameter(Position = 5, Mandatory = $true)]
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    [string]
    $config_args,
    [Parameter(Position = 6, Mandatory = $true)]
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    [string]
    $sdk_version,
    [Parameter(Position = 7, Mandatory = $true)]
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    [string]
    $vs,
    [Parameter(Position = 8, Mandatory = $true)]
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    [string]
    $arch,
    [Parameter(Position = 9, Mandatory = $false)]
    [string]
    $ts,
    [Parameter(Position = 10, Mandatory = $true)]
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    [string]
    $php
)

Function Cleanup() {
    if(Test-Path $ext_dir) {
        Remove-Item $ext_dir -Recurse -Force
    }
    if(Test-Path $cache_dir) {
        Remove-Item $cache_dir -Recurse -Force
    }
    New-Item -Path $cache_dir -ItemType "directory"
}

Function Get-LatestGitTag() {
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]
        $repo
    )
    $lsRemoteOutput = git ls-remote --tags $repo 2>&1
    $versionTags = @()
    foreach ($line in $lsRemoteOutput -split "`n") {
        $line = $line.Trim()
        if (-not $line) { continue }
        $match = [regex]::Match($line, '\d+\.\d+(?:\.\d+)?(?:\.\d+)$')
        if ($match.Success) {
            $versionObj = [version]$match.Value
            $versionTags += [PSCustomObject]@{
                Tag     = $match.Value
                Version = $versionObj
            }
        }
    }

    return ($versionTags | Sort-Object Version -Descending | Select-Object -First 1).Tag
}

Function Get-Extension() {
    if ($repo -like "*pecl.php.net*") {
        if($branch -eq 'latest') {
            $content = [xml](Invoke-WebRequest -Uri "https://pecl.php.net/rest/r/$extension/allreleases.xml").Content
            foreach($i in $content.a.r) { 
                if($i.s -eq 'stable') { 
                    $branch = $i.v; 
                    break; 
                }
            }
        }
        New-Item "$ext_dir" -ItemType "directory" -Force > $null 2>&1
        Invoke-WebRequest -Uri "https://pecl.php.net/get/$extension-$branch.tgz" -OutFile "$ext_dir\$extension-$branch.tgz" -UseBasicParsing
        & tar -xzf "$ext_dir\$extension-$branch.tgz" -C $ext_dir
        Copy-Item -Path "$ext_dir\$extension-$branch\*" -Destination $ext_dir -Recurse -Force
        Remove-Item -Path "$ext_dir\$extension-$branch" -Recurse -Force        
    } else {        
        if($php -match $dev_branch_versions) {
            git clone --branch=$dev_branch $github/$dev_repo.git $ext_dir
        } else {
            if($branch -eq 'latest_stable_tag') {
                $branch = Get-LatestGitTag $github/$repo.git
            }
            git clone --branch=$branch $github/$repo.git $ext_dir            
        }
    }
    $patch = Join-Path (Split-Path -Parent $PSScriptRoot) "patches/$extension.ps1"
    if(Test-Path $patch) {
        & $patch -php $php -path $ext_dir
    }
}

Function Get-Package {
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]
        $package,
        [Parameter(Position = 1, Mandatory = $true)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]
        $url,
        [Parameter(Position = 2, Mandatory = $true)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]
        $tmp_dir,
        [Parameter(Position = 3, Mandatory = $true)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]
        $package_dir
    )
    if (-not (Test-Path $cache_dir\$package)) {
        Invoke-WebRequest $url -OutFile "$cache_dir\$package"
    }

    if (-not (Test-Path $package_dir)) {
        Expand-Archive -Path $cache_dir\$package -DestinationPath $cache_dir -Force
        if($tmp_dir -ne $package_dir) {
            Rename-Item -Path $cache_dir\$tmp_dir -NewName $package_dir -Force
        }
    }
}

Function Add-TaskFile() {
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]
        $filename
    )
    $bat_content = @()
    $bat_content += ""
    $bat_content += "call phpize 2>&1"
    $bat_content += "call configure --$config_args --enable-debug-pack 2>&1"
    $bat_content += "nmake /nologo 2>&1"
    $bat_content += "exit %errorlevel%"
    Set-Content -Encoding "ASCII" -Path $filename -Value $bat_content
}

Function Get-TSPath() {
    if($ts -eq 'nts') {
        return '-nts'
    }

    return ''
}

Function Get-ReleaseDirectory() {
    $arch_path = ''
    if($arch -eq 'x64') {
        $arch_path = 'x64'
    }

    $release_path = 'Release'
    if($ts -eq 'ts') {
        $release_path = 'Release_TS'
    }

    return [IO.Path]::Combine($arch_path, $release_path)
}

Function Get-PHPBranch() {
    $php_branch = 'master'
    if($php -ne $nightly_version) {
        $php_branch = "PHP-$php"
    }

    return $php_branch
}

Function Get-VSToolset() {
    $toolsets = @{
        "vc14" = "14.0"
    }
    $MSVCDirectory = vswhere -latest -products * -find "VC\Tools\MSVC"
    foreach ($toolset in (Get-ChildItem $MSVCDirectory)) {
        $major, $minor = $toolset.Name.split(".")[0,1]
        if(14 -eq $major) {
            if (9 -ge $minor) {
                $toolsets."vc14" = $toolset
            } elseif (19 -ge $minor) {
                $toolsets."vc15" = $toolset
            } elseif (29 -ge $minor) {
                $toolsets."vs16" = $toolset
            } else {
                $toolsets."vs17" = $toolset
            }
        }
    }
    $toolset = $toolsets.$vs
    if (-not $toolset) {
        throw "No toolset found for $vs"
    }
    return $toolset.Name
}

Function Build-Extension() {
    $ts_path = Get-TSPath
    $package_zip = "php-devel-pack-$php_version$ts_path-Win32-$vs-$arch.zip"
    $tmp_dir = "php-$php_version-devel-$vs-$arch"
    $package_dir = "php-$php_version$ts_path-devel-$vs-$arch"
    $url = "$trunk/$package_zip"
    Get-Package $package_zip $url $tmp_dir $package_dir

    Set-Location $ext_dir
    Add-TaskFile "task.bat"
    $env:PATH = "$cache_dir\$package_dir;$env:PATH"
    $builder = "$cache_dir\php-sdk-$sdk_version\phpsdk-$vs-$arch.bat"
    $task = (Get-Item -Path "." -Verbose).FullName + '\task.bat'
    & $builder -s (Get-VSToolset) -t $task
}

Function Copy-Extension() {
    Set-Location $workspace
    New-Item -Path $extension -ItemType "directory"
    $release_dir = Get-ReleaseDirectory
    $ext_path = [IO.Path]::Combine($ext_dir, $release_dir, "php_$extension.dll")
    Write-Output "Extension Path: $ext_path"
    if(Test-Path $ext_path) {
        Copy-Item -Path $ext_path -Destination "$extension\php$php`_$ts`_$arch`_$extension.dll"
        Get-ChildItem $extension
    } else {
        exit 1
    }
}

$workspace = (Get-Location).Path
$cache_dir = "C:\build-cache"
$ext_dir = "C:\projects\$extension"
$github = "https://github.com"
$trunk = "$github/shivammathur/php-builder-windows/releases/download/php$php"
$dev_branch_versions = '8.[5-6]'
$nightly_version = Invoke-RestMethod "https://raw.githubusercontent.com/php/php-src/master/main/php_version.h" | Where-Object { $_ -match '(\d+\.\d+)\.' } | Foreach-Object {$Matches[1]}
$php_branch = Get-PHPBranch
$php_version = Invoke-RestMethod "https://raw.githubusercontent.com/php/php-src/$php_branch/main/php_version.h" | Where-Object { $_  -match 'PHP_VERSION "(.*)"' } | Foreach-Object {$Matches[1]}
$package_zip = "php-sdk-$sdk_version.zip"
$tmp_dir = "php-sdk-binary-tools-php-sdk-$sdk_version"
if($sdk_version -eq 'master') {
    $package_zip = "master.zip"
    $tmp_dir = "php-sdk-binary-tools-master"
}
$package_dir = "php-sdk-$sdk_version"
$url = "$github/php/php-sdk-binary-tools/archive/$package_zip"
Cleanup
Get-Package $package_zip $url $tmp_dir $package_dir
Get-Extension
Build-Extension
Copy-Extension
