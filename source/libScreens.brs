' ********************************************************************************************************
' ********************************************************************************************************
' **  Roku Moon Patrol Channel - http://github.com/lvcabral/Moon-Patrol-Roku
' **
' **  libCanvas.brs - Library with generic methods for Screen objects
' **  Created: June 2018
' **  Updated: September 2019
' **
' **  Copyright (C) Marcelo Lv Cabral < https://lvcabral.com >
' ********************************************************************************************************
' ********************************************************************************************************

'-----
' Generic Methods

Sub close_screen()
    m.visible = false
    m.canvas.Close()
End Sub

Sub set_list_style(style as string)
    m.listStyle = style
End Sub

Sub set_display_mode(mode as string)
    m.displayMode = mode
End Sub

Sub set_breadcrumb_text(leftText as string, rightText as string)
    font = m.canvas.fonts.large
    wl = font.GetOneLineWidth(leftText, 500)
    wr = font.GetOneLineWidth(rightText, 500)
    xr = 1228 - wr
    xb = xr - 22
    xl = xr - wl - 28
    m.breadCrumb = []
    m.breadCrumb.Push({ Text: leftText
                        TextAttrs: {color: m.theme.BreadcrumbTextLeft, font: font, HAlign: "Left"}
                        TargetRect: {x:xl, y:72, w:wl, h:24}})
    m.breadCrumb.Push({ Text: "•"
                        TextAttrs: {color: m.theme.BreadcrumbDelimiter, font: font, HAlign: "Left"}
                        TargetRect: {x:xb, y:72, w:20, h:24}})
    m.breadCrumb.Push({ Text: rightText
                        TextAttrs: {color: m.theme.BreadcrumbTextRight, font: font, HAlign: "Left"}
                        TargetRect: {x:xr, y:72, w:wr, h:24}})   
End Sub

Sub set_focused_item(index as integer)
    m.focus = index
    if m.visible then m.Show()
End Sub

Function get_content_list() as object
    return m.content
End Function

'------ 
' Generic Functions

Function GetOverhang()
    theme = m.theme
    overhang = []
    overhang.Push({ Color: "#000000FF", CompositionMode: "Source", url: theme.OverhangSliceHD})
    if theme.OverhangLogoHD <> invalid
        overhang.Push({ url: theme.OverhangLogoHD, TargetRect: {x: int(val(theme.OverhangOffsetHD_X)), y: int(val(theme.OverhangOffsetHD_Y))} })
    end if
    return overhang
End Function

Function GetScreenMessage(index as integer, event as string)
    this = {index: index, event: event}
    this.isListItemFocused = function() as boolean
        return (m.event = "focused")
    end function
    this.isListItemSelected = function() as boolean
        return (m.event = "selected")
    end function
    this.isScreenClosed = function() as boolean
        return (m.event = "closed")
    end function
    this.isRemoteKeyPressed = function() as boolean
        return (m.event = "remote")
    end function
    this.isButtonPressed = function() as boolean
        return (m.event = "button")
    end function
    this.GetIndex = function() as integer
        return m.index
    end function
    return this
End Function

Sub InitCache()
    g = GetGlobalAA()
    if g.files = invalid then g.files = CreateObject("roFileSystem")
    if g.cache = invalid 
        g.cache = {}
        g.cacheId = 0
    end if
End Sub

Function AddToCache(fileName as string, bmp as object, update = false as boolean) as string
    g = GetGlobalAA()
    tmpFile = g.cache.Lookup(fileName)
    if tmpFile = invalid
        g.cacheId++
        tmpFile = "tmp:/cached" + g.cacheId.toStr() + ".png"
        g.cache.AddReplace(fileName,tmpFile)
    end if
    if update or not g.files.Exists(tmpFile)
        png = bmp.GetPng(0, 0, bmp.GetWidth(), bmp.GetHeight())
        png.WriteFile(tmpFile)
    end if
    return tmpFile
End Function

Function CachedFile(fileName as string) as string
    g = GetGlobalAA()
    tmpFile = g.cache.Lookup(fileName)
    if tmpFile = invalid then tmpFile = fileName
    return tmpFile
End Function

Function CenterImage(url as string, width as integer, height as integer) as string
    por = CreateObject("roBitmap", url)
    if por.GetWidth() <> width or por.GetHeight() <> height
        bmp = CreateObject("roBitmap",{width:width, height:height, alphaenable:true})
        pst = ScaleToSize(por, width, height)
        if pst <> invalid
            if pst.GetWidth() < width then offX = (width - pst.GetWidth()) / 2 else offX = 0
            if pst.GetHeight() < height then offY = (height - pst.GetHeight()) / 2 else offY = 0
            bmp.DrawObject(offX, offY, pst)
        else
            print "invalid image:"; url
        end if
        url = AddToCache(url + "300x300", bmp, true)
    end if
    return url
End Function

Function ScaleBitmap(bitmap as object, scale as float, simpleMode = false as boolean) as object
    if bitmap = invalid or bitmap.GetWidth() = 0 then return bitmap
    if scale = 1.0
        scaled = bitmap
    else if scale = int(scale) or simpleMode
		scaled = CreateObject("roBitmap",{width:int(bitmap.GetWidth()*scale), height:int(bitmap.GetHeight()*scale), alphaenable:bitmap.GetAlphaEnable()})
		scaled.DrawScaledObject(0,0,scale,scale,bitmap)
    else
        region = CreateObject("roRegion", bitmap, 0, 0, bitmap.GetWidth(), bitmap.GetHeight())
        region.SetScaleMode(1)
        scaled = CreateObject("roBitmap",{width:int(bitmap.GetWidth()*scale), height:int(bitmap.GetHeight()*scale), alphaenable:bitmap.GetAlphaEnable()})
        scaled.DrawScaledObject(0,0,scale,scale,region)
	end if
    return scaled
End Function

Function ScaleToSize(bitmap as object, width as integer, height as integer, ratio = true as boolean) as object
    if bitmap = invalid then return bitmap
    if ratio and bitmap.GetWidth() <= width and bitmap.GetHeight() <= height
        scaled = bitmap
    else
        region = CreateObject("roRegion", bitmap, 0, 0, bitmap.GetWidth(), bitmap.GetHeight())
        region.SetScaleMode(1)
        if ratio
            if bitmap.GetWidth() > bitmap.GetHeight()
                scale = width / bitmap.GetWidth()
            else
                scale = height / bitmap.GetHeight()
            end if
            scaled = CreateObject("roBitmap",{width:int(bitmap.GetWidth()*scale), height:int(bitmap.GetHeight()*scale), alphaenable:bitmap.GetAlphaEnable()})
            scaled.DrawScaledObject(0,0,scale,scale,region)
        else
            scaleX = width / bitmap.GetWidth()
            scaleY = height / bitmap.GetHeight()
            scaled = CreateObject("roBitmap",{width:width, height:height, alphaenable:bitmap.GetAlphaEnable()})
            scaled.DrawScaledObject(0,0,scaleX,scaleY,region)
        end if
	end if
    return scaled
End Function
