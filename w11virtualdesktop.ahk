; AutoHotkey v1 script

; Get hwnd of AutoHotkey window, for listener

; Path to the DLL, relative to the script
;VDA_PATH := A_ScriptDir . "\target\debug\VirtualDesktopAccessor.dll"
VDA_PATH := A_ScriptDir . ".\VirtualDesktopAccessor.dll"
hVirtualDesktopAccessor := DllCall("LoadLibrary", "Str", VDA_PATH, "Ptr")

GoToDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GoToDesktopNumber", "Ptr")
MoveWindowToDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "MoveWindowToDesktopNumber", "Ptr")

MoveCurrentWindowToDesktop(desktopNumber) {
    global MoveWindowToDesktopNumberProc, GoToDesktopNumberProc
    WinGet, activeHwnd, ID, A
    DllCall(MoveWindowToDesktopNumberProc, "Ptr", activeHwnd, "Int", desktopNumber, "Int")
    DllCall(GoToDesktopNumberProc, "Int", desktopNumber)
}

GoToDesktopNumber(num) {
    global GoToDesktopNumberProc
    DllCall(GoToDesktopNumberProc, "Int", num, "Int")
    return
}

!1:: GoToDesktopNumber(0)
!2:: GoToDesktopNumber(1)
!3:: GoToDesktopNumber(2)
!4:: GoToDesktopNumber(3)
!5:: GoToDesktopNumber(4)
!6:: GoToDesktopNumber(5)
!7:: GoToDesktopNumber(6)
!8:: GoToDesktopNumber(7)
!9:: GoToDesktopNumber(8)
!0:: GoToDesktopNumber(9)

!+1:: MoveCurrentWindowToDesktop(0)
!+2:: MoveCurrentWindowToDesktop(1)
!+3:: MoveCurrentWindowToDesktop(2)
!+4:: MoveCurrentWindowToDesktop(3)
!+5:: MoveCurrentWindowToDesktop(4)
!+6:: MoveCurrentWindowToDesktop(5)
!+7:: MoveCurrentWindowToDesktop(6)
!+8:: MoveCurrentWindowToDesktop(7)
!+9:: MoveCurrentWindowToDesktop(8)
!+0:: MoveCurrentWindowToDesktop(9)
