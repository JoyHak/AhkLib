; https://www.autohotkey.com/boards/viewtopic.php?p=610331#p610331

GetControlsHwnd(hWnd, classNN := "") {
    ; Search for all controls that matches specified control win32 / custom class name
    ; without instance number (Class != ClassNN).    
    ; Returns array of found control handles (uniq IDs)
        
    ; Search in the current window using FindWindowEx():
    ; https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-findwindowexw
    
    prevHWnd  := DllCall("FindWindowExW", "ptr", hWnd, "ptr", 0, "str", classNN, "ptr", 0)
    startHWnd := prevHWnd
    hWnds     := []
            
    loop {
        nextHWnd := DllCall("FindWindowExW", "ptr", hWnd, "ptr", prevHWnd, "str", classNN, "ptr", 0)          
        
        ; The loop iterates through all the tabs over and over again, 
        ; so we must stop when it repeats
        if (nextHWnd = startHWnd)
            break
        
        prevHWnd := nextHWnd
        hWnds.push(nextHWnd)
    }
    
    return hWnds 
}