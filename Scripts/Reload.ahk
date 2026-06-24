; Reload active script after saving it by Ctrl+S if it's opened in your IDE

#SingleInstance force
#Warn

A_HotkeyInterval := 0
ListLines(false)
SetKeyDelay(-1, -1)

InTitle(WinTitle, needle) {
    try {
        if WinActive(WinTitle) {
            return InStr(
                WinGetTitle(), 
                needle
            )
        }
    }
    return false
}


#HotIf InTitle('ahk_exe notepad++.exe', A_ScriptName)
    ~^sc01F::{
        Sleep(1000)
        Reload
    }
    ~^+Del::{
        Sleep(1000)
        ExitApp
    }

#HotIf
    ~^+!Del::ExitApp
