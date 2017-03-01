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

    const.MOON_HILLS = 0
    const.MOON_CITY  = 1

    const.COURSE_BEGGINER = 0
    const.COURSE_CHAMPION = 1

    const.BACK_MOUNTAINS_Y = 188
    const.FRONT_HILLS_Y    = 258
    const.FRONT_CITY_Y     = 256
    const.GROUND_LEVEL_Y   = 320
    const.GROUND_OFFSET_Y  = 84

    const.PANEL_WIDTH      = 640
    const.PANEL_HEIGHT     = 160

    const.TERRAIN_WIDTH    = 2000

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
    const.SCORE_Z  = 50

    return const
End Function

Function LoadBitmapRegions(path as string, jsonFile as string, pngFile = "" as string) as object
    if pngFile = ""
        pngFile = jsonFile
    end if
    print "loading ";path + jsonFile + ".json"
    json = ParseJson(ReadAsciiFile(path + jsonFile + ".json"))
    regions = {}
    if json <> invalid
        bitmap = CreateObject("roBitmap", path + pngFile + ".png")
        for each name in json.frames
            frame = json.frames.Lookup(name).frame
            regions.AddReplace(name, CreateObject("roRegion", bitmap, frame.x, frame.y, frame.w, frame.h))
        next
    end if
    return regions
End Function

Function GetRegion(image as string, wrap = false as boolean) as object
    bmp = CreateObject("roBitmap", image)
    rgn = CreateObject("roRegion", bmp, 0, 0, bmp.GetWidth(), bmp.GetHeight())
    rgn.SetWrap(wrap)
    return rgn
End Function

Function GetTerrain(width as integer) as object
    font = m.fonts.getFont("Press Start 2P", 14, false, false)
    if m.settings.spriteMode = m.const.MODE_ARCADE
        mColor = &h00DE51FF
        gColor = &hFF9751FF
        bColor = mColor
        tColor = &h210000FF
    else
        mColor = &h00A000FF
        gColor = &hC06000FF
        bColor = gColor
        tColor = m.colors.yellow
    end if
    bmp = CreateObject("roBitmap", {width:width, height:m.const.PANEL_HEIGHT, alphaenable:true})
    height = m.const.PANEL_HEIGHT - m.const.GROUND_OFFSET_Y
    bmp.DrawRect(0, m.const.GROUND_OFFSET_Y, bmp.GetWidth(), height, gColor)
    c = 0
    depth = (Rnd(5) - 1) * 2
    s = 0
    m.terrain = []
    ap = [6, 6, 6, 8, 8, 8, 8, 10, 10, 10, 10, 10, 10, 12, 12, 12]
    while c < width
        if s <= 0
            path = ap[Rnd(ap.Count()) - 1]
            dest = (Rnd(5) - 1) * 2
            s = path
        end if
        if dest > depth
            move = (Rnd(2) - 1) * 2
        else if dest < depth
            move = -(Rnd(2) - 1) * 2
        else
            move = 0
        end if
        depth += move
        wide = (Rnd(4) + 1) * 2
        if depth > 0
            bmp.DrawRect(c, m.const.GROUND_OFFSET_Y, wide, depth, mColor)
        end if
        for t = 1 to wide
            m.terrain.Push(depth)
        next
        s -= wide
        c += wide
    end while
    print "terrain array size = "; m.terrain.Count()
    bmp.DrawRect(bmp.GetWidth() - 32, bmp.GetHeight() - 30, 16, 16, bColor)
    bmp.DrawText("A", bmp.GetWidth() - 30, bmp.GetHeight() - 28, tColor, font)
    bmp.Finish()
    return bmp
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
    'if settings.highScores = invalid
        settings.highScores = [ {score: 750, point: "A", name: "MLC"},
                                {score: 0, point: "", name: ""},
                                {score: 0, point: "", name: ""},
                                {score: 0, point: "", name: ""},
                                {score: 0, point: "", name: ""}]
    'end if
    return settings
End Function

'------- Numeric and String Functions -------

Function zeroPad(number as integer, length = 2 as integer) as string
    text = number.ToStr()
    if text.Len() < length then text = String(length-text.Len(), "0") + text
    return text
End Function

Function padCenter(text as string, size as integer) as string
    if Len(text) > size
        return text.Left(size)
    else if Len(text) < size
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
    if Len(text) > size
        return text.Left(size)
    else if Len(text) < size
        text += String(size - Len(text), 32)
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
