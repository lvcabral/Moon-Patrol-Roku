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

Sub PlayGame()
    'Clear screen (needed for non-OpenGL devices)
    m.mainScreen.Clear(m.colors.black)
    m.mainScreen.SwapBuffers()
    m.mainScreen.Clear(m.colors.black)
    'Initialize flags and aux variables
    m.debug = false
    m.gameOver = false
    m.freeze = false
    'Game Loop
    m.clock.Mark()
    while true
        event = m.port.GetMessage()
        if type(event) = "roUniversalControlEvent"
            'Handle Remote Control events
            id = event.GetInt()
            if id = m.code.BUTTON_BACK_PRESSED
                StopAudio()
                DestroyMoon()
                exit while
            else if id = m.code.BUTTON_INSTANT_REPLAY_PRESSED
                ResetGame()
                'm.buggy.usedCheat = true
                m.clock.Mark()
            else if id = m.code.BUTTON_PLAY_PRESSED
                PauseGame()
            else if id = m.code.BUTTON_INFO_PRESSED
                m.currentStage++
                ResetGame()
                ' if m.buggy.lives < m.settings.startLives + 1
                '     m.buggy.lives++
                '     m.buggy.usedCheat = true
                ' end if
            else if ControlNext(id)
                m.currentStage++
                ResetGame()
                ' m.buggy.usedCheat = true
            else if ControlDebug(id)
                m.debug = not m.debug
            else
                'm.buggy.cursors.update(id)
            end if
        else if event = invalid
            'Game screen process
            ticks = m.clock.TotalMilliseconds()
            if ticks > m.speed
                'Update sprites
                if m.startup then BuggyStartup() else MoonUpdate()
                ' EnemiesLauncher()
                ' EnemiesUpdate()
                BuggyUpdate()
                'SoundUpdate()
                'Paint Screen
                m.compositor.AnimationTick(ticks)
                m.compositor.DrawAll()
                DrawScore()
                m.mainScreen.SwapBuffers()
                if m.freeze then stop
                m.freeze = false
                m.clock.Mark()
                'Check buggy death
                if m.gameOver
                    StopAudio()
                    ' GameOver()
                    DestroyMoon()
                    m.buggy = invalid
                    exit while
                end if
            end if
        end if
    end while
End Sub

Sub DrawMoon()
    if m.moon.layers <> invalid then DestroyMoon()
    m.moon.layers = [{speed: 2}, {speed: 4}, {speed: 5}]
    m.moon.layers[0].region = m.regions.Lookup("back-mountain")
    m.moon.layers[0].sprite = m.compositor.NewSprite(0, m.const.BACK_MOUNTAIN_Y, m.moon.layers[0].region , m.const.LAYER0_Z)
    if m.moon.landscape = m.const.MOON_MOUNTAIN
        m.moon.layers[1].region = m.regions.Lookup("front-mountain")
        m.moon.layers[1].sprite = m.compositor.NewSprite(0, m.const.FRONT_MOUNTAIN_Y, m.moon.layers[1].region, m.const.LAYER1_Z)
    else
        m.moon.layers[1].region = m.regions.Lookup("front-city")
        m.moon.layers[1].sprite = m.compositor.NewSprite(0, m.const.FRONT_CITY_Y, m.moon.layers[1].region, m.const.LAYER1_Z)
    end if
    m.moon.layers[2].region = m.regions.Lookup("ground-level")
    m.moon.layers[2].sprite = m.compositor.NewSprite(0, m.const.GROUND_LEVEL_Y, m.moon.layers[2].region, m.const.LAYER2_Z)
End Sub

Sub DrawScore()
    rgn = m.regions.Lookup("score-board")
    if m.moon.top = invalid
        m.moon.top = m.compositor.NewSprite(0, 0, rgn, m.const.LAYER2_Z)
    else
        m.moon.top.SetRegion(rgn)
    end if
End Sub

Sub MoonUpdate()
    for l = 0 to 2
        m.moon.layers[l].region.OffSet(m.moon.layers[l].speed, 0, 0, 0)
    next
End Sub

Sub BuggyStartup()
    PlaySong("theme", true)
    DrawMoon()
    m.startup = false
End Sub

Sub BuggyUpdate()

End Sub

Sub PauseGame()
    m.audioPlayer.Pause()
    text = "GAME PAUSED"
    textWidth = m.gameFont.GetOneLineWidth(text, m.gameWidth)
    textHeight = m.gameFont.GetOneLineHeight()
    x = Cint((m.gameWidth - textWidth) / 2)
    y = 308
    m.gameScreen.DrawRect(x - 32, y - 32, textWidth + 64, textHeight + 64, m.colors.black)
    m.gameScreen.DrawText(text, x, y, m.colors.white, m.gameFont)
    m.mainScreen.SwapBuffers()
    while true
        key = wait(0, m.port)
        if key = m.code.BUTTON_PLAY_PRESSED then exit while
    end while
    m.audioPlayer.Play()
    m.clock.Mark()
End Sub

Sub DestroyMoon()
    if m.moon.top <> invalid
        m.moon.top.Remove()
        m.moon.top = invalid
    end if
    if m.moon.layers <> invalid
        for i = 0 to 2
            m.moon.layers[i].sprite.Remove()
            m.moon.layers[i].sprite = invalid
        next
        m.moon.layers = invalid
    end if
End Sub

Function ControlNext(id as integer) as boolean
    vStatus = m.settings.controlMode = m.const.CONTROL_VERTICAL and id = m.code.BUTTON_A_PRESSED
    hStatus = m.settings.controlMode = m.const.CONTROL_HORIZONTAL and id = m.code.BUTTON_FAST_FORWARD_PRESSED
    return vStatus or hStatus
End Function

Function ControlDebug(id as integer) as boolean
    vStatus = m.settings.controlMode = m.const.CONTROL_VERTICAL and id = m.code.BUTTON_B_PRESSED
    hStatus = m.settings.controlMode = m.const.CONTROL_HORIZONTAL and id = m.code.BUTTON_REWIND_PRESSED
    return vStatus or hStatus
End Function
