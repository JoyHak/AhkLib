; Checks if active window has keyboard focus
IsFocused() {
    static hOleacc := DllCall("LoadLibraryW", "Str", "oleacc.dll", "Ptr")
    
    ; Cache data
    hWnd := DllCall("GetForegroundWindow")
    static hLast := 0
    static timeLast := 0
    
    isCached := (hLast == hWnd) && (A_Now - timeLast < 7)
    
    hLast := hWnd
    timeLast := A_Now
    
    if isCached
        return true
    
    static idObject := 0xFFFFFFF8  ; OBJID_CARET
    static flag := idObject & 0xFFFFFFFF

    obj := NumPut("int64", 0x11CF3C3D618736E0, IID := Buffer(16))
    IID_IAccessible := -16 + NumPut("int64", 0x719B3800AA000C81, obj)
    
    oAcc := ComValue(9, 0)
    
    if (DllCall(
        "oleacc\AccessibleObjectFromWindow", 
        "ptr", hwnd, 
        "uint", flag, 
        "ptr", IID_IAccessible, 
        "ptr*", oAcc)) {
        return false
    }
    
    x := Buffer(4) 
    y := Buffer(4) 
    w := Buffer(4) 
    h := Buffer(4)

    try {
        Get(&cord) => ComValue(0x4003, cord.ptr, 1)
        oAcc.accLocation(Get(&x), Get(&y), Get(&w), Get(&h), 0)
    } catch {
        return false
    }

    X := NumGet(x, 0, "int")
    Y := NumGet(y, 0, "int")
    W := NumGet(w, 0, "int")
    
    return X && Y && W
}