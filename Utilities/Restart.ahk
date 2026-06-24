; Restart specific window/script
Restart(WinTitle := "A") {
    path := WinGetProcessPath(WinTitle)
    name := WinGetProcessName(WinTitle)
    WinTitle   := "ahk_exe " name
    WaitTimout := 10 
    
    processQuery := 
    (Join`s
       "select processId, commandLine 
        from Win32_Process 
        where CommandLine like '%" name "%'"
    )
    
    for p in ComObjGet("winmgmts:").ExecQuery(processQuery) {
        if !InStr(p.commandLine, path)
            continue
            
        WinClose(WinTitle)
        WinWaitNotActive(WinTitle, , WaitTimout)
        Run(p.commandLine)
        
        if WinWaitActive(WinTitle, , WaitTimout) {
            WinActivate(WinTitle) 
        } 
    }
            
}