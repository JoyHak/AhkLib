; https://www.autohotkey.com/boards/viewtopic.php?f=83&t=140529&p=619538#p619538

class KeyboardLayout {
    static layouts := Map(
        'ru', 0x04190419,  ; RU
        'en', 0x04090409,  ; EN
        'de', 0x00000407,  ; German
        'fr', 0x0000040C,  ; French
        'es', 0x0000040A,  ; Spanish
        'it', 0x00000410,  ; Italian
        'pt', 0x00000416,  ; Portuguese (Brazil)
        'uk', 0x00000422,  ; Ukrainian
        'pl', 0x00000415,  ; Polish
        'cz', 0x00000405,  ; Czech
        'sk', 0x0000041B,  ; Slovak
        'hu', 0x0000040E,  ; Hungarian
        'nl', 0x00000413,  ; Dutch
        'da', 0x00000406,  ; Danish
        'fi', 0x0000040B,  ; Finnish
        'sv', 0x0000041D,  ; Swedish
        'no', 0x00000414,  ; Norwegian
        'tr', 0x0000041F,  ; Turkish
        'el', 0x00000408,  ; Greek
        'ja', 0x00000411,  ; Japanese
        'ko', 0x00000412,  ; Korean
        'zh', 0x00000404,  ; Chinese (Taiwan)
        'ar', 0x00000401,  ; Arabic
        'he', 0x0000040D,  ; Hebrew
        'fa', 0x00000429,  ; Persian
        'vi', 0x0000042A,  ; Vietnamese
        'bg', 0x00000402,  ; Bulgarian
        'hr', 0x0000041A,  ; Croatian
        'sl', 0x00000424,  ; Slovenian
        'et', 0x00000425,  ; Estonian
        'lv', 0x00000426,  ; Latvian
        'lt', 0x00000427,  ; Lithuanian
        'is', 0x0000040F,  ; Icelandic
        'sq', 0x0000041C,  ; Albanian
        'mk', 0x0000042F,  ; Macedonian
        'hi', 0x00000439,  ; Hindi
        'th', 0x0000041E,  ; Thai
        'id', 0x00000421,  ; Indonesian
        'ms', 0x0000043E,  ; Malay
        'ca', 0x00000403,  ; Catalan
        'eu', 0x0000042D,  ; Basque
        'gl', 0x00000456,  ; Galician
        'am', 0x0000045E,  ; Amharic
        'ta', 0x00000449,  ; Tamil
        'te', 0x0000044A,  ; Telugu
        'ur', 0x00000420,  ; Urdu
        'bn', 0x00000445,  ; Bengali
        'gu', 0x00000447,  ; Gujarati
        'kn', 0x0000044B,  ; Kannada
        'ml', 0x0000044C,  ; Malayalam
        'mr', 0x0000044E,  ; Marathi
        'or', 0x00000448,  ; Odia
        'pa', 0x00000446,  ; Punjabi
        'si', 0x0000045B   ; Sinhala
    )
    
    static WM_INPUTLANGCHANGEREQUEST := 0x50

    static Set(id)  => PostMessage(KeyboardLayout.WM_INPUTLANGCHANGEREQUEST, 0, id, , 'A')
    static _Set(id) => SendMessage(KeyboardLayout.WM_INPUTLANGCHANGEREQUEST, 0, id, , 'A')
    
    static __Item[locale] {
        get {
            if (locale is String)
                return KeyboardLayout.layouts[locale]
                
            if !(locale is Integer)
                throw ValueError('ID must be hexadecimal number', , locale)
                
            for loc, id in KeyboardLayout.layouts {
                if (id == locale)
                    return loc
            }
            
            throw ValueError('Unknown ID', , locale)
        }
        
        set {
            if (value != true)
                throw TypeError('Value must be boolean to enable layout', , Type(value))
                
            this._Set(KeyboardLayout.layouts[locale])
        }
    }

    static Get() => DllCall(
        'GetKeyboardLayout', 'Ptr', 
            DllCall(
                'GetWindowThreadProcessId', 
                'Ptr', DllCall('GetForegroundWindow'), 
                'UInt', 0
            )
        )
    
    static _Toggle() {    
        static toggle := KeyboardLayout['ru'] == this.Get()
        layoutId := toggle ? KeyboardLayout['en'] : KeyboardLayout['ru']
        
        this._Set(layoutId)
            
        while (layoutId != this.Get())
            Sleep(100)
        
        toggle ^= 1    
        return layoutId
    }


    static Toggle() {
        ; SendLevel = 3: intercept all keys including AHK-generated;
        ; Timeout = 2 sec.: stop after 2 seconds (unless .Stop() has been called during that period) 
        static hook := InputHook('I3 T2')
        
        hook.Start()
        this._Toggle()            

        loop parse, hook.Input {
            SendEvent('{vk' GetKeyVK(A_LoopField) '}')
        }  
        hook.Stop()
    }
}