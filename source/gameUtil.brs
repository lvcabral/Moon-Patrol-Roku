' ********************************************************************************************************
' ********************************************************************************************************
' **  Roku Moon Patrol Channel - http://github.com/lvcabral/Moon-Patrol-Roku
' **
' **  Created: February 2017
' **  Updated: February 2017
' **
' **  Remake in BrigthScript developed by Marcelo Lv Cabral - http://lvcabral.com
' ********************************************************************************************************
' ********************************************************************************************************
Function GetConstants() as object
    const = {}

    const.GAME_SPEED  = 40 '25 fps

    const.MODE_ARCADE = 0
    const.MODE_ATARI  = 1

    const.MOON_MOUNTAIN = 0
    const.MOON_CITY     = 1

    const.BACK_MOUNTAIN_Y  = 208
    const.FRONT_MOUNTAIN_Y = 280
    const.FRONT_CITY_Y     = 276
    const.GROUND_LEVEL_Y   = 320

    const.PANEL_WIDTH      = 640
    const.PANEL_HEIGHT     = 160

    const.MENU_START    = 0
    const.MENU_CONTROL  = 1
    const.MENU_SPRITES  = 2
    const.MENU_HISCORES = 3
    const.MENU_CREDITS  = 4

    const.CONTROL_VERTICAL   = 0
    const.CONTROL_HORIZONTAL = 1

    const.LAYER0_Z = 20
    const.LAYER1_Z = 21
    const.LAYER2_Z = 22
    const.BUGGY_Z  = 30
    const.ENEMY_Z  = 40

    return const
End Function

Function GetRegion(image as string, wrap = false as boolean) as object
    bmp = CreateObject("roBitmap", image)
    rgn = CreateObject("roRegion", bmp, 0, 0, bmp.GetWidth(), bmp.GetHeight())
    rgn.SetWrap(wrap)
    return rgn
End Function

'------- Registry Functions -------
Function GetRegistryString(key as String, default = "") As String
    sec = CreateObject("roRegistrySection", "MoonPatrol")
    if sec.Exists(key)
        return sec.Read(key)
    end if
    return default
End Function

Sub SaveRegistryString(key as string, value as string)
    sec = CreateObject("roRegistrySection", "MoonPatrol")
    sec.Write(key, value)
    sec.Flush()
End Sub

Sub SaveSettings(settings as object)
    SaveRegistryString("Settings", FormatJSON({settings: settings}, 1))
End Sub

Function LoadSettings() as dynamic
    settings = invalid
    json = GetRegistryString("Settings")
    if json <> ""
        obj = ParseJSON(json)
        if obj <> invalid
            settings = obj.settings
        end if
    end if
    if settings = invalid then settings = {}
    if settings.controlMode = invalid then settings.controlMode = m.const.CONTROL_VERTICAL
    if settings.spriteMode = invalid then settings.spriteMode = m.const.MODE_ARCADE
    if settings.highScores = invalid then settings.highScores = [ {score: 0, name: ""} ]
    return settings
End Function
'------- Numeric and String Functions -------

Function itostr(i as integer) as string
    str = Stri(i)
    return strTrim(str)
End Function

Function strTrim(str as String) as string
    st = CreateObject("roString")
    st.SetString(str)
    return st.Trim()
End Function

Function zeroPad(number as integer, length = invalid) as string
    text = itostr(number)
    if length = invalid then length = 2
    if text.Len() < length
        for i = 1 to length-text.Len()
            text = "0" + text
        next
    end if
    return text
End Function

Function padCenter(text as string, size as integer) as string
    if Len(text) > size then text.Left(text, size)
    if Len(text) < size
        left = ""
        right = ""
        for c = 1 to size - Len(text)
            if c mod 2 = 0
                left += " "
            else
                right += " "
            end if
        next
        text = left + text + right
    end if
    return text
End Function

Function padLeft(text as string, size as integer) as string
    if Len(text) > size then text.Left(text, size)
    if Len(text) < size
        for c = 1 to size - Len(text)
            text += " "
        next
    end if
    return text
End Function

Function IsOdd(number) as boolean
    return (number mod 2 <> 0)
End Function

Function CenterText(text as string, width as integer)
    return Cint((width - m.gameFont.GetOneLineWidth(text, width)) / 2)
End Function

'------- Device Check Functions -------

Function IsHD()
    di = CreateObject("roDeviceInfo")
    return (di.GetUIResolution().name <> "sd")
End Function

Function IsfHD()
    di = CreateObject("roDeviceInfo")
    return(di.GetUIResolution() = "fhd")
End Function

Function IsOpenGL() as Boolean
    di = CreateObject("roDeviceInfo")
    model = Val(Left(di.GetModel(),1))
    return (model = 3 or model = 4 or model = 6)
End Function

Function GetManifestArray() as Object
    manifest = ReadAsciiFile("pkg:/manifest")
    lines = manifest.Tokenize(chr(10))
    aa = {}
    for each line in lines
        entry = line.Tokenize("=")
        aa.AddReplace(entry[0],entry[1].Trim())
    end for
    print aa
    return aa
End Function