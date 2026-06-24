#Requires AutoHotkey v2
#Warn LocalSameAsGlobal, Off
#Warn Unreachable, Off

#Include "..\RegExMatchAll.ahk"

main() {
    links := Map()
    
    loop files, 'posts\*.html' {
        html := FileRead(A_LoopFilePath)
        html := StrReplace(html, '&amp;', '&')
    
        for link, ctx in RegExMatchAll(
            html,
            'U)<dd>Topic: <a href="(?<href>[^"]+)">(?<title>.+)<\/a>'
        ) {
            links.Set(link.href, link.title) 
            
        }
    }
    
    topics := ''
    for href, title in links
        topics .= Format('[{}]({})`n', title, href)
    
    f := FileOpen('posts\topics.md', 'w')
    f.Write(topics)
    f.Close()
}

ToolTip('Parsing...')
main()