Set-Clipboard(Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey
Write-Host -NoNewLine 'Chave copiada (CTRL + V) - Pressionar qualquer tecla para sair...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');