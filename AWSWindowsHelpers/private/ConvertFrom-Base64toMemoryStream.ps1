function ConvertFrom-Base64toMemoryStream{
    param(
        [parameter(Mandatory)]
        [string]$Base64Input
    )

    [byte[]]$bytearray = [System.Convert]::FromBase64String($Base64Input)
    $stream = New-Object System.IO.MemoryStream($bytearray,0,$bytearray.Length)
    return $stream
}