function ConvertFrom-MemoryStreamToString{
    param(
        [parameter(Mandatory)]
        [System.IO.MemoryStream]$inputStream
    )
    $reader = New-Object System.IO.StreamReader($inputStream);
    $inputStream.Position = 0;
    return $reader.ReadToEnd()
}
