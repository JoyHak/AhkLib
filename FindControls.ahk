FindControls(_winId, _classes, _flag := 0) {
    ; Recursive search for all controls from the specified array
    ; that contains win32 / custom class names without instance number (Class != ClassNN).    
    ; Returns bitwise flag where each bit represents the presence of a control from the array.
        
    ; Search in the current window using FindWindowEx():
    ; https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-findwindowexw

    for _index, _class in _classes {
        if (_class && DllCall("FindWindowEx", "ptr", _winId, "ptr", 0, "str", _class, "ptr", 0)) {
            _flag |= 1 << (_index - 1)
            _classes[_index] := ""
        }
    }

    ; Search in child windows
    _child := DllCall("FindWindowEx", "ptr", _winId, "ptr", 0, "ptr", 0, "ptr", 0)
    while (_child) {
        _flag  := FindControls(_child, _classes, _flag)
        _child := DllCall("GetWindow", "ptr", _child, "uint", 2)  ; GW_HWNDNEXT 
    }

    return _flag
}
