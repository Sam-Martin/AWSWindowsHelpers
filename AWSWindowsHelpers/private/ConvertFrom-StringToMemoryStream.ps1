function ConvertFrom-StringToMemoryStream{
    param(
        [parameter(Mandatory)]
        [string]$InputString
    )
    $stream = New-Object System.IO.MemoryStream;
    $writer = New-Object System.IO.StreamWriter($stream);
    $writer.Write($InputString);
    $writer.Flush();
    return $stream
}