;AHK script for wow
;Authored by llxibo
#NoEnv
#SingleInstance, Force
#Persistent
DetectHiddenWindows, On
CoordMode,ToolTip,Screen
CoordMode, Mouse,Screen
CoordMode,Pixel,Screen
;Init app info and default settings

AppTitle:="WoW AHK Helper"
Author:="llxibo"

; Menu,Tray,Tip,%AppTitle% powered by %Author%

w_Enabled:=0
w_wait:=0
prevColor:=0x000000

status_none:=0

status_keypress_preset:=11

status_keypress_asc:=21
status_keydown_asc:=22
status_keyup_asc:=23

status_keypress_vk:=31
status_keydown_vk:=32
status_keyup_vk:=33

status_mouseclick:=51
status_mousemove:=52
status_mousesetpreset:=53
status_mousemove_left:=56
status_mousemove_right:=57
status_mousemove_up:=58
status_mousemove_down:=59

mouseclick_preset1x:=1470
mouseclick_preset1y:=450
; mouseclick_preset1x:=970
; mouseclick_preset1y:=413

Return

;Function to show a tooltip in right bottom of screen for 2 seconds
TooltipAuto(text,autoFade) {
	StringSplit t_TooltipLines,text,`n
	t_MaxLen:=0
	Loop %t_TooltipLines0%
		t_MaxLen:=t_MaxLen<StrLen(t_TooltipLines%A_Index%) ? StrLen(t_TooltipLines%A_Index%) : t_MaxLen
	Tooltip,%text%,A_ScreenWidth-6*t_MaxLen-7,A_ScreenHeight-15*t_TooltipLines0+3
	if (autoFade==1)
		SetTimer,w_HideTooltip,-2000
}

f10::
	w_Enabled:=1
	WindowsID:="WoW-CN-1#"
	WinGetPos , w_Window_X, w_Window_Y,,, %WindowsID%
	w_idletickcount:=A_TickCount
	Loop {
		KeyWait Shift
		KeyWait Control
		KeyWait Alt

		PixelGetColor, VM_Color, % w_Window_X+1, % w_Window_Y+1
		status:=VM_Color & 0x0000FF
		VMC1:=round((VM_Color & 0x00FF00)/0x100)
		VMC2:=round((VM_Color & 0xFF0000)/0x10000)
		VMC1H:=SubStr(VM_Color,5,2)
		VMC2H:=SubStr(VM_Color,3,2)
		
		MouseGetPos, VM_PosX, VM_PosY
		TooltipAuto("@" . w_Window_X . "," . w_Window_Y . ":" . VM_Color . ": " . status . ", " . VMC1H . ", " . VMC2 . " Mouse(" . VM_PosX . "." .  VM_PosY . ")",1)
		if (w_wait=0 or VM_Color<>prevColor) {
			prevColor:=VM_Color
			SetKeyDelay,,-1
			w_wait:=0
			w_idle:=0
			if (status=status_keypress_preset) {
			
			} else if (status=status_keypress_asc) {
				if (VMC2>0) {
					SetKeyDelay,,%VMC2%*20
					w_wait:=1
				}
				ControlSend,,{asc %VMC1%},%WindowsID%	
			} else if (status=status_keydown_asc) {
			} else if (status=status_keyup_asc) {
			} else if (status=status_keypress_vk) {
				if (VMC2>0) {
					SetKeyDelay,,% VMC2*20
					w_wait:=1
				}
				ControlSend,,{vk%VMC1H%},%WindowsID%
			} else if (status=status_keydown_vk) {
				ControlSend,,{vk%VMC1H% Down},%WindowsID%
				w_wait:=1
			} else if (status=status_keyup_vk) {
				ControlSend,,{vk%VMC1H% Up},%WindowsID%
				w_wait:=1
			} else if (status=status_mouseclick) {
				; w_mousestopped:=1
				; Loop {
					; MouseGetPos, t_StartX,t_StartY
					; Loop 100 {
						; Sleep 0
						; MouseGetPos, t_PosX, t_PosY
						; if (t_PosX<>t_StartX or t_PosY<>t_StartY) {
							; w_mousestopped:=0
							; break
						; }
					; }
				; } Until w_mousestopped=1
				MouseGetPos, t_StartX,t_StartY
				MouseMove,% w_Window_X+mouseclick_preset%VMC1%x,% w_Window_Y+mouseclick_preset%VMC1%y,0
				ControlSend,,{vkBA},%WindowsID%
				MouseMove,t_StartX,t_StartY,0
				; SetControlDelay -1
				; ControlClick,% "X" . mouseclick_preset%VMC1%x . " Y" . mouseclick_preset%VMC1%y,%WindowsID%,,RIGHT,,NA Pos
			} else if (status=status_mousemove) {
			} else if (status=status_mousesetpreset) {
			} else if (status=status_mousemove_left) {
			} else if (status=status_mousemove_right) {
			} else if (status=status_mousemove_up) {
			} else if (status=status_mousemove_down) {
			} else {
				w_idle:=1
			}
			if (w_idle=0)
				w_idletickcount:=A_TickCount
			else if (A_TickCount-w_idletickcount>5000) {
				TooltipAuto("Sleeping",1)
				Sleep 1000
			}
		}
		Sleep 0
	} Until w_Enabled=0
	TooltipAuto("VMKD Stopped",1)
Return

f11::
	w_Enabled:=0
Return

!^+f11::
	Reload
Return

w_HideTooltip:
	ToolTip
Return
