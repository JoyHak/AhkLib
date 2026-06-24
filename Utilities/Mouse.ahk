; https://www.autohotkey.com/boards/viewtopic.php?f=83&t=140619

class Mouse {
    static SCROLL_LIMIT       := 100    ; lines per scroll
    static MOVE_LIMIT         := 20     ; units
    
    static SPIF_UPDATEINIFILE := 3      ; update user profile, notify all apps
    
    static __New() {
        this.scrollSpeed     := this.GetScrollSpeed()
        this.moveSpeed       := this.GetMoveSpeed()
    }

    /**
     * @returns {Integer} Vertical and horizontal scrolling speed of the mouse.
     */
    static GetScrollSpeed() {
        static SPI_GETWHEELSCROLLLINES := 0x68

        DllCall(
            "SystemParametersInfoW", 
            "UInt", SPI_GETWHEELSCROLLLINES, "UInt", 0, 
            "UInt*", &curSpeed := 0, "UInt", 0
        )
        
        return curSpeed
    }
    
    /**
     * @returns {Integer} Movement speed of the mouse.
     */
    static GetMoveSpeed() {
        static SPI_GETMOUSESPEED := 0x70

        DllCall(
            "SystemParametersInfoW", 
            "UInt", SPI_GETMOUSESPEED, "UInt", 0, 
            "UInt*", &curSpeed := 0, "UInt", 0
        )
        
        return curSpeed
    }
    
    /**
     * Sets the vertical and horizontal scrolling speed of the mouse.
     * @param {Integer} speed Positive integer value.
     * @returns {Integer} New speed value between 1 and {@link Mouse.SCROLL_LIMIT}
     */
    static SetScrollSpeed(speed := 3) {
        if (speed < 1 || Type(speed) != "Integer")
            throw ValueError(A_ThisFunc ": speed must be non-zero integer", "speed", speed)
            
        if (speed > Mouse.SCROLL_LIMIT)
            throw ValueError(A_ThisFunc ": speed is reached max. limit " Mouse.SCROLL_LIMIT, "speed limit", speed)
        
        static SPI_SETWHEELSCROLLLINES := 0x69
        static SPI_SETWHEELSCROLLCHARS := 0x006D 
        
        DllCall(
            "SystemParametersInfoW",     
            "UInt", SPI_SETWHEELSCROLLLINES, 
            "UInt", speed, "Ptr", 0, 
            "UInt", Mouse.SPIF_UPDATEINIFILE
        )  
        DllCall(
            "SystemParametersInfoW",     
            "UInt", SPI_SETWHEELSCROLLCHARS, 
            "UInt", speed, "Ptr", 0, 
            "UInt", Mouse.SPIF_UPDATEINIFILE
        )     
        
        return (this.scrollSpeed := speed)
    }
    
    /**
     * Sets the movement speed of the mouse.
     * @param {Integer} speed Positive integer value.
     * @returns {Integer} New speed value between 1 and {@link Mouse.MOVE_LIMIT}
     */
    static SetMoveSpeed(speed := 10) {
        if (speed < 1 || Type(speed) != "Integer")
            throw ValueError(A_ThisFunc ": speed must be non-zero integer", "speed", speed)
            
        if (speed > Mouse.MOVE_LIMIT)
            throw ValueError(A_ThisFunc ": speed is reached max. limit " Mouse.MOVE_LIMIT, "speed limit", speed)
                                                                    
        static SPI_SETMOUSESPEED  := 0x71
        DllCall(
            "SystemParametersInfoW",     
            "UInt", SPI_SETMOUSESPEED, 
            "Ptr", 0, 
            "UInt", speed, 
            "Ptr",  Mouse.SPIF_UPDATEINIFILE
        )
        
        return (this.moveSpeed := speed)
    }
    
    /**
     * Increments (increases) the scrolling speed of the mouse.
     * @param {Integer} value An integer value that will be subtracted/added to the current speed (can be negative and zero).
     * @returns {Integer} If 1 <= speed <= {@link Mouse.SCROLL_LIMIT} - returns new speed; otherwise - current speed.
     */
    static IncrementScrollSpeed(value := 1) {
        val := this.scrollSpeed + value
        return (value && val >= 1 && val <= Mouse.SCROLL_LIMIT)
              ? this.SetScrollSpeed(val)
              : this.scrollSpeed
    }
    
    /**
     * Increments (increases) the movement speed of the mouse.
     * @param {Integer} value An integer value that will be subtracted/added to the current speed (can be negative and zero).
     * @returns {Integer} If 1 <= speed <= {@link Mouse.MOVE_LIMIT} - returns new speed; otherwise - current speed.
     */
    static IncrementMoveSpeed(value := 1) {
        val := this.moveSpeed + value
        return (value && val >= 1 && val <= Mouse.MOVE_LIMIT)
              ? this.SetMoveSpeed(val)
              : this.moveSpeed
    }
}