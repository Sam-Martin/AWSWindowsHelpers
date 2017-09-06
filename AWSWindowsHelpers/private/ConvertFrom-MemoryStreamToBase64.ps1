function ConvertFrom-MemoryStreamToBase64{
    param(
        [parameter(Mandatory)]
        [System.IO.MemoryStream]$inputStream
    )
    $reader = New-Object System.IO.StreamReader($inputStream);
    $inputStream.Position = 0;
    return  [System.Convert]::ToBase64String($inputStream.ToArray())
}