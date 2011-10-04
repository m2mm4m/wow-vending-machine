; AHK script for wow
; Authored by llxibo
#NoEnv
#SingleInstance, Force
#Persistent
DetectHiddenWindows, On
CoordMode,ToolTip,Screen
CoordMode, Mouse,Screen
CoordMode,Pixel,Screen

; Init app info and default settings
SetGlobal() {
	global
	
	; global information
	AppTitle:="WoW AHK Helper"
	Author:="llxibo"
	
	; WoW windows information and default keypressing config
	WoWTitle:={"魔兽世界":"WoW-CN", "World of Warcraft":"WoW-EU", "魔獸世界":"WoW-TW"}
	DefaultHotKey:="{f9}"
	DefaultInterval:=5000
	
	; Hotkey config
	Hotkeys:=[	 {key:"f12",	label:"ToggleTimer",	keyStr:"F12",		desc:"Toggle Timer"			}
				,{key:"!f12",	label:"DetectWindows",	keyStr:"a-F12",		desc:"Scan for Clients"		}
				,{key:"^f12",	label:"OpenConfig",		keyStr:"c-F12",		desc:"Open Config"			}
				,{key:"!^f12",	label:"ToggleHide",		keyStr:"c-a-F12",	desc:"Hide/Show Clients"	}
				,{key:"!^+f12",	label:"ReloadScript",	keyStr:"c-a-s-F12",	desc:"Reload Script"		}	]
	; Initialize global strings
	w_Enabled:=0
	w_HideAll:=0
	WinInfo:=Array()
	
	; VMKD Configuration
	VMKD_MaxOffset:=30
}

SetGlobal()
SetHotkeys()
Menu,Tray,Tip,%AppTitle% powered by %Author%
DetectWoW()
Return

; Function to show a tooltip in right bottom of screen for 2 seconds
TooltipAuto(text,autoFade) {
	StringSplit t_TooltipLines,text,`n
	t_MaxLen:=0
	Loop %t_TooltipLines0%
		t_MaxLen:=t_MaxLen<StrLen(t_TooltipLines%A_Index%) ? StrLen(t_TooltipLines%A_Index%) : t_MaxLen
	Tooltip,%text%,A_ScreenWidth-6*t_MaxLen-7,A_ScreenHeight-15*t_TooltipLines0+3
	if (autoFade=1)
		SetTimer,w_HideTooltip,-2000
}

; Register all hotkeys in table Hotkeys
SetHotkeys() {
	global Hotkeys
	Menu,Tray,Add
	for index,hotkeyObj in Hotkeys {
		Hotkey % hotkeyObj.key,% hotkeyObj.label
		Menu,Tray,Add,% hotkeyObj.desc,% hotkeyObj.label
	}
}

; Check key state of modifiers, and send key with ControlSend or Send
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

; Check if a window is WoW client
IsWoWWindow(winID) {
	WinGetClass,t_WindowClass,% "ahk_id" . winID
	return t_WindowClass="GxWindowClass"
}

; Set default settings for a WinInfo object. Will not reset the object if it's alrealy initialized
SetDefault(obj) {
	global
	if (obj.init=1)
		return obj
	obj.init:=1
	obj.enabled:=0
	obj.interval:=DefaultInterval
	obj.hotkey:=DefaultHotKey
	obj.isNotControlSend:=0
	obj.modCheck:=3
	obj.hidden:=0
	return obj
}

; Get window object by an winID, return an empty table if not found
GetWindowByID(winID) {
	global WinInfo
	for index,obj in WinInfo {
		if (obj.id=winID) {
			; MsgBox % obj.id
			return obj
		}
	}
	return {}
}

; Detect for WoW windows and push ahk_id into array
DetectWoW() {
	global WoWTitle
	global WinInfo
	global NumWindows:=0
	totalEnabled:=0
	t_WinInfo:=Array()
	for rawtitle,alias in WoWTitle {
		Winget,t_WindowsID,list,%rawtitle%
		Loop %t_WindowsID%	; Change raw title to alias
			if IsWoWWindow(t_WindowsID%A_Index%)
				WinSetTitle,% "ahk_id" . t_WindowsID%A_Index%, , %alias%
		
		Winget,t_WindowsID,list,%alias%
		Loop %t_WindowsID% {
			if IsWoWWindow(t_WindowsID%A_Index%) {
				NumWindows:=NumWindows+1
				this:=GetWindowByID(t_WindowsID%A_Index%)
				this.index:=NumWindows
				this.id:=t_WindowsID%A_Index%
				this.ahkid:="ahk_id" . this.id
				; MsgBox % this.ahkid
				this.title:=alias . "-" . A_Index . "#"
				SetDefault(this)
				t_WinInfo.Insert(this)
				if (this.enabled)
					totalEnabled:=totalEnabled+1
				w_WinTitle%NumWindows%=%t_AliasTitle%-%A_Index%#
				WinSetTitle,% "ahk_id" . t_WindowsID%A_Index%, ,% this.title
				WinShow % "ahk_id" . t_WindowsID%A_Index%
			}
		}
	}
	WinInfo:=t_WinInfo
	if (totalEnabled=0 and IsObject(WinInfo[1]))
		WinInfo[1].enabled:=1
	TooltipAuto("检测到" . NumWindows . "客户端",1)
}

; Update all timers with current timer settings
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

; Hide/show windows according to current settings
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

; Build a line of GUI controls for a WinInfo object
BuildGUILine(index,obj,state) {
	global
	Gui Add,CheckBox,xm+20 w100 hp Section vc_Enabled%index%,% obj.title
	GuiControl,,c_Enabled%index%,% obj.enabled
	GuiControl,%state%,c_Enabled%index%
	
	Gui Add,Edit,ys w120 hp vc_Hotkey%index%,% obj.hotkey
	GuiControl,%state%,c_Hotkey%index%
	
	Gui Add,Edit,ys w120 hp vc_Interval%index%,% obj.interval
	GuiControl,%state%,c_Interval%index%
	
	Gui Add,CheckBox,ys w70 hp -Tabstop vc_IsNotControlSend%index%,前台
	GuiControl,,c_IsNotControlSend%index%,% obj.isNotControlSend
	GuiControl,%state%,c_IsNotControlSend%index%
	
	Gui Add,DropDownList,ys w90 -Tabstop AltSubmit vc_ModCheck%index%,禁用|检测|等待
	GuiControl,Choose,c_ModCheck%index%,% obj.modCheck
	GuiControl,%state%,c_ModCheck%index%
	
	Gui Add,CheckBox,ys w60 hp -Tabstop vc_IsHidden%index%,隐藏
	GuiControl,,c_IsHidden%index%,% obj.hidden
	GuiControl,%state%,c_IsHidden%index%
	
	; Gui Add,Radio,ys w60 hp -Tabstop,VMKD
}

; Enable/disable auto key sending
ToggleTimer:
	w_Enabled:=!w_Enabled
	TooltipAuto(UpdateTimer(),1)
Return

; Detect WoW windows
DetectWindows:
	w_Enabled:=0
	w_HideAll:=0
	UpdateTimer()
	DetectWoW()
Return

; Hide WoW clients
ToggleHide:
	w_HideAll:=!w_HideAll
	TooltipAuto(UpdateHide(),1)
Return

; Force reload this script
ReloadScript:
	Reload
Return

; Open config dialog
OpenConfig:
	If not (w_GuiBuilt=1) {
		Gui Add,Text,xm+20 y10 w100 Section Center,启用
		Gui Add,Text,ys w120 hp Center,按键
		Gui Add,Text,ys w120 hp Center,间隔
		Gui Add,Text,ys w70 hp Center,前台模式
		Gui Add,Text,ys w90 hp Center,Mod检查
		Gui Add,Text,ys w60 hp Center
		Gui Add,DropDownList,yp-5 Hidden	; Invisible dropdownlist to get height
		
		for index,obj in WinInfo {
			BuildGUILine(index,obj,"Enable")
		}
		If (not IsObject(WinInfo[1])) {
			t_obj:=SetDefault({})
			t_obj.title:="WoW-##-##"
			BuildGUILine(1,t_obj,"Disable")
		}
		Gui Add,Button,xp-80 y+10 w80 Default gc_ButtonOK,OK
		Gui Add,Button,x+10 w80 gc_ButtonCancel,Cancel
		w_GuiBuilt:=1
	}
	Gui Show,,%AppTitle%
Return

; GUI callback label for OK button
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

; GUI callback label for Cancel button
c_ButtonCancel:
	Gui Cancel
	Gui Destroy
	w_GuiBuilt:=0
Return

w_HideTooltip:
	ToolTip
Return

; Preset timer labels
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

; PixelGetColor(x,y) {
	; PixelGetColor t_PixelGetColor, %x%, %y%
	; obj:={}
	; obj.r:=t_PixelGetColor & 0x0000FF
	; obj.g:=round((t_PixelGetColor & 0x00FF00)/0x100)
	; obj.b:=round((t_PixelGetColor & 0xFF0000)/0x10000)
	; return obj
; }

; FindVMKDLabel(obj,x,y) {
	
	; return 0
; }

; VMKDRecognizeWindow(obj) {
	; global VMKD_MaxOffset
	; WinGetPos,t_X,t_Y,,,% obj.ahkid
	; obj.x:=t_X
	; obj.y:=t_Y
	
	; Loop % VMKD_MaxOffset+1 {
		; curPos:=A_Index-1
		; if FindVMKDLabel(obj,obj.x+curPos,obj.y+curPos)
			; return 1
		; Loop %curPos% {
			; if FindVMKDLabel(obj,obj.x+curPos-A_Index,obj.y+curPos)
				; return 1
			; if FindVMKDLabel(obj,obj.x+curPos,obj.y+curPos-A_Index)
				; return 1
		; }
	; }
	; return 0
; }

; VMKDRecognize() {
	; global WinInfo
	; for index,value in WinInfo {
		; WinGetTitle,t_Title,% value.ahkid
		; if (t_Title=value.title) {
			; VMKDRecognizeWindow(value)
		; }
	; }
; }

