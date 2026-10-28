$shell = New-Object -ComObject Shell.Application
$myComputer = $shell.Namespace(17)
$phone = $null
foreach ($item in $myComputer.Items()) {
    if ($item.Name -like "*A07*" -or $item.Name -like "*Salah*") {
        $phone = $item
        break
    }
}

if ($phone -ne $null) {
    Write-Output "Phone found: $($phone.Name)"
    $phoneFolder = $phone.GetFolder
    foreach ($storage in $phoneFolder.Items()) {
        Write-Output "Storage: $($storage.Name)"
        $storageFolder = $storage.GetFolder
        $downloadFolder = $null
        foreach ($f in $storageFolder.Items()) {
            if ($f.Name -like "*Download*" -or $f.Name -like "*Téléchargement*") {
                $downloadFolder = $f.GetFolder
                Write-Output "Found Download folder: $($f.Name)"
            }
        }
        if ($downloadFolder -ne $null) {
            $debugApk = "C:\Users\tlp07\Desktop\Nouveau dossier\mobile_app\build\app\outputs\flutter-apk\app-debug.apk"
            $releaseApk = "C:\Users\tlp07\Desktop\Nouveau dossier\mobile_app\build\app\outputs\flutter-apk\app-release.apk"
            
            $apkSource = $debugApk
            if ((Test-Path $debugApk) -and (Test-Path $releaseApk)) {
                $debugTime = (Get-Item $debugApk).LastWriteTime
                $releaseTime = (Get-Item $releaseApk).LastWriteTime
                if ($releaseTime -gt $debugTime) {
                    $apkSource = $releaseApk
                } else {
                    $apkSource = $debugApk
                }
            } elseif (Test-Path $releaseApk) {
                $apkSource = $releaseApk
            }
            
            if (Test-Path $apkSource) {
                $fileInfo = Get-Item $apkSource
                Write-Output "Transfert du fichier le plus récent : $($fileInfo.Name) ($([math]::Round($fileInfo.Length / 1MB, 1)) Mo, modifié le $($fileInfo.LastWriteTime))"
                $downloadFolder.CopyHere($apkSource, 16)
                Write-Output "APK Copié avec succès dans : $($phone.Name) / Download !"
            }
        }
    }
} else {
    Write-Output "Téléphone non détecté en mode MTP (Explorateur de fichiers)."
    Write-Output "Vérification via ADB..."
    $adbDevices = (adb devices) | Out-String
    if ($adbDevices -match "(?m)^([A-Za-z0-9]+)\s+device$") {
        $deviceId = $matches[1]
        Write-Output "Appareil ADB détecté : $deviceId"
        $apkToInstall = "C:\Users\tlp07\Desktop\Nouveau dossier\mobile_app\build\app\outputs\flutter-apk\app-debug.apk"
        Write-Output "Installation directe via adb install -r $apkToInstall ..."
        adb -s $deviceId install -r $apkToInstall
    } else {
        Write-Output "Aucun appareil ADB détecté. Assurez-vous de brancher le câble USB et de déverrouiller l'écran du téléphone."
    }
}
