;AHK script for wow
;Authored by llxibo
#NoEnv
#SingleInstance, Force
#Persistent
DetectHiddenWindows, On
CoordMode,ToolTip,Screen

;Init app info and default settings
SetGlobal() {
	global
	WoWTitle:={"魔兽世界":"WoW-CN", "World of Warcraft":"WoW-EU", "魔獸世界":"WoW-TW"}
	AppTitle:="WoW AHK Helper"
	Author:="llxibo"
	DefaultHotKey:="{f9}"
	DefaultInterval:=5000
	w_Enabled:=0
	w_HideAll:=0
}

SetGlobal()
Menu,Tray,Tip,%AppTitle% powered by %Author%
DetectWoW()
Return

;Function to show a tooltip in right bottom of screen for 2 seconds
TooltipAuto(text,autoFade) {
	StringSplit t_TooltipLines,text,`n
	t_MaxLen:=0
	Loop %t_TooltipLines0%
		t_MaxLen:=t_MaxLen<StrLen(t_TooltipLines%A_Index%) ? StrLen(t_TooltipLines%A_Index%) : t_MaxLen
	Tooltip,%text%,A_ScreenWidth-6*t_MaxLen-7,A_ScreenHeight-15*t_TooltipLines0+3
	if (autoFade=1)
		SetTimer,w_HideTooltip,-2000
}

;Check key state of modifiers, and send key with ControlSend or Send
SendKeyAuto(label) {
	global WinInfo
	t_CurrentIndex:=SubStr(label,8)
	this:=WinInfo[t_CurrentIndex]
	If (this.modCheck=3) {
		KeyWait Shift
		KeyWait Control
		KeyWait Alt
	}
	SetKeyDelay,,50
	If (not this.modCheck=2 or not (GetKeyState("Shift") or GetKeyState("Control") or GetKeyState("Alt"))) {
		If (this.isNotControlSend=0) {
			ControlSend ,,% this.hotkey,% this.ahkid
		} Else {
			IfWinActive % this.ahkid
				Send % this.hotkey
		}
	}
}

IsWoWWindow(winID) {
	WinGetClass,t_WindowClass,% "ahk_id" . winID
	return t_WindowClass="GxWindowClass"
}

SetDefault(obj) {
	global
	obj.init:=1
	obj.enabled:=obj.index=1 ? 1 : 0
	obj.interval:=DefaultInterval
	obj.hotkey:=DefaultHotKey
	obj.isNotControlSend:=0
	obj.modCheck:=3
	obj.hidden:=0
}

;Detect for WoW windows and push ahk_id into array
DetectWoW() {
	global WoWTitle
	global WindowsID:=0
	global WinInfo:=Array()
	for rawtitle,alias in WoWTitle {
		Winget,t_WindowsID,list,%rawtitle%
		Loop %t_WindowsID%	;Change raw title to alias
			if IsWoWWindow(t_WindowsID%A_Index%)
				WinSetTitle,% "ahk_id" . t_WindowsID%A_Index%, , %alias%
		
		Winget,t_WindowsID,list,%alias%
		Loop %t_WindowsID% {
			if IsWoWWindow(t_WindowsID%A_Index%) {
				WindowsID:=WindowsID+1
				this:={}
				this.index:=1
				this.id:=t_WindowsID%A_Index%
				this.ahkid:="ahk_id" . this.id
				this.title:=alias . "-" . A_Index . "#"
				if (this.init!=1)
					SetDefault(this)
				WinInfo.Insert(this)
				WindowsID%WindowsID%:=t_WindowsID%A_Index%	
				w_WinTitle%WindowsID%=%t_AliasTitle%-%A_Index%#
				WinSetTitle,% "ahk_id" . t_WindowsID%A_Index%, ,% this.title
				WinShow % "ahk_id" . t_WindowsID%A_Index%
			}
		}
	}
	TooltipAuto("检测到" . WindowsID . "客户端",1)
}

UpdateTimer() {
	global WinInfo
	global w_Enabled
	t_Count:=0
	t_TooltipText:=""
	for index,value in WinInfo {
		; MsgBox % w_Enabled . " " . value.hidden
		if IsLabel("w_Timer" . index)
			if (value.enabled=1 and w_Enabled=1) {
				SetTimer w_Timer%index%, % value.interval
				t_Count:=t_Count+1
				t_TooltipText:=t_TooltipText . "`n" . value.title . ": " . Round(value.interval/1000,2) . "秒"
			} else {
				SetTimer w_Timer%index%, Off
			}
	}
	return (t_Count=0 ? "已暂停全部定时器" : ("已启用" . t_Count . "个定时器:" . t_TooltipText))
}

UpdateHide() {
	global WinInfo
	global w_HideAll
	t_Count:=0
	t_TooltipText:=""
	for index,value in WinInfo {
		if (w_HideAll=1 and value.hidden) {
			WinHide % value.ahkid
			t_TooltipText:=t_TooltipText . "`n" . value.title
			t_Count:=t_Count+1
		} else {
			WinShow % value.ahkid
		}
	}
	return (t_Count=0 ? "已显示所有窗口" : ("已隐藏" . t_Count . "个窗口:" . t_TooltipText))
}

; F12 to enable/disable auto key sending
f12::
	w_Enabled:=!w_Enabled
	TooltipAuto(UpdateTimer(),1)
Return

; Alt-F12 to detect WoW windows
!f12::
	w_Enabled:=0
	w_HideAll:=0
	UpdateTimer()
	DetectWoW()
Return

; Ctrl-Alt-F12 to hide wow clients
!^f12::
	w_HideAll:=!w_HideAll
	TooltipAuto(UpdateHide(),1)
Return

; Ctrl-Alt-Shift-F12 to force reload script
!^+f12::
	Reload
Return

; Ctrl-F12 to open config dialog
^f12::
	If not (w_GuiBuilt=1) {
		Gui Add,Text,xm+20 y10 w100 Section Center,启用
		Gui Add,Text,ys w120 hp Center,按键
		Gui Add,Text,ys w120 hp Center,间隔
		Gui Add,Text,ys w70 hp Center,前台模式
		Gui Add,Text,ys w90 hp Center,Mod检查
		Gui Add,Text,ys w60 hp Center
		; Gui Add,Text,ys w60 hp Center
		
		Gui Add,DropDownList,yp-5 Hidden	;Invisible dropdownlist to get height
		
		for index,value in WinInfo {
			Gui Add,CheckBox,xm+20 w100 hp Section vc_Enabled%index%,% value.title
			GuiControl,,c_Enabled%index%,% value.enabled
			
			Gui Add,Edit,ys w120 hp vc_Hotkey%index%,% value.hotkey
			
			Gui Add,Edit,ys w120 hp vc_Interval%index%,% value.interval
			
			Gui Add,CheckBox,ys w70 hp -Tabstop vc_IsNotControlSend%index%,前台
			GuiControl,,c_IsNotControlSend%index%,% value.isNotControlSend
			
			Gui Add,DropDownList,ys w90 -Tabstop AltSubmit vc_ModCheck%index%,禁用|检测|等待
			GuiControl,Choose,c_ModCheck%index%,% value.modCheck
			
			Gui Add,CheckBox,ys w60 hp -Tabstop vc_IsHidden%index%,隐藏
			GuiControl,,c_IsHidden%index%,% value.hidden
			
			; Gui Add,Radio,ys w60 hp -Tabstop,VMKD
		}
		If (WinInfo.MaxIndex()=0) {
			GuiControl,Disable,c_Hotkey1
			GuiControl,Disable,c_Interval1
			GuiControl,Disable,c_Enabled1
		}
		Gui Add,Button,xp-80 y+10 w80 Default gc_ButtonOK,OK
		Gui Add,Button,x+10 w80 gc_ButtonCancel,Cancel
		w_GuiBuilt:=1
	}
	Gui Show,,%AppTitle%
Return

c_ButtonOK:
	Gui Submit
	for index,value in WinInfo {
		value.enabled:=c_Enabled%index%
		value.hotkey:=c_Hotkey%index%
		value.interval:=c_Interval%index%
		value.isNotControlSend:=c_IsNotControlSend%index%
		value.modCheck:=c_ModCheck%index%
		value.hidden:=c_IsHidden%index%
	}
	TooltipAuto(UpdateTimer(),1)
	UpdateHide()
	Gui Destroy
	w_GuiBuilt:=0
Return
c_ButtonCancel:
	Gui Cancel
	Gui Destroy
	w_GuiBuilt:=0
Return

w_HideTooltip:
	ToolTip
Return

w_Timer1:
	SendKeyAuto(A_ThisLabel)
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
w_Timer7:
	SendKeyAuto(A_ThisLabel)
Return
w_Timer8:
	SendKeyAuto(A_ThisLabel)
Return
w_Timer9:
	SendKeyAuto(A_ThisLabel)
Return
w_Timer10:
	SendKeyAuto(A_ThisLabel)
Return

; VMKDRecognize() {
	; global WinInfo
	; for index,value in WinInfo {
		; WinGetTitle,t_Title,% value.ahkid
		; if (t_Title=value.title) {
			; WinGetPos,t_X,t_Y,,,% value.ahkid
			; Loop % value.MaxIndex() {
				; local index:=A_Index
			; }
		; }
	; }
; }

