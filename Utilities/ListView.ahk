; Functions to access external ListView control
; Based on Ryan Dingman's implementation: https://p.autohotkey.com/?p=b774f86d

; ── Process memory access ──────────────────────────────────────────────────────────────────────────────────────────

/**
 * Writes data to the memory of a specified process.
 *
 * @param {Ptr} hProcess        Handle to the process whose memory is to be modified.
 * @param {Ptr} lpBaseAddress   Pointer to the base address in the target process to write to.
 * @param {Ptr} lpBuffer        Pointer to the buffer that contains the data to be written.
 * @param {UInt} nSize          Number of bytes to write.
 * @returns {UInt}              The number of bytes written, or 0 on failure.
 */
WriteProcessMemory(hProcess, lpBaseAddress, lpBuffer, nSize) {
    return DllCall(
        "WriteProcessMemory", 
        "Ptr", hProcess, 
        "Ptr", lpBaseAddress, 
        "Ptr", lpBuffer, 
        "UInt", nSize, 
        "UInt*", &lpBytesWritten := 0
    )
}

/**
 * Allocates memory in the virtual address space of a specified process.
 *
 * @param {Ptr}  hProcess           Handle to the process in which to allocate memory.
 * @param {Ptr}  lpAddress          Pointer to the desired starting address of the region to allocate, or 0 to let the system determine the address.
 * @param {UInt} dwSiz              Size of the region of memory to allocate, in bytes.
 * @param {UInt} flAllocationType   Type of memory allocation (e.g., MEM_COMMIT, MEM_RESERVE).
 * @param {UInt} flProtect          Memory protection for the region (e.g., PAGE_READWRITE).
 * @returns {Ptr} Pointer to the allocated memory address, or 0 on failure.
 */
VirtualAllocEx(hProcess, lpAddress, dwSize, flAllocationType, flProtect) {
    return DllCall(
        "VirtualAllocEx", 
        "Ptr", hProcess, 
        "Ptr", lpAddress, 
        "UInt", dwSize, 
        "UInt", flAllocationType, 
        "UInt", flProtect, 
        "Ptr"
    )
}

/**
 * Releases, decommits, or releases and decommits a region of memory within the virtual address space of a specified process.
 *
 * @param {Ptr} hProcess     Handle to the process whose memory is to be freed.
 * @param {Ptr} lpAddress    Pointer to the starting address of the region to free.
 * @param {UInt} dwSize      Size of the region to free, in bytes (typically 0 when using MEM_RELEASE).
 * @param {UInt} dwFreeType  Type of free operation (e.g., MEM_RELEASE, MEM_DECOMMIT).
 * @returns {UInt} Nonzero if successful; zero otherwise.
 */
VirtualFreeEx(hProcess, lpAddress, dwSize, dwFreeType) {
    return DllCall(
        "VirtualFreeEx", 
        "Ptr", hProcess, 
        "Ptr", lpAddress, 
        "UInt", dwSize, 
        "UInt", dwFreeType
    )
}

/**
 * Closes an open object handle (such as a process, thread, or file).
 *
 * @param {Ptr} hObject - Handle to an open object to be closed.
 * @returns {UInt} Nonzero if successful; zero otherwise.
 */
CloseHandle(hObject) => DllCall("CloseHandle", "Ptr", hObject)

; ── List View interaction ──────────────────────────────────────────────────────────────────────────────────────────

/**
  * Finds the index of a ListView item whose text matches the specified value.
  *
  * @param {hwnd} hwnd           Handle to the ListView control.
  * @param {String} text         The text to search for in the ListView.
  * @param {String} [column]     The [zero-based] [column ]index to search in.
  * @returns {Integer} The zero-based index of the found item, or `-1` if not found.
  *
  * @remarks
  *     Uses remote memory manipulation and Windows messages to get ListView item.
  *     Cleans up all allocated memory and handles after operation.
  *     Based on Ryan Dingman's implementation: https://p.autohotkey.com/?p=b774f86d
  */
FindListViewItem(hwnd, text, column := 0) {   
    static PROCESS_VM_OPERATION := 0x0008
    static PROCESS_VM_WRITE     := 0x0020
    static PROCESS_VM_READ      := 0x0010
    static PAGE_READWRITE       := 0x04
    
    static MEM_COMMIT           := 0x1000
    static MEM_RELEASE          := 0x8000
    
    hProcess := DllCall(
        "OpenProcess", 
        "UInt", PROCESS_VM_OPERATION | PROCESS_VM_WRITE | PROCESS_VM_READ, 
        "Int", false, 
        "UInt", WinGetPID("ahk_id " hwnd), 
        "Ptr"
    )
    
    if !hProcess
        return -1
    
    ; Allocate memory for LVFINDINFO structure
    static LVFINDINFO_SIZE := A_PtrSize * 4
    if !(pLVFINDINFO := VirtualAllocEx(hProcess, 0, LVFINDINFO_SIZE, MEM_COMMIT, PAGE_READWRITE)) {
        CloseHandle(hProcess)
        return -1
    }
    
    ; Allocate memory for text
    pText := 0
    textBuffer := Buffer(StrLen(text) * 2 + 2, 0)
    StrPut(text, textBuffer, 'UTF-16')
        
    if !(pText := VirtualAllocEx(hProcess, 0, textBuffer.Size, MEM_COMMIT, PAGE_READWRITE)) {
        VirtualFreeEx(hProcess, pLVFINDINFO, 0, MEM_RELEASE)
        CloseHandle(hProcess)
        return -1
    }
    
    WriteProcessMemory(hProcess, pText, textBuffer, textBuffer.Size)
        
    ; Prepare LVFINDINFO structure
    lvFindInfo := Buffer(LVFINDINFO_SIZE, 0)
    
    NumPut("UInt", 0x0002, lvFindInfo, 0)               ; LVFI_STRING flag
    NumPut("Ptr",  pText,  lvFindInfo, A_PtrSize)       ; pszText (text to search)
    NumPut("Int",  column, lvFindInfo, A_PtrSize * 3)   ; lParam for column search
    
    ; Search for index
    WriteProcessMemory(hProcess, pLVFINDINFO, lvFindInfo, LVFINDINFO_SIZE)
    result := SendMessage(0x1053, -1, pLVFINDINFO,, hwnd)  ; LVM_FINDITEMW; Start from the beginning
    
    ; Cleanup
    if pText
        VirtualFreeEx(hProcess, pText, 0, MEM_RELEASE)
        
    VirtualFreeEx(hProcess, pLVFINDINFO, 0, MEM_RELEASE)
    CloseHandle(hProcess)
    
    return result
}


/**
 * Selects (and focuses) a ListView item by index in a remote process.
 *
 * @param {hwnd} hwnd       Handle to the ListView control.
 * @param {Integer} index   The zero-based index of the item to select.
 * @returns {Boolean}       `True` if the item was successfully selected, `false` otherwise.
 *
 * @remarks
 *     Uses remote memory manipulation and Windows messages to set ListView selection.
 *     Cleans up all allocated memory and handles after operation.
 *     Based on Ryan Dingman's implementation: https://p.autohotkey.com/?p=643d8337
 */
SelectListViewItem(hwnd, index) {
    ; Messages
    static LVM_SETITEMSTATE     := 0x102B
    static LVM_GETITEMSTATE     := 0x102C

    ; Item states
    static LVIS_FOCUSED         := 0x0001
    static LVIS_SELECTED        := 0x0002

    ; Memory constants  
    static MEM_COMMIT           := 0x1000
    static MEM_RELEASE          := 0x8000
    static PAGE_READWRITE       := 0x04
    
    static PROCESS_VM_WRITE     := 0x0020
    static PROCESS_VM_READ      := 0x0010
    static PROCESS_VM_OPERATION := 0x0008
        
    ; Build LVITEM structure in remote process memory
    hProcess := DllCall(
        "OpenProcess", 
        "UInt", PROCESS_VM_OPERATION | PROCESS_VM_WRITE | PROCESS_VM_READ, 
        "Int", false, 
        "UInt", WinGetPID("ahk_id " hwnd), 
        "Ptr"
    )
    
    _LvItem := VirtualAllocEx(hProcess, 0, Size := 32, MEM_COMMIT, PAGE_READWRITE)    
    LvItem  := Buffer(Size, 0)
    
    ; Clear selection
    NumPut("UInt", 0, LvItem, 12)
    NumPut("UInt", LVIS_SELECTED | LVIS_FOCUSED, LvItem, 16)
    WriteProcessMemory(hProcess, _LvItem, LvItem, Size)
    SendMessage(LVM_SETITEMSTATE, -1, _LvItem,, hwnd)
    
    ; Set selection
    NumPut("UInt", LVIS_SELECTED | LVIS_FOCUSED, LvItem, 12)
    NumPut("UInt", LVIS_SELECTED | LVIS_FOCUSED, LvItem, 16)
    WriteProcessMemory(hProcess, _LvItem, LvItem, Size)
    SendMessage(LVM_SETITEMSTATE, index, _LvItem,, hwnd)
    
    ; Verify that target has been selected
    isSelected := SendMessage(LVM_GETITEMSTATE, index, LVIS_SELECTED,, hwnd)
    result := (isSelected & LVIS_SELECTED) != 0
    
    ; Cleanup    
    VirtualFreeEx(hProcess, _LvItem, 0, MEM_RELEASE)
    CloseHandle(hProcess)
    
    DllCall("CloseHandle", "Ptr", hProcess)
    return result
}