; Based on https://github.com/AutoHotkey/Ahk2Exe/blob/74db07327f9e2d3c11ee025052fc41571a5ff2d4/Lib/VersionRes.ahk
; Allows to change VERSIONINFO (file properties)

class VersionInfo {
	__New(addr := 0) {
        this.Name     := ""
        this.Data     := ""
        this.IsText   := true
        this.DataSize := 0
        this.Children := []
    
		if !addr
			return this
		
		wLength   := NumGet(addr, "UShort")
        addrLimit := addr + wLength
        addr += 2
        
		wValueLength := NumGet(addr, "UShort")
        addr += 2
		
        wType := NumGet(addr, "UShort"), 
        addr += 2
		
        szKey := StrGet(addr), 
        addr += 2 * (StrLen(szKey) + 1)
        addr  := (addr + 3) & ~3
		
		this.Name       := szKey
		this.DataSize   := wValueLength
		this.IsText     := wType
        
        size := wValueLength * (wType + 1)
        this.Data := Buffer(size * 2)
        try
            DllCall("msvcrt\memcpy", "ptr", this.Data, "ptr", addr, "ptr", size, "cdecl")
        catch
            DllCall("msvcrt\memcpy", "ptr", StrPtr(this.Data), "ptr", addr, "ptr", size, "cdecl") 
        addr += size 
        addr := (addr + 3) & ~3

		while (addr < addrLimit) {
			size := (NumGet(addr, "UShort") + 3) & ~3
			this.Children.InsertAt(1, VersionInfo(addr))
			addr += size
		}
	}
	
	__Enum(VarsNumber) => this.Children.__Enum(VarsNumber)
	
	AddChild(node) {
		this.Children.InsertAt(1, node)
	}
	
	DeleteChild(node) {
		for c in this.children {
			if (this.children[c].name = node)
				this.children.RemoveAt(c)
        }
	}
	
	GetChild(name) {
		for _, v in this {
			if (v.Name = name)
				return v
        }
	}
	
	GetText() => this.IsText ? this.Data : ''
	
	SetText(txt) {
		this.Data     := txt
		this.IsText   := true
		this.DataSize := StrLen(txt) + 1
	}
		
	Save(addr) {
		orgAddr := addr
		addr += 2
        
		NumPut("UShort", ds:=this.DataSize, addr)
        addr += 2
        
		NumPut("UShort", it:=this.IsText, addr)
        addr += 2
		addr += 2 * StrPut(this.Name, addr, "UTF-16")
		addr := (addr + 3) & ~3
        
		realSize := ds * (it + 1)
        try
            DllCall("msvcrt\memcpy", "ptr", addr, "ptr", this.Data, "ptr", realSize, "cdecl")
        catch
            DllCall("msvcrt\memcpy", "ptr", addr, "ptr", StrPtr(this.Data), "ptr", realSize, "cdecl")
        addr += realSize
		addr := (addr + 3) & ~3
        
		for _, v in this
			addr += v.Save(addr)
		
        size := addr - orgAddr
		NumPut("UShort", size, Integer(orgAddr))
		return size
	}
}

GetVersionInfo(ExeFile) {
    ; https://www.autohotkey.com/boards/viewtopic.php?f=6&t=4282&hilit=VerInfo
    err(msg) => (StdErr('Get VersionInfo error: ' msg '`n' OSError(A_LastError).Message '`n`nTarget: ' ExeFile) && Map())

    if !(dwLen := DllCall("Version.dll\GetFileVersionInfoSize", "Str", ExeFile, "Ptr", 0))
        return err('VersionInfo is unavailable')
	dwLen := VarSetStrCapacity(&lpData, dwLen + A_PtrSize)
	
    if !(DllCall("Version.dll\GetFileVersionInfo", "Str", ExeFile, "UInt", 0, "UInt", dwLen, "Ptr", StrPtr(lpData)))
        return err('Failed to get VersionInfo')
	if !(DllCall("Version.dll\VerQueryValue", "Ptr",  StrPtr(lpData), "Str", "\VarFileInfo\Translation", "PtrP", &lpBuffer := 0, "PtrP", &puLen := 0))
        return err('VerQueryValue() fail')
        
    sLangCP := Format(
        "{:04X}{:04X}", 
        NumGet(lpBuffer + 0, "UShort"), 
        NumGet(lpBuffer + 2, "UShort")
    )
	
    props := Map()
	static list := "Comments InternalName ProductName CompanyName LegalCopyright ProductVersion FileDescription LegalTrademarks PrivateBuild FileVersion OriginalFilename SpecialBuild"
	
    loop parse, list, A_Space {
		if (DllCall(
            "Version.dll\VerQueryValue", 
            "Ptr", StrPtr(lpData), 
            "Str", "\StringFileInfo\" sLangCP "\" A_LoopField, 
            "PtrP", &lpBuffer, 
            "PtrP", &puLen
        )) {
            props[A_LoopField] := StrGet(lpBuffer, puLen)
        }
	}
    
    return props
}

SetVersionInfo2(ExeFile, properties) {
    err(msg) => StdErr('Set VersionInfo error: ' msg '.`n' OSError(A_LastError).Message '`n`nTarget: ' ExeFile)

    if !properties.Count
        return false
    if !IsFile(&ExeFile)
        return err('Failed to find destination file')
        
    if !(hUpdate := DllCall("BeginUpdateResource", "str", ExeFile, "uint", 0, "ptr"))
        return err('BeginUpdateResource() fail')
        
	if !(hModule := DllCall("LoadLibraryEx", "str", ExeFile, "ptr", 0, "ptr", 2, "ptr"))
		return err('Failed to open destination file')
    
	if !(hResource := DllCall("FindResource", "ptr", hModule, "ptr", 1, "ptr", 16, "ptr"))
        return err('Failed to get file resources to update VersionInfo')
        
	hMemory   := DllCall("LoadResource", "ptr", hModule, "ptr", hResource, "ptr")
	VerInfo   := VersionInfo(DllCall("LockResource", "ptr", hMemory, "ptr"))	
    DllCall("FreeLibrary", "ptr", hModule)
	
	VerAddress := VerInfo.Data
	props := GetVerInfoChild(GetVerInfoChild(VerInfo, "StringFileInfo"), "040904b0")
	
    for prop, value in properties {
        if (!value) {
            props.DeleteChild(prop)
            continue
        } 
        
        GetVerInfoChild(props, prop).SetText(value)  
        switch (prop, false) {            
            case "FileVersion", "ProductVersion":
                ver := VersionTextToNumber(value)
                major := (ver >> 32) & 0xFFFFFFFF
                minor := ver & 0xFFFFFFFF
                
                if (prop = "FileVersion") {
                    NumPut("UInt", major, VerAddress + 8)
                    NumPut("UInt", minor, VerAddress + 12)
                } else {
                    NumPut("UInt", major, VerAddress + 16)
                    NumPut("UInt", minor, VerAddress + 20)
                } 
            
            case "Language":
                continue
        }
    }

    newVerInfo  := Buffer(16384)
	VerInfoSize := VerInfo.Save(newVerInfo.Ptr)
	
    lang := ""
	if properties.Has("Language") {
        NumPut("UShort", (lang := properties["Language"]), newVerInfo, VerInfoSize - 4)
    }                             

	DllCall(
        "UpdateResource", 
        "ptr", hUpdate, 
        "ptr", 16, 
        "ptr", 1, 
        "ushort", 0x409, 
        "ptr", 0, 
        "uint", 0, 
    "uint")	
    
    if !(DllCall(
        "UpdateResource", 
        "ptr", hUpdate, 
        "ptr", 16, 
        "ptr", 1, 
        "ushort", lang ? lang : 0x409, 
        "ptr", newVerInfo.Ptr, 
        "uint", VerInfoSize, 
    "uint")) {
        return StdErr('Failed to change VersionInfo:`t' ExeFile '`n`n' A_LastError)
    }
        
    return true
}


SetVersionInfo(ExeFile, VerInfo) {
    hUpdate := DllCall("BeginUpdateResource", "str", ExeFile, "uint", 0, "ptr")
	hModule := DllCall("LoadLibraryEx", "str", ExeFile, "ptr", 0, "ptr", 2, "ptr")
	if !hModule
		StdErr("Error: Error opening destination file. (D1)")
	
	hRsrc := DllCall("FindResource", "ptr", hModule, "ptr", 1, "ptr", 16, "ptr") ; Version Info\1
	hMem := DllCall("LoadResource", "ptr", hModule, "ptr", hRsrc, "ptr")
	vi := VersionInfo(DllCall("LockResource", "ptr", hMem, "ptr"))
	DllCall("FreeLibrary", "ptr", hModule)
	
	ffi := vi.data
        
	props := GetVerInfoChild(GetVerInfoChild(vi, "StringFileInfo"), "040904b0")
	for k,v in VerInfo
	{	if (!v)
			props.DeleteChild(k)                   ; Remove any unwanted version info
		else
		{	if !(k = "Language")
				GetVerInfoChild(props, k).SetText(v)  ; All properties, but not language
			if (k ~= "^(?i:FileVersion|ProductVersion)$")
			{	ver := VersionTextToNumber(v)
				hiPart := (ver >> 32)&0xFFFFFFFF, loPart := ver & 0xFFFFFFFF
				if (k = "FileVersion")
						NumPut("UInt", hiPart, ffi+8), NumPut("UInt", loPart, ffi+12)
				else NumPut("UInt", hiPart, ffi+16), NumPut("UInt", loPart, ffi+20)
	}	}	}
	VarSetStrCapacity(&newVI, 16384)
	viSize := vi.Save(StrPtr(newVI))
	wk := ""

	DllCall("UpdateResource", "ptr", hUpdate, "ptr", 16, "ptr", 1, "ushort", 0x409, "ptr", 0, "uint", 0, "uint")
	DllCall("UpdateResource", "ptr", hUpdate, "ptr", 16, "ptr", 1, "ushort", wk ? wk : 0x409, "ptr", StrPtr(newVI), "uint", viSize, "uint")
}

VersionTextToNumber(ver) {
	num := props := 0	
    while ((props < 4) && RegExMatch(ver, "^(\d+).?", &o)) {
		ver := SubStr(ver, o.Len + 1)
		val := Integer(o[1])
		num |= (val & 0xFFFF) << ((3 - props) * 16)
		props++
	}
	return num
}

GetVerInfoChild(VerInfo, name) {
	c := VerInfo.GetChild(name)
	if !c {
		c := VersionInfo()
		c.Name := name
		VerInfo.AddChild(c)
	}
	return c
}
