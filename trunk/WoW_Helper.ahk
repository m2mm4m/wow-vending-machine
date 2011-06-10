;AHK script for wow
;Authored by llxibo
#NoEnv
#SingleInstance, Force
#Persistent
DetectHiddenWindows, On
CoordMode,ToolTip,Screen
;Init app info and default settings

AppTitle:="WoW AHK Helper"
Author:="llxibo"

WoWTitle:=3
WoWTitle1:="魔兽世界"
WoWTitleAlias1:="WoW-CN"
WoWTitle2:="World of Warcraft"
WoWTitleAlias2:="WoW-EU"
WoWTitle3:="魔獸世界"
WoWTitleAlias3:="WoW-TW"
WoWTitle4:="千寻"
WoWTitleAlias4:="千寻"

DefaultHotKey:="{f9}"
DefaultInterval:=5000
Menu,Tray,Tip,%AppTitle% powered by %Author%

w_Enabled:=0
w_HideAll:=0
Gosub DetectWoW
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

;Check key state of modifiers, and send key with ControlSend or Send
SendKeyAuto(label) {
	t_CurrentIndex:=SubStr(label,8)
	If (w_ModCheck%t_CurrentIndex%=3) {
		KeyWait Shift
		KeyWait Control
		KeyWait Alt
	}
	SetKeyDelay,,50
	If (not w_ModCheck%t_CurrentIndex%=2 or not (GetKeyState("Shift") or GetKeyState("Control") or GetKeyState("Alt"))) {
		If (w_IsNotControlSend%t_CurrentIndex%=0) {
			ControlSend ,,% w_Hotkey%t_CurrentIndex%,% "ahk_id" . WindowsID%t_CurrentIndex%
		} Else {
			IfWinActive % "ahk_id" . WindowsID%t_CurrentIndex%
				Send % w_Hotkey%t_CurrentIndex%
		}
	}
}
Return

;Detect for WoW windows and push ahk_id into array
DetectWoW:
	WindowsID:=0
	Loop %WoWTitle% {
		t_AliasTitle:=WoWTitleAlias%A_Index%
		
		Winget,t_WindowsID,list,% WoWTitle%A_Index%
		Loop %t_WindowsID%	;Change raw title to alias
			WinSetTitle,% "ahk_id" . t_WindowsID%A_Index%, , %t_AliasTitle%
			
		Winget,t_WindowsID,list,%t_AliasTitle%
		Loop %t_WindowsID% {
			WinGetClass,t_WindowClass,% "ahk_id" . t_WindowsID%A_Index%
			if SubStr(t_WindowClass,1,13)="GxWindowClass" {
				WindowsID:=WindowsID+1
				WindowsID%WindowsID%:=t_WindowsID%A_Index%
				w_WinTitle%WindowsID%=%t_AliasTitle%-%A_Index%#
				WinSetTitle,% "ahk_id" . t_WindowsID%A_Index%, , % w_WinTitle%WindowsID%
				WinShow % "ahk_id" . t_WindowsID%A_Index%
			}
		}
	}
	;Init settings for each window if not initiallized
	Loop % WindowsID>0 ? WindowsID : 1 {
		if not (w_Init%A_Index%=1) {
			w_Init%A_Index%:=1
			w_Enabled%A_Index%:=A_Index=1 ? 1 : 0
			w_Interval%A_Index%:=DefaultInterval
			w_Hotkey%A_Index%:=DefaultHotKey
			w_IsNotControlSend%A_Index%:=0
			w_ModCheck%A_Index%:=3
		}
		w_IsHidden%A_Index%:=0
	}
	TooltipAuto("检测到" . WindowsID . "客户端",1)
Return

UpdateTimer:
	t_Count:=0
	t_TooltipText:=""
	Loop %WindowsID% {
		If IsLabel("w_Timer" . A_Index)
			If (w_Enabled%A_Index%=1 and w_Enabled=1) {
				SetTimer w_Timer%A_Index%, % w_Interval%A_Index%
				t_Count:=t_Count+1
				t_TooltipText:=t_TooltipText . "`n" . w_WinTitle%A_Index% . ": " . Round(w_Interval%A_Index%/1000,2) . "秒"
			} Else {
				SetTimer w_Timer%A_Index%,Off
			}
	}
	TooltipAuto(t_Count=0 ? "已暂停全部定时器" : ("已启用" . t_Count . "个定时器:" . t_TooltipText),1)
Return

UpdateHide:
	t_Count:=0
	t_TooltipText:=""
	Loop %WindowsID% {
		if (w_HideAll=1 and w_IsHidden%A_Index%=1) {
			WinHide % "ahk_id" . WindowsID%A_Index%
			t_TooltipText:=t_TooltipText . "`n" . w_WinTitle%A_Index%
			t_Count:=t_Count+1
		} else {
			WinShow % "ahk_id" . WindowsID%A_Index%
		}
		TooltipAuto(t_Count=0 ? "已显示所有窗口" : ("已隐藏" . t_Count . "个窗口:" . t_TooltipText),1)
	}
Return

f12::
	w_Enabled:=!w_Enabled
	Gosub UpdateTimer
Return

!f12::
	w_Enabled:=0
	w_HideAll:=0
	Gosub UpdateTimer
	Gosub DetectWoW
Return

!^f12::
	w_HideAll:=!w_HideAll
	Gosub UpdateHide
Return

!^+f12::
	Reload
Return

w_HideTooltip:
	ToolTip
Return

;Ctrl-F12 to open config dialog
^f12::
	If not (w_GuiBuilt=1) {
		If WindowsID>0
			ControlID:=WindowsID
		Else
			ControlID:=1
		
		Gui Add,Text,xm+20 y10 w100 Section Center,启用
		Gui Add,Text,ys w120 hp Center,按键
		Gui Add,Text,ys w120 hp Center,间隔
		Gui Add,Text,ys w70 hp Center,前台模式
		Gui Add,Text,ys w90 hp Center,Mod检查
		Gui Add,Text,ys w60 hp Center
		Gui Add,Text,ys w60 hp Center
		
		Gui Add,DropDownList,yp-5 Hidden	;Invisible dropdownlist to get height
		
		Loop %ControlID% {
			Gui Add,CheckBox,xm+20 w100 hp Section vw_Enabled%A_Index%,% w_WinTitle%A_Index%
			GuiControl,,w_Enabled%A_Index%,% w_Enabled%A_Index%
			
			Gui Add,Edit,ys w120 hp vw_Hotkey%A_Index%,% w_HotKey%A_Index%
			
			Gui Add,Edit,ys w120 hp vw_Interval%A_Index%,% w_Interval%A_Index%
			
			Gui Add,CheckBox,ys w70 hp -Tabstop vw_IsNotControlSend%A_Index%,前台
			GuiControl,,w_IsNotControlSend%A_Index%,% w_IsNotControlSend%A_Index%
			
			Gui Add,DropDownList,ys w90 -Tabstop AltSubmit vw_ModCheck%A_Index%,禁用|检测|等待
			GuiControl,Choose,w_ModCheck%A_Index%,% w_ModCheck%A_Index%
			
			Gui Add,CheckBox,ys w60 hp -Tabstop vw_IsHidden%A_Index%,隐藏
			GuiControl,,w_IsHidden%A_Index%,% w_IsHidden%A_Index%
			
			Gui Add,Radio,ys w60 hp -Tabstop,VMKD
		}
		If (WindowsID<=0) {
			GuiControl,Disable,w_Hotkey1
			GuiControl,Disable,w_Interval1
			GuiControl,Disable,w_Enabled1
		}
		Gui Add,Button,xp-80 y+10 w80 Default gw_ButtonOK,OK
		Gui Add,Button,x+10 w80 gw_ButtonCancel,Cancel
		;GuiControl,Focus,w_HotKey1
		w_GuiBuilt:=1
	}
	Gui Show,,%AppTitle%
Return

w_ButtonOK:
	Gui Submit
	Gosub UpdateTimer
	Gosub UpdateHide
	Gui Destroy
	w_GuiBuilt:=0
Return
w_ButtonCancel:
	Gui Cancel
	Gui Destroy
	w_GuiBuilt:=0
Return

w_Timer1:
	SendKeyAuto(A_ThisLabel)
	; PixelGetColor, QAH_color, 1, 1
	; QAH1:=QAH_color & 0x0000FF
	; QAH2:=(QAH_color & 0x00FF00)/0x100
	; QAH3:=(QAH_color & 0xFF0000)/0x10000
	; TooltipAuto(QAH1 . "," . QAH2 . "," . QAH3,1)
Return
w_Timer2:
	SendKeyAuto(A_ThisLabel)
Return
w_Timer3:
	SendKeyAuto(A_ThisLabel)
Return
w_Timer4:
	SendKeyAuto(A_ThisLabel)
Return
w_Timer5:
	SendKeyAuto(A_ThisLabel)
Return
w_Timer6:
	SendKeyAuto(A_ThisLabel)
Return

;----------------QAH driver--------------
^!x::
{
	QAH_Enabled:=!QAH_Enabled
	If (QAH_Enabled=0) {
		SetTimer QAH_ScanFlag,Off
		TooltipAuto("QAH: Paused",1)
	}
	Else {
		MouseGetPos, QAH_MouseX, QAH_MouseY
		SetTimer QAH_ScanFlag,1000
		TooltipAuto("QAH: Scanning",0)
	}
}
Return

QAH_ScanFlag:
IfWinActive ahk_id%WindowsID1%
{
	PixelGetColor, QAH_color, 1, 1
	QAH_mailcursor:=QAH_color & 0x0000FF
	QAH_openauction:=(QAH_color & 0x00FF00)/0x100
	QAH_openmail:=(QAH_color & 0xFF0000)/0x10000
	If (QAH_mailcursor>127) {
		QAH_mailcursor:=1
	} Else {
		QAH_mailcursor:=0
	}
	If (QAH_openauction>127) {
		ControlSend ,,{f9}{f10},ahk_id%WindowsID1%
	}
	If (QAH_openmail>127) {
		MouseClick Right,%QAH_MouseX%,%QAH_MouseY%
	}
	;Tooltip,%QAH_mailcursor%..%QAH_openauction%..%QAH_openmail%
	;ControlSend ,,{f9},ahk_id%WindowsID1%
	TooltipAuto("QAH: Scanning",0)
}
Else {
	TooltipAuto("QAH: Not Active",0)
}
Return
