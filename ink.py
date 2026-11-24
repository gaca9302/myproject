import os
import win32com.client
shortcut_path = "invoice.pdf.lnk"
shell = win32com.client.Dispatch("WScript.Shell")
shortcut = shell.CreateShortcut(shortcut_path)
shortcut.TargetPath = os.path.join(os.environ["WINDIR"],"System32","WindowsPowerShell","v1.0","powershell.exe")
shortcut.Arguments = "-NoExit -c \"write-host \"hello world\"\""
shortcut.WorkingDirectory = os.getcwd()
#shortcut.IconLocation = r"C:\Windows\System32\imageres.dll,15"
shortcut.IconLocation = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe,11"
shortcut.Save()
print("Создан:", shortcut_path)

'''
import os
import win32com.client
shell = win32com.client.Dispatch("WScript.Shell")
for i in range(100):
    shortcut = shell.CreateShortcut(f"icon_{i}.lnk")
    shortcut.TargetPath = os.path.join(os.environ["WINDIR"],"System32","notepad.exe"    )
    shortcut.IconLocation = fr"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe,{i}"
    shortcut.Save()
print("Создано 100 тестовых ярлыков")'''
