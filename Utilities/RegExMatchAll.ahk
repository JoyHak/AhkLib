; Usage example: https://github.com/JoyHak/MarkdownToBBCode/blob/952871b510947fb69956ee551a5d62d38d187c06/Lib/convert.ahk#L116
; Replacement example: https://github.com/JoyHak/MarkdownToBBCode/blob/952871b510947fb69956ee551a5d62d38d187c06/Lib/convert.ahk#L233

class RegExMatchAll {
	__New(haystack, needle) {
		this.Haystack := haystack
		this.Needle   := needle
	}

	__Enum(n) {
		this.Pos := 0
        return Next

        Next(&match, &context) {
            if this.HasProp('Replacement') {
                this.Haystack := SubStr(this.Haystack, 1, this.Pos - 1)
                               . this.Replacement
                               . SubStr(this.Haystack, this.Pos + this.match.Len)

                this.DeleteProp('Replacement')
            }

            context    := this
            try {
                this.Pos   := RegExmatch(this.Haystack, this.Needle, &match, this.Pos + 1)
                this.match := match
            } catch {
                MsgBox(this.match.keyword '' this.match.params '`n' this.match.descr '`n`n' this.match.description)
            }
            return this.Pos != 0
        }
	}
}