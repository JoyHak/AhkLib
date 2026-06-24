; https://www.autohotkey.com/boards/viewtopic.php?f=83&t=140568

#Warn
KeyHistory(25)

class Spammer {
    __New(holdKey := '', sendWhat := '', isSpeedUp := true, delayMs := 200, speedUpMs?) {          
        if (Type(sendWhat) != "String" || sendWhat == '')
            throw ValueError("Keys/text must be non-empty string", "sendWhat", sendWhat)        
        
        if (Type(delayMs) != "Integer" || delayMs < 0)
            throw ValueError("Delay must be positive integer", "delayMs", delayMs)

        this._minDelayMs     := 30        
        delayMs -= this._minDelayMs
        this.delayMs   := delayMs
        this._delayMs  := delayMs

        if !IsSet(speedUpMs)
            speedUpMs := Max(delayMs // 10 - 10, 10)
        else if (Type(speedUpMs) != "Integer" || speedUpMs <= 0)
            throw ValueError("Delay must be non-zero integer", "speedUpMs", speedUpMs) 
        
        this.speedUpMs := speedUpMs
        this.isSpeedUp := isSpeedUp && delayMs
        this.holdKey   := holdKey
        this.sendWhat  := sendWhat
    }
    
    Call() {
        if this.delayMs
            Sleep(this.delayMs)
            
        if (this.isSpeedUp 
        && (this.delayMs - this.speedUpMs) >= this._minDelayMs)
            this.delayMs -= this.speedUpMs
        
        if ((this.holdKey && !GetKeyState(this.holdKey, 'P')) 
         || (A_PriorKey && A_PriorKey != this.holdKey
             && A_TimeIdle < this.delayMs))
            return this.Stop()
            
        SendEvent(this.sendWhat)
    }
    
    Start() {        
        SetTimer(this, this._minDelayMs)
        return 1
    }
    
    Stop() {
        SetTimer(this, 0)
        this.delayMs := this._delayMs
        return 0
    }    
}