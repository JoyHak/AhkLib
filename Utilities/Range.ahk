class Range {
    __New(start, end?, step:=1) {
        if !step
            throw TypeError("Invalid 'step' parameter")
        if !IsSet(end)
            end := start, start := end == 0 ? 0 : end < 0 ? -1 : 1
        if (end < start) && (step > 0)
            step := -step
        this.start := start, this.end := end, this.step := step
    }
    __Enum(varCount) {
        start := this.start - this.step, end := this.end, step := this.step, counter := 0
        EnumElements(&element) {
            start := start + step
            if ((step > 0) && (start > end)) || ((step < 0) && (start < end))
                return false
            element := start
            return true
        }
        EnumIndexAndElements(&index, &element) {
            start := start + step
            if ((step > 0) && (start > end)) || ((step < 0) && (start < end))
                return false
            index := ++counter
            element := start
            return true
        }
        return (varCount = 1) ? EnumElements : EnumIndexAndElements
    }
}
