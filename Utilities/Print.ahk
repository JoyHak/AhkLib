; Convert anything to string: Object, Array, ...

FormatValue(v) => Type(v) == 'String' ? '"' v '"' : v

Dump(v) {    
    name := FormatTime(, "dd-MM HH-mm-ss") . '-' . Random(0, 100) . '.log'
    FileAppend(v, name)
}

Print(val, level := 0, seen := 0) {
    static MAX_DEPTH := 1000

    ; Initializing a set of already visited objects (to protect against loops)
    if !IsObject(seen)
        seen := Map()

    indent := Format("{:" level "}", "    ")    
    out := ""

    t := Type(val)

    ; Primitives
    if t ~= "^(Integer|Float|String|Number|Decimal|VarRef|Buffer|Func)$" {
        out .= indent . "[" t "] " . FormatValue(val) . "`n"
        if level = 0
            Dump(out)
        return out
    }

    if !IsObject(val) {
        out .= indent . "[Unknown:" t "]`n"
        if level = 0
            Dump(out)
        return out
    }

    ; Objects / arrays / Map, etc.
    ; Infinite loop protection
    if seen.Has(val) {
        out .= indent . "[" t "] <circular ref>`n"
        if level = 0
            Dump(out)
        return out
    }
    seen[val] := true

    out .= indent . "[" t "] {`n"

    if level >= MAX_DEPTH {
        out .= indent . "    <max depth reached>`n"
        out .= indent . "}`n"
        if level = 0
            Dump(out)
        return out
    }

    ; For Array/Map we list by indexes/keys
    if t = "Array" {
        for i, v in val {
            out .= indent . "    [" i "]:`n"
            out .= Print(v, level + 2, seen)
        }
    } else if t = "Map" {
        for k, v in val {
            out .= indent . '    "' k '":`n'
            out .= Print(v, level + 2, seen)
        }
    } else {
        ; General Object: list own properties.
        for name, v in val.OwnProps() {
            out .= indent . "    ." name ":`n"
            out .= Print(v, level + 2, seen)
        }
    }

    out .= indent . "}`n"

    if level = 0
        Dump(out)
    return out
}