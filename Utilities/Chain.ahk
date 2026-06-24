#Requires AutoHotkey v2

class Chainable {
    __New(value := '') {
        this.value := value
    }

    o0(f, params*) {
        if IsObject(f) {
            this.value := f(this.value, params*)
        } else if IsSet(f) {
            this.value := %f%(this.value, params*)
        }

        return this
    }
}

class o0 extends Chainable {

}

; Example
; o0("    Hello world!").o0(Trim).o0(StrUpper).o0(MsgBox)
