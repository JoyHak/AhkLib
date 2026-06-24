GetControlsText(hwnd, encoding := "UTF-16") {
    line := ''      
    for control in WinGetControlsHwnd(hwnd) {       
        line .= control
        . "|" . ControlGetClassNN(control) 
        . "|" . WinGetText(control)
        . "|" . ControlGetText(control) 
        . "`r`n"
        line .= GetControlsText(control)
    }
    
    return line
}
/*    
    ^e::{
        fileName := 'ActiveControls1.log'
        hwnd := WinExist('A')
        DetectHiddenText true
        DetectHiddenWindows true
        MsgBox(GetControlsText(hwnd))
        try FileDelete(fileName)
        try FileAppend(GetControlsText(hwnd), fileName)
    }
*/