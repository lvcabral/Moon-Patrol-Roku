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

Function StartMenu(focus as integer) as integer
    this = {
            screen: CreateObject("roListScreen")
            port: CreateObject("roMessagePort")
           }
    'Cache HighScore bitmap
    if m.scoresChanged = invalid or m.scoresChanged
        print "caching high scores"
        bmp = GetHighScoreBitmap()
        png = bmp.GetPng(0, 0, bmp.GetWidth(), bmp.GetHeight())
        png.WriteFile("tmp:/high_scores.png")
        m.scoresChanged = false
    end if
    'Draw Menu
    this.screen.SetMessagePort(this.port)
    this.screen.SetHeader("Game Menu")
    this.controlModes = ["Vertical Mode", "Horizontal Mode"]
    this.controlHelp  = ["", ""]
    this.controlImage = ["pkg:/images/control_vertical.png", "pkg:/images/control_horizontal.png"]
    this.spriteMode = ["Arcade", "Atari ST"]
    this.spriteHelp  = ["Arcade sprites", "Atari ST sprites"]
    this.spriteImage = ["pkg:/images/menu_arcade.png", "pkg:/images/menu_atari_st.png"]
    listItems = GetMenuItems(this)
    this.screen.SetContent(listItems)
    this.screen.SetFocusedListItem(focus)
    this.screen.Show()
    startGame = false
    listIndex = 0
    oldIndex = 0
    selection = -1
    while true
        msg = wait(0,this.port)
        if msg.isScreenClosed() then exit while
        if type(msg) = "roListScreenEvent"
            if msg.isListItemFocused()
                listIndex = msg.GetIndex()
            else if msg.isListItemSelected()
                selection = msg.GetIndex()
                if selection = m.const.MENU_START
                    SaveSettings(m.settings)
                    exit while
                else if selection >= m.const.MENU_HISCORES
                    exit while
                end if
            else if msg.isRemoteKeyPressed()
                remoteKey = msg.GetIndex()
                update = (remoteKey = m.code.BUTTON_LEFT_PRESSED or remoteKey = m.code.BUTTON_RIGHT_PRESSED)
                if remoteKey = m.code.BUTTON_REWIND_PRESSED
                    this.screen.SetFocusedListItem(m.const.MENU_START)
                else if remoteKey = m.code.BUTTON_FAST_FORWARD_PRESSED
                    this.screen.SetFocusedListItem(m.const.MENU_CREDITS)
                else if listIndex = m.const.MENU_CONTROL
                    if remoteKey = m.code.BUTTON_LEFT_PRESSED
                        m.settings.controlMode--
                        if m.settings.controlMode < 0 then m.settings.controlMode = this.controlModes.Count() - 1
                    else if remoteKey = m.code.BUTTON_RIGHT_PRESSED
                        m.settings.controlMode++
                        if m.settings.controlMode = this.controlModes.Count() then m.settings.controlMode = 0
                    end if
                    if update
                        listItems[listIndex].Title = "Control: " + this.controlModes[m.settings.controlMode]
                        listItems[listIndex].ShortDescriptionLine1 = this.controlHelp[m.settings.controlMode]
                        listItems[listIndex].HDPosterUrl = this.controlImage[m.settings.controlMode]
                        listItems[listIndex].SDPosterUrl = this.controlImage[m.settings.controlMode]
                        this.screen.SetItem(listIndex, listItems[listIndex])
                        m.sounds.navSingle.Trigger(50)
                    end if
                else if listIndex = m.const.MENU_SPRITES
                    if remoteKey = m.code.BUTTON_LEFT_PRESSED
                        m.settings.spriteMode--
                        if m.settings.spriteMode < 0 then m.settings.spriteMode = this.spriteMode.Count() - 1
                    else if remoteKey = m.code.BUTTON_RIGHT_PRESSED
                        m.settings.spriteMode++
                        if m.settings.spriteMode = this.spriteMode.Count() then m.settings.spriteMode = 0
                    end if
                    if update
                        listItems[listIndex].Title = "Graphics: " + this.spriteMode[m.settings.spriteMode]
                        listItems[listIndex].ShortDescriptionLine1 = this.spriteHelp[m.settings.spriteMode]
                        listItems[listIndex].HDPosterUrl = this.spriteImage[m.settings.spriteMode]
                        listItems[listIndex].SDPosterUrl = this.spriteImage[m.settings.spriteMode]
                        this.screen.SetItem(listIndex, listItems[listIndex])
                        m.sounds.navSingle.Trigger(50)
                    end if
                end if
            end if
        end if
    end while
    return selection
End Function

Function GetMenuItems(menu as object)
    listItems = []
    listItems.Push({
                Title: "Start the Game"
                HDSmallIconUrl: "pkg:/images/icon_start.png"
                SDSmallIconUrl: "pkg:/images/icon_start.png"
                HDPosterUrl: "pkg:/images/arcade_machine.png"
                SDPosterUrl: "pkg:/images/arcade_machine.png"
                ShortDescriptionLine1: ""
                ShortDescriptionLine2: "Press OK to start the game"
                })
    listItems.Push({
                Title: "Control: " + menu.controlModes[m.settings.controlMode]
                HDSmallIconUrl: "pkg:/images/icon_arrows.png"
                SDSmallIconUrl: "pkg:/images/icon_arrows.png"
                HDPosterUrl: menu.controlImage[m.settings.controlMode]
                SDPosterUrl: menu.controlImage[m.settings.controlMode]
                ShortDescriptionLine1: menu.controlHelp[m.settings.controlMode]
                ShortDescriptionLine2: "Use Left and Right to set the control mode"
                })
    listItems.Push({
                Title: "Graphics: " + menu.spriteMode[m.settings.spriteMode]
                HDSmallIconUrl: "pkg:/images/icon_arrows.png"
                SDSmallIconUrl: "pkg:/images/icon_arrows.png"
                HDPosterUrl: menu.spriteImage[m.settings.spriteMode]
                SDPosterUrl: menu.spriteImage[m.settings.spriteMode]
                ShortDescriptionLine1: menu.spriteHelp[m.settings.spriteMode]
                ShortDescriptionLine2: "Use Left and Right to set the graphics"
                })
    listItems.Push({
                Title: "High Scores"
                HDSmallIconUrl: "pkg:/images/icon_hiscores.png"
                SDSmallIconUrl: "pkg:/images/icon_hiscores.png"
                HDPosterUrl: "tmp:/high_scores.png"
                SDPosterUrl: "tmp:/high_scores.png"
                ShortDescriptionLine1: "Use of cheat keys during the game disables high score record"
                ShortDescriptionLine2: "Press OK to open High Scores"
                })
    listItems.Push({
                Title: "Game Credits"
                HDSmallIconUrl: "pkg:/images/icon_info.png"
                SDSmallIconUrl: "pkg:/images/icon_info.png"
                HDPosterUrl: "pkg:/images/menu_credits.png"
                SDPosterUrl: "pkg:/images/menu_credits.png"
                ShortDescriptionLine1: "Alpha v" + m.manifest.major_version + "." + m.manifest.minor_version + "." + m.manifest.build_version
                ShortDescriptionLine2: "Press OK to read game credits"
                })
    return listItems
End Function

Sub ShowHighScores(waitTime = 0 as integer)
    screen = m.mainScreen
    Sleep(250) ' Give time to Roku clear list screen from memory
    if m.isOpenGL
        screen.Clear(m.colors.black)
        screen.SwapBuffers()
    end if
    scoreFont = m.fonts.getFont("Press Start 2P", 14, false, false)
    bmp = CreateObject("roBitmap", "tmp:/high_scores.png")
    message = "PRESS ANY KEY TO RETURN"
    centerX = Cint((bmp.GetWidth() - scoreFont.GetOneLineWidth(message, bmp.GetWidth())) / 2)
    bmp.DrawText(message, centerX, 370, m.colors.white, scoreFont)
    'Paint screen
    centerX = Cint((screen.GetWidth() - bmp.GetWidth()) / 2)
    centerY = Cint((screen.GetHeight() - bmp.GetHeight()) / 2)
    screen.Clear(m.colors.black)
    screen.DrawObject(centerX, centerY, bmp)
    screen.SwapBuffers()
    while true
        key = wait(waitTime, m.port)
        if key = invalid or key < 100 then exit while
    end while
End Sub

Sub ShowCredits(waitTime = 0 as integer)
    screen = m.mainScreen
    Sleep(250) ' Give time to Roku clear list screen from memory
    if m.isOpenGL
        screen.Clear(m.colors.black)
        screen.SwapBuffers()
    end if
    imgIntro = "pkg:/images/game_credits.png"
    bmp = CreateObject("roBitmap", imgIntro)
    centerX = Cint((screen.GetWidth() - bmp.GetWidth()) / 2)
    centerY = Cint((screen.GetHeight() - bmp.GetHeight()) / 2)
    screen.Clear(m.colors.black)
    screen.DrawObject(centerX, centerY, bmp)
    screen.SwapBuffers()
	while true
    	key = wait(waitTime, m.port)
		if key = invalid or key < 100 then exit while
	end while
End Sub

Function GetHighScoreBitmap() as object
    scoreFont = m.fonts.getFont("Press Start 2P", 14, false, false)
    bmp = CreateObject("roBitmap", "pkg:/images/frame_high_scores.png")
    title = "TOP   SCORES"
    centerX = Cint((bmp.GetWidth() - scoreFont.GetOneLineWidth(title, bmp.GetWidth())) / 2)
    bmp.DrawText(title, centerX, 100, m.colors.cyan, scoreFont)
    bmp.DrawText("    5", centerX, 100, m.colors.white, scoreFont)
    header = "NO. POINT  SCORE   INITIALS"
    centerX = Cint((bmp.GetWidth() - scoreFont.GetOneLineWidth(header, bmp.GetWidth())) / 2)
    hs = m.settings.highScores
    bmp.DrawText(header, centerX, 130, m.colors.white, scoreFont)
    for i = 0 to 4
        y = 160 + i * 25
        score = Str(i + 1) + "         " + zeroPad(hs[i].score, 6)
        bmp.DrawText(score, centerX, y, m.colors.yellow, scoreFont)
        if hs[i].point <> ""
            score = "      " + hs[i].point + "              " + hs[i].name
            bmp.DrawText(score, centerX, y, m.colors.orange, scoreFont)
        else
            bmp.DrawRect(centerX + 6 * 14, y, 14, 14, m.colors.cyan)
        end if
    next
    bmp.Finish()
    return bmp
End Function
