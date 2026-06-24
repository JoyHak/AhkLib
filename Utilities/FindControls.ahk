; https://www.autohotkey.com/boards/viewtopic.php?f=6&t=137068

FindControls(hwnd, aClasses, bFlag := 0) {
    ; Iterative search for all controls from the specified array
    ; that contains win32 / custom class names without instance number (Class != ClassNN).    
    ; Returns bitwise flag where each bit represents the presence of a control from the array.
        
    ; Search in the current window using FindWindowEx():
    ; https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-findwindowexw

    for idx, classNN in aClasses {
        if (classNN && DllCall("FindWindowEx", "ptr", hwnd, "ptr", 0, "str", classNN, "ptr", 0)) {
            bFlag |= 1 << (idx - 1)
            aClasses[idx] := ""
        }
    }

    ; Search in child windows
    hChild := DllCall("FindWindowEx", "ptr", hwnd, "ptr", 0, "ptr", 0, "ptr", 0)
    while (hChild) {
        bFlag  := FindControls(hChild, aClasses, bFlag)
        hChild := DllCall("GetWindow", "ptr", hChild, "uint", 2)  ; GW_HWNDNEXT 
    }

    return bFlag
}
