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
                DestroyBuggy()
                exit while
            else if id = m.code.BUTTON_INSTANT_REPLAY_PRESSED
                ResetGame()
                DrawMoon()
                'm.buggy.usedCheat = true
                m.clock.Mark()
            else if id = m.code.BUTTON_PLAY_PRESSED
                PauseGame()
            else if id = m.code.BUTTON_INFO_PRESSED
                'ResetGame()
                ' if m.buggy.lives < m.settings.startLives + 1
                '     m.buggy.lives++
                '     m.buggy.usedCheat = true
                ' end if
            else if ControlNext(id)
                ' m.currentStage++
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
                if not m.startup then MoonUpdate()
                ' EnemiesLauncher()
                ' EnemiesUpdate()
                BuggyUpdate()
                'SoundUpdate()
                DrawScore()
                'Paint Screen
                m.compositor.AnimationTick(ticks)
                m.compositor.DrawAll()
                if m.showBase then DrawMessage()
                m.mainScreen.SwapBuffers()
                if m.showBase
                    PlaySound("start-course")
                    Sleep(4400)
                    m.showBase = false
                    PlaySong("theme", true)
                end if
                if m.freeze then stop
                m.freeze = false
                m.startup = false
                m.clock.Mark()
                'Check buggy death
                if m.gameOver
                    StopAudio()
                    ' GameOver()
                    DestroyMoon()
                    DestroyBuggy()
                    m.buggy = invalid
                    exit while
                end if
            end if
        end if
    end while
End Sub

Sub DrawMoon()
    if m.moon.layers <> invalid then DestroyMoon()
    m.moon.layers = [{speed: 1}, {speed: 3}, {speed: 6}]
    m.moon.layers[0].region = m.regions.images.Lookup("back-mountains")
    m.moon.layers[0].sprite = m.compositor.NewSprite(0, m.const.BACK_MOUNTAINS_Y, m.moon.layers[0].region , m.const.LAYER0_Z)
    if m.moon.landscape = m.const.MOON_HILLS
        m.moon.layers[1].region = m.regions.images.Lookup("front-hills")
        m.moon.layers[1].sprite = m.compositor.NewSprite(0, m.const.FRONT_HILLS_Y, m.moon.layers[1].region, m.const.LAYER1_Z)
    else
        m.moon.layers[1].region = m.regions.images.Lookup("front-city")
        m.moon.layers[1].sprite = m.compositor.NewSprite(0, m.const.FRONT_CITY_Y, m.moon.layers[1].region, m.const.LAYER1_Z)
    end if
    bmp = GetTerrain(m.const.TERRAIN_WIDTH)
    rgn = CreateObject("roRegion", bmp, 0, 0, bmp.GetWidth(), bmp.GetHeight())
    rgn.SetWrap(true)
    m.moon.layers[2].region = rgn
    m.moon.layers[2].sprite = m.compositor.NewSprite(0, m.const.GROUND_LEVEL_Y, m.moon.layers[2].region, m.const.LAYER2_Z)
    'Draw base
    y = m.const.GROUND_LEVEL_Y + m.const.GROUND_OFFSET_Y
    z = m.const.LAYER2_Z + 1
    if m.showBase
        if m.moon.base <> invalid then m.moon.base.Remove()
        x = 64
        m.moon.base = m.compositor.NewSprite(x, y - 48, m.regions.sprites.Lookup("base"), z)
        BuggyUpdate()
    end if
    'Draw holes
    y -= 8
    for h = 0 to m.moon.holes.Count() - 1
        hrg = m.regions.sprites.Lookup("hole-" + m.moon.holes[h].size.ToStr())
        x = m.moon.holes[h].x
        m.moon.holes[h].sprite = m.compositor.NewSprite(x, y + m.terrain[x], hrg, z)
    next
End Sub

Sub DrawScore()
    rgn = m.regions.images.Lookup("score-board")
    if m.moon.top = invalid
        m.moon.top = m.compositor.NewSprite(0, 0, rgn, m.const.SCORE_Z)
    else
        m.moon.top.SetRegion(rgn)
    end if
End Sub

Sub DrawMessage()
    text = "BEGINNER COURSE GO !"
    width = m.gameScreen.GetWidth()
    centerX = Cint(( width - m.gameFont.GetOneLineWidth(text, width)) / 2)
    m.gameScreen.DrawText(text, centerX, 140, m.colors.white, m.gameFont)
End Sub

Sub MoonUpdate()
    for l = 0 to 2
        m.moon.layers[l].region.OffSet(m.moon.layers[l].speed, 0, 0, 0)
    next
    m.moon.xOff += m.moon.layers[2].speed
    if m.moon.xOff >= m.moon.layers[2].region.GetWidth()
        print "finished layer 2"; m.moon.xOff
        m.moon.xOff -= m.moon.layers[2].region.GetWidth()
    end if

    if m.moon.base <> invalid
        m.moon.base.MoveOffset(-m.moon.layers[2].speed, 0)
        if m.moon.base.GetX() + 262 < 0
            m.moon.base.Remove()
            m.moon.base = invalid
            print "base sprite destroyed"
        end if
    end if
    for each hole in m.moon.holes
        if hole.sprite <> invalid
            hole.sprite.MoveOffset(-m.moon.layers[2].speed, 0)
            if hole.sprite.GetX() + 64 < 0
                hole.sprite.Remove()
                hole.sprite = invalid
            end if
        end if
    next
End Sub

Sub BuggyUpdate()
    'Draw Buggy
    if m.buggy = invalid
        gy = m.const.GROUND_LEVEL_Y + m.const.GROUND_OFFSET_Y
        m.buggy = {x: 144, y: gy - 45, yOff: 10, shake: 0, wheels: []}
        rgn = m.regions.sprites.Lookup("buggy-1")
        bx = m.buggy.x
        by = m.buggy.y - m.buggy.yOff
        m.buggy.sprite = m.compositor.NewSprite(bx, by, rgn, m.const.BUGGY_Z)
        'Wheels
        if m.settings.spriteMode = m.const.MODE_ARCADE
            wx = [bx + 2, bx + 20, bx + 46]
        else
            wx = [bx, bx + 22, bx + 50]
        end if
        wback = [m.regions.sprites.Lookup("wheel-2"), m.regions.sprites.Lookup("wheel-1")]
        wback[0].SetTime(200)
        wback[1].SetTime(200)
        wy = by + 46 - wback[0].GetHeight()
        m.buggy.wheels.Push(m.compositor.NewAnimatedSprite(wx[0], wy, wback, m.const.BUGGY_Z))
        m.buggy.wheels.Push(m.compositor.NewAnimatedSprite(wx[1], wy, wback, m.const.BUGGY_Z))
        wfront = [m.regions.sprites.Lookup("wheel-4"), m.regions.sprites.Lookup("wheel-3")]
        wfront[0].SetTime(200)
        wfront[1].SetTime(200)
        wy = by + 46 - wfront[0].GetHeight()
        m.buggy.wheels.Push(m.compositor.NewAnimatedSprite(wx[2], wy, wfront, m.const.BUGGY_Z))
    else
        if m.buggy.yOff > 0 and m.moon.base <> invalid and m.moon.base.GetX() < 0
            print "goind down from base"
            m.buggy.yOff--
            m.buggy.sprite.MoveOffset(0, 1)
            m.buggy.wheels[0].MoveOffset(0, 1)
            m.buggy.wheels[1].MoveOffset(0, 1)
            m.buggy.wheels[2].MoveOffset(0, 1)
        else if m.buggy.yOff = 0
            'Update buggy
            aOff = [1, 1, 2, 2, 3, 3, 2, 2]
            bx = m.buggy.x
            by = m.buggy.y + aOff[m.buggy.shake]
            m.buggy.sprite.MoveTo(bx, by)
            m.buggy.shake++
            if m.buggy.shake = aOff.Count() then m.buggy.shake = 0
            'Update wheels
            ww = m.buggy.wheels[0].GetRegion().GetWidth()
            wh = m.buggy.wheels[0].GetRegion().GetHeight()

            wx = m.buggy.wheels[0].GetX()
            idx = wx + ww + m.moon.xOff
            if idx > m.const.TERRAIN_WIDTH - 1 then idx -= m.const.TERRAIN_WIDTH
            wy = m.buggy.y + 46 - wh + m.terrain[idx]
            m.buggy.wheels[0].MoveTo(wx, wy)

            wx = m.buggy.wheels[1].GetX()
            idx = wx + ww + m.moon.xOff
            if idx > m.const.TERRAIN_WIDTH - 1 then idx -= m.const.TERRAIN_WIDTH
            wy = m.buggy.y + 46 - wh + m.terrain[idx]
            m.buggy.wheels[1].MoveTo(wx, wy)

            ww = m.buggy.wheels[2].GetRegion().GetWidth()
            wh = m.buggy.wheels[2].GetRegion().GetHeight()

            wx = m.buggy.wheels[2].GetX()
            idx = wx + ww + m.moon.xOff
            if idx > m.const.TERRAIN_WIDTH - 1 then idx -= m.const.TERRAIN_WIDTH
            wy = m.buggy.y + 46 - wh + m.terrain[idx]
            m.buggy.wheels[2].MoveTo(wx, wy)
        end if
    end if
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
    if m.moon.base <> invalid
        m.moon.base.Remove()
        m.moon.base = invalid
    end if
    for each hole in m.moon.holes
        if hole.sprite <> invalid
            hole.sprite.Remove()
            hole.sprite = invalid
        end if
    next
End Sub

Sub DestroyBuggy()
    if m.buggy <> invalid
        m.buggy.sprite.Remove()
        m.buggy.wheels[0].Remove()
        m.buggy.wheels[1].Remove()
        m.buggy.wheels[2].Remove()
        m.buggy = invalid
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
