Function Invoke-AWSWindowsHelperEncryptKMSPlaintext{

    Param(
        [string]$KeyID,
        [string]$PlaintextString,
        [string]$Region
    )
    
    # Encrypt the output
    $EncryptedOuput = (Invoke-KMSEncrypt -KeyId $keyID -Plaintext $(ConvertFrom-StringToMemoryStream $PlaintextString) -region $Region)

    # Convert it to Base64 so we can write it to a file
    Return ConvertFrom-MemoryStreamToBase64 -inputStream $EncryptedOuput.CiphertextBlob
}