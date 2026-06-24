/**
 * Creates small GUI with edit field and specified text.
 * @param {string} prompt Text before the edit field
 * @param {func} callback Function that will be called 
 * on button/Enter click with edit field value.
 * @example https://github.com/JoyHak/Radify/tree/Radially#path-find
 * @example https://github.com/user-attachments/assets/68b2491a-9537-4ca4-a180-ec83b3030bba
*/
Prompt(prompt := 'App name:', callback := (value) => 0) {
    ui := Gui('-E0x200 -SysMenu +DPIScale', A_ScriptName)
    ui.SetFont('s12 q5', 'Maple Mono Normal NF CN')
    
    ui.OnEvent('Close',   (*) => ui.Destroy())
    ui.OnEvent('Escape',  (*) => ui.Destroy())
    
    ui.AddText(, prompt)
    e := ui.AddEdit('x+m yp-4 w100 -wrap')
    e.Focus()
    
    ui.AddButton('x+m yp-4 w30 h30 -wrap +default', '=>')
      .OnEvent('Click', (*) => (ui.Submit(), callback(e.value)))
    
    ui.Show('Center')
}