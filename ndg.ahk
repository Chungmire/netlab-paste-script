#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

; **Variables**
global HotkeyStrings := {}  ; Associative array to store hotkey-string pairs
global PasteHotkey := "F4"  ; Default paste hotkey

; **Add Tray Menu Item to Show the GUI**
Menu, Tray, Add, Show GUI, ShowGUI
Menu, Tray, Default, Show GUI  ; Set 'Show GUI' as the default action
Menu, Tray, Click, 1  ; Enable single-click to trigger default tray action

; **Assign the Paste Hotkey**
Hotkey, %PasteHotkey%, PasteClipboard, On

; **Create the GUI**
Gui, Font, s10, Segoe UI  ; Sets the font to Segoe UI with size 10
Gui, Add, Text,, Paste Clipboard Hotkey:
Gui, Add, Hotkey, vPasteHotkeyInput, %PasteHotkey%
Gui, Add, Button, gSetPasteHotkey, Change Paste Hotkey

Gui, Add, Text,,
Gui, Add, Text,, ------------------------------------------------------------

Gui, Add, Text,, Custom Hotkey:
Gui, Add, Hotkey, vHotkeyInput, ; vHotkeyInput variable to store the hotkey
Gui, Add, Text,, Text to send:
Gui, Add, Edit, vStringInput Multi w300 h50, ; **Multi-line Edit Control**
Gui, Add, Button, gAddHotkey, Add Hotkey

Gui, Add, Text,,
Gui, Add, Text,, ------------------------------------------------------------
Gui, Add, Text,, Your Hotkeys:
Gui, Add, ListView, r5 w300 vHotkeyListView AltSubmit, Hotkey|String

; **Add Delete Button**
Gui, Add, Button, gDeleteHotkey, Delete Hotkey
Gui, Add, Button, gHideGUI, Hide GUI

; Populate the ListView with any existing hotkeys
RefreshHotkeyList()

Gui, Show,, Define Hotkeys

return  ; End of auto-execute section

; **Set Paste Hotkey Button Action**
SetPasteHotkey:
    Gui, Submit, NoHide
    if (PasteHotkeyInput = "")
    {
        MsgBox, 48, Error, Please enter a valid paste hotkey.
        return
    }

    ; **Check for Hotkey Conflicts**
    ; Check if the new paste hotkey conflicts with any existing hotkeys
    if (HotkeyStrings.HasKey(PasteHotkeyInput))
    {
        MsgBox, 48, Error, The paste hotkey "%PasteHotkeyInput%" conflicts with an existing hotkey. Please choose a different hotkey.
        return
    }

    ; Remove previous paste hotkey
    Hotkey, %PasteHotkey%, PasteClipboard, Off

    ; Set new paste hotkey
    PasteHotkey := PasteHotkeyInput
    Hotkey, %PasteHotkey%, PasteClipboard, On

return

; **Function to Paste Clipboard Content**
PasteClipboard:
    if (Clipboard != "")
    {
        SetKeyDelay, 0, 0
        SendInput, %Clipboard%
    }
return

; **Add Hotkey Button Action**
AddHotkey:
    ; Retrieve the values from the GUI
    Gui, Submit, NoHide

    ; **Validate Inputs**
    if (HotkeyInput = "" || StringInput = "")
    {
        MsgBox, 48, Error, Please enter both a hotkey and a string.
        return
    }

    ; **Check for Hotkey Conflicts**
    ; Check if the hotkey conflicts with the paste hotkey
    if (HotkeyInput = PasteHotkey)
    {
        MsgBox, 48, Error, The hotkey "%HotkeyInput%" conflicts with the paste hotkey. Please choose a different hotkey.
        return
    }

    ; Check if the hotkey already exists
    if (HotkeyStrings.HasKey(HotkeyInput))
    {
        MsgBox, 48, Error, The hotkey "%HotkeyInput%" is already assigned. Please choose a different hotkey.
        return
    }

    ; **Assign the Hotkey Dynamically**
    Hotkey, %HotkeyInput%, SendString, On

    ; **Store the String Associated with the Hotkey**
    HotkeyStrings[HotkeyInput] := StringInput

    ; **Update the Hotkey ListView**
    RefreshHotkeyList()

    ; **Clear Inputs**
    GuiControl,, HotkeyInput
    GuiControl,, StringInput

    ; **Refocus HotkeyInput Control**
    GuiControl, Focus, HotkeyInput
return


; **Delete Hotkey Button Action**
DeleteHotkey:
    Gui, Submit, NoHide

    ; Get the selected row in the ListView
    RowIndex := LV_GetNext(0, "Focused")
    if (!RowIndex)
    {
        MsgBox, 48, Error, Please select a hotkey to delete.
        return
    }

    LV_GetText(SelectedHotkey, RowIndex, 1)

    ; Remove the hotkey assignment
    Hotkey, %SelectedHotkey%, SendString, Off

    ; Remove the hotkey from the associative array
    HotkeyStrings.Delete(SelectedHotkey)

    ; **Update the Hotkey ListView**
    RefreshHotkeyList()

return

; **Function to Send the String When Hotkey is Pressed**
SendString:
    ; Get the string associated with the pressed hotkey
    StringToSend := HotkeyStrings[A_ThisHotkey]
    if (StringToSend != "")
    {
        SetKeyDelay, 0, 0
        SendInput, %StringToSend%
    }
    else
    {
        MsgBox, 48, Error, No string found for hotkey "%A_ThisHotkey%".
    }
return

; **Function to Refresh the Hotkey ListView**
RefreshHotkeyList()
{
    GuiControl, -Redraw, HotkeyListView
    LV_Delete()  ; Clear the ListView
    for Hotkey, String in HotkeyStrings
    {
        LV_Add("", Hotkey, String)
    }
    GuiControl, +Redraw, HotkeyListView
}

; **Hide GUI Button Action**
HideGUI:
    Gui, Hide  ; Hide the GUI window
return

; **Tray Menu Item to Show GUI**
ShowGUI:
    Gui, Show
return

#IfWinActive, Define Hotkeys  ; Context-sensitive hotkeys active only when the GUI is open

    ; Handle Enter key
    Enter::
        ControlGetFocus, focusedControl, Define Hotkeys
        if (focusedControl = "Edit1")
        {
            Gosub, AddHotkey  ; Trigger the AddHotkey action
            return
        }
        else
        {
            Send, {Enter}  ; Default behavior
        }
    return

    ; Handle Ctrl+Enter key
    ^Enter::
        ControlGetFocus, focusedControl, Define Hotkeys
        if (focusedControl = "Edit1")
        {
            Send, {Enter}  ; Insert a newline in the StringInput edit box
            return
        }
        else
        {
            Send, ^{Enter}  ; Default behavior
        }
    return

#IfWinActive  ; End of context-sensitive hotkeys