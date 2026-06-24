; Popup message for debugging script: 
; Abort (Terminate), Retry (Reload), Ignore (Continue; Default)
Msg(text) {
    switch MsgBox(text, A_ScriptName, 2 | 512 | 262144), false {
    case 'Abort':
        ExitApp()
    case 'Retry':
        Reload()
    case 'Ignore':
        return
    }
}