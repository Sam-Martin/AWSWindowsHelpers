# PSake makes variables declared here available in other scriptblocks
# Init some things
Properties {
    # Find the build folder based on build system
    $ProjectRoot = $ENV:BHProjectPath
    $ModuleRoot = $ENV:BHModulePath
    if(-not $ProjectRoot)
    {
        $ProjectRoot = $PSScriptRoot
    }

    $Verbose = @{}
    if($ENV:BHCommitMessage -match "!verbose")
    {
        $Verbose = @{Verbose = $True}
    }
}

Task Default -Depends Deploy

Task Init {
    '----------------------------------------------------------------------'
    Set-Location $ProjectRoot
    "Build System Details:"
    Get-Item ENV:BH*
    "`n"
}

Task Deploy -Depends Init {
    '----------------------------------------------------------------------'    
    # Update Manifest version number
    $ManifestPath = $Env:BHPSModuleManifest
    
    If (-Not $env:APPVEYOR_BUILD_VERSION) {
        $Manifest = Test-ModuleManifest -Path $manifestPath
        [System.Version]$Version = $Manifest.Version
        [String]$NewVersion = New-Object -TypeName System.Version -ArgumentList ($Version.Major, $Version.Minor, $Version.Build, ($Version.Revision+1))
    } Else {
        $NewVersion = $env:APPVEYOR_BUILD_VERSION
    }
    "New Version: $NewVersion"

   
    # Update function list & manifest version
    $FunctionList = @( Get-ChildItem -Path $ModuleRoot\Public\*.ps1 -ErrorAction SilentlyContinue ).BaseName
    Update-ModuleManifest -Path $ManifestPath -ModuleVersion $NewVersion -FunctionsToExport $functionList
    
    $Params = @{
        Path = $ProjectRoot
        Force = $true
        Recurse = $false # We keep psdeploy artifacts, avoid deploying those : )
    }
    Invoke-PSDeploy @Verbose @Params
}