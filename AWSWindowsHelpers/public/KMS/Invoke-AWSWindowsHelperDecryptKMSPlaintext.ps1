function Invoke-AWSWindowsHelperDecryptKMSPlaintext{

    Param(
        [string]$Base64Secret,
        [string]$Region
    )
    # Decrypt the secret from the file
    $DecryptedOutputStream = Invoke-KMSDecrypt -CiphertextBlob $(ConvertFrom-Base64toMemoryStream -Base64Input $Base64Secret) -region $Region

    # Convert the decrypted stream to a strimg
    Return ConvertFrom-MemoryStreamToString -inputStream $DecryptedOutputStream.Plaintext
}