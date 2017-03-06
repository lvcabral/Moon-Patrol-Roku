' ********************************************************************************************************
' ********************************************************************************************************
' **  Roku Moon Patrol Channel - http://github.com/lvcabral/Moon-Patrol-Roku
' **
' **  Created: February 2017
' **  Updated: March 2017
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
    m.high = {score: m.settings.highScores[0].score, point: m.settings.highScores[0].point}
    m.board = m.regions.images.Lookup("score-board-" + m.currentCourse.ToStr())
    m.score = 0
    m.lives = 3
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
                DestroyBuggy()
                DrawMoon()
                m.clock.Mark()
            else if id = m.code.BUTTON_PLAY_PRESSED
                PauseGame()
            else if id = m.code.BUTTON_INFO_PRESSED
                if m.lives < 9
                     m.lives++
                     m.usedCheat = true
                end if
            else if m.buggy <> invalid
                m.buggy.cursors.update(id)
            end if
        else if event = invalid
            'Game screen process
            ticks = m.clock.TotalMilliseconds()
            if ticks > m.speed
                'Update sprites
                if not m.startup and m.buggy.state <= m.const.BUGGY_JUMP
                    m.time += m.speed
                    MoonUpdate()
                end if
                ' EnemiesLauncher()
                ' EnemiesUpdate()
                BuggyUpdate()
                SoundUpdate()
                'Paint Screen
                m.compositor.AnimationTick(ticks)
                m.compositor.DrawAll()
                DrawScore()
                if m.showBase then DrawMessage()
                m.mainScreen.SwapBuffers()
                if m.showBase
                    PlaySound("start-course")
                    Sleep(4400)
                    m.showBase = false
                    PlaySong("theme", true)
                    m.time = 0
                end if
                if m.freeze then stop
                m.freeze = false
                m.startup = false
                m.clock.Mark()
                'Check buggy crash
                if m.buggy.crashed
                    m.lives--
                    if m.lives >= 0
                        ResetGame()
                        DrawMoon()
                        DestroyBuggy()
                    else
                        m.gameOver = true
                    end if
                end if
                'Check game over
                if m.gameOver or m.currentStage = 26
                    StopAudio()
                    GameOver()
                    DestroyMoon()
                    DestroyBuggy()
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
    m.moon.layers[0].sprite.SetMemberFlags(0)
    if m.moon.landscape = m.const.MOON_HILLS
        m.moon.layers[1].region = m.regions.images.Lookup("front-hills")
        m.moon.layers[1].sprite = m.compositor.NewSprite(0, m.const.FRONT_HILLS_Y, m.moon.layers[1].region, m.const.LAYER1_Z)
    else
        m.moon.layers[1].region = m.regions.images.Lookup("front-city")
        m.moon.layers[1].sprite = m.compositor.NewSprite(0, m.const.FRONT_CITY_Y, m.moon.layers[1].region, m.const.LAYER1_Z)
    end if
    m.moon.layers[1].sprite.SetMemberFlags(0)
    bmp = GetTerrain(m.const.TERRAIN_WIDTH)
    rgn = CreateObject("roRegion", bmp, 0, 0, bmp.GetWidth(), bmp.GetHeight())
    rgn.SetWrap(true)
    m.moon.layers[2].region = rgn
    m.moon.layers[2].sprite = m.compositor.NewSprite(0, m.const.GROUND_LEVEL_Y, m.moon.layers[2].region, m.const.LAYER2_Z)
    m.moon.layers[2].sprite.SetMemberFlags(0)
    m.moon.stage = {current: m.currentStage, switch: false}
    'Draw base
    y = m.const.GROUND_LEVEL_Y + m.const.GROUND_OFFSET_Y
    z = m.const.LAYER2_Z + 1
    if m.showBase
        if m.moon.base <> invalid then m.moon.base.Remove()
        x = 64
        m.moon.base = m.compositor.NewSprite(x, y - 48, m.regions.sprites.Lookup("base"), z)
        m.moon.base.SetMemberFlags(0)
        BuggyUpdate()
    end if
    'Draw holes
    y -= 8
    for h = 0 to m.moon.holes.Count() - 1
        hrg = m.regions.sprites.Lookup("hole-" + m.moon.holes[h].size.ToStr())
        hrg.SetCollisionRectangle(8, 0, hrg.GetWidth() - 16, hrg.GetHeight())
        hrg.SetCollisionType(1)
        x = m.moon.holes[h].x
        m.moon.holes[h].sprite = m.compositor.NewSprite(x, y + m.terrain[x], hrg, z)
        m.moon.holes[h].sprite.SetData("hole")
    next
End Sub

Sub DrawMessage()
    if m.currentCourse = m.const.COURSE_BEGINNER
        text = "BEGINNER COURSE GO !"
    else
        text = "CHAMPION COURSE GO !"
    end if
    width = m.gameScreen.GetWidth()
    centerX = Cint(( width - m.gameFont.GetOneLineWidth(text, width)) / 2)
    m.gameScreen.DrawText(text, centerX, 140, m.colors.white, m.gameFont)
End Sub

Sub DrawScore()
    width = m.gameScreen.GetWidth()
    m.gameScreen.DrawObject(0, 0, m.board)
    strPoint = Chr(m.currentStage + 64)
    if m.score > m.high.score
        m.high.score = m.score
        m.high.point = strPoint
    end if
    if m.settings.spriteMode = m.const.MODE_ARCADE
        'Lives
        strLives = " "
        if m.lives> 0 then strLives = m.lives.ToStr()
        m.gameScreen.DrawText(strLives, 580, 36, m.colors.yellow, m.gameFont)
        'Scores
        strHigh = zeroPad(m.high.score, 6)
        x = 160 - m.gameFont.GetOneLineWidth(strHigh, 120)
        m.gameScreen.DrawText(strHigh, x, 18, m.colors.red, m.gameFont)
        x = 192 - m.gameFont.GetOneLineWidth(m.high.point, 40)
        m.gameScreen.DrawText(m.high.point, x, 18, m.colors.black, m.gameFont)
        strScore = zeroPad(m.score, 6)
        x = 160 - m.gameFont.GetOneLineWidth(strScore, 120)
        m.gameScreen.DrawText(strScore, x, 50, m.colors.yellow, m.gameFont)
        'Point
        if m.currentStage > 0
            m.gameScreen.DrawRect(232, 82, 250 / 26 * m.currentStage, 8, m.colors.red)
            x = 348 - m.gameFont.GetOneLineWidth(strPoint, 40)
            m.gameScreen.DrawText(strPoint, x, 18, m.colors.black, m.gameFont)
        end if
        'Time
        strTime = zeroPad(Int(m.time / 1000), 3)
        x = 348 - m.gameFont.GetOneLineWidth(strTime, 70)
        m.gameScreen.DrawText(strTime, x, 50, m.colors.red, m.gameFont)
    else
        'Lives
        m.gameScreen.DrawText(m.lives.ToStr(), 608, 32, m.colors.cyan, m.smallFont)
        'Scores
        strHigh = m.high.score.ToStr()
        x = 140 - m.smallFont.GetOneLineWidth(strHigh, 96)
        m.gameScreen.DrawText(strHigh, x, 18, m.colors.yellow, m.smallFont)
        x = 170 - m.smallFont.GetOneLineWidth(m.high.point, 96)
        m.gameScreen.DrawText(m.high.point, x, 18, m.colors.yellow, m.smallFont)
        strScore = m.score.ToStr()
        x = 140 - m.smallFont.GetOneLineWidth(strScore, 96)
        m.gameScreen.DrawText(strScore, x, 48, m.colors.yellow, m.smallFont)
        'Point
        if m.currentStage > 0
            m.gameScreen.DrawRect(192, 82, 320 / 26 * m.currentStage, 2, m.colors.red)
            x = 332 - m.gameFont.GetOneLineWidth(strPoint, 40)
            m.gameScreen.DrawText(strPoint, x, 18, m.colors.cyan, m.gameFont)
        end if
        'Time
        strTime = Int(m.time / 1000).ToStr()
        x = 332 - m.smallFont.GetOneLineWidth(strTime, 70)
        m.gameScreen.DrawText(strTime, x, 48, m.colors.cyan, m.smallFont)
    end if
End Sub

Sub MoonUpdate()
    for l = 0 to 2
        m.moon.layers[l].region.OffSet(m.moon.layers[l].speed, 0, 0, 0)
    next
    m.moon.xOff += m.moon.layers[2].speed
    if m.moon.xOff >= m.const.TERRAIN_LIMIT
        label = ""
        if m.moon.stage.switch
            m.moon.stage.current++
            label = Chr(m.moon.stage.current + 64)
        end if
        m.moon.xOff -= m.const.TERRAIN_LIMIT
        old = m.moon.layers[2].region.GetBitmap()
        new = GetTerrain(m.const.TERRAIN_LIMIT, "", true)
        bmp = UpdateTerrain(old, new, label)
        rgn = CreateObject("roRegion", bmp, 0, 0, bmp.GetWidth(), bmp.GetHeight())
        rgn.SetWrap(true)
        rgn.OffSet(m.moon.xOff, 0, 0, 0)
        m.moon.layers[2].sprite.Remove()
        m.moon.layers[2].region = rgn
        m.moon.layers[2].sprite = m.compositor.NewSprite(0, m.const.GROUND_LEVEL_Y, m.moon.layers[2].region, m.const.LAYER2_Z)
        m.moon.layers[2].sprite.SetMemberFlags(0)
        m.moon.stage.switch = not m.moon.stage.switch
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
    'Draw New Buggy
    if m.buggy = invalid
        gy = m.const.GROUND_LEVEL_Y + m.const.GROUND_OFFSET_Y
        m.buggy = {x: 144, y: gy - 45, yOff: 0, shake: 0, wheels: []}
        if m.showBase then m.buggy.yOff = 10
        m.buggy.cursors = GetControl(m.settings.controlMode)
        m.buggy.jump = m.anims.buggy.sequence.jump
        m.buggy.explode = m.anims.buggy.sequence.explode
        m.buggy.loose = {anim: m.anims.buggy.sequence.loose}
        rgn = m.regions.sprites.Lookup("buggy-1")
        bx = m.buggy.x
        by = m.buggy.y - m.buggy.yOff
        m.buggy.sprite = m.compositor.NewSprite(bx, by, rgn, m.const.BUGGY_Z)
        m.buggy.sprite.SetData("buggy")
        'Wheels
        if m.settings.spriteMode = m.const.MODE_ARCADE
            wx = [bx + 2, bx + 20, bx + 46]
        else
            wx = [bx, bx + 22, bx + 50]
        end if
        wback = GetAnimation(m.anims.buggy.sequence, m.regions.sprites, "wheel", "back-wheel")
        wy = by + 46 - wback[0].GetHeight()
        m.buggy.wheels.Push(m.compositor.NewAnimatedSprite(wx[0], wy, wback, m.const.BUGGY_Z))
        m.buggy.wheels.Push(m.compositor.NewAnimatedSprite(wx[1], wy, wback, m.const.BUGGY_Z))
        wfront = GetAnimation(m.anims.buggy.sequence, m.regions.sprites, "wheel", "front-wheel")
        wy = by + 46 - wfront[0].GetHeight()
        m.buggy.wheels.Push(m.compositor.NewAnimatedSprite(wx[2], wy, wfront, m.const.BUGGY_Z))
        m.buggy.state = m.const.BUGGY_DRIVE
        m.buggy.crashed = false
    else
        if m.buggy.yOff > 0 and m.moon.base <> invalid and m.moon.base.GetX() < 0
            print "going down from base"
            m.buggy.yOff--
            m.buggy.sprite.MoveOffset(0, 1)
            m.buggy.wheels[0].MoveOffset(0, 1)
            m.buggy.wheels[1].MoveOffset(0, 1)
            m.buggy.wheels[2].MoveOffset(0, 1)
        else if m.buggy.yOff = 0
            if m.buggy.x + m.moon.xOff >= 640
                if m.currentStage <> m.moon.stage.current
                    m.currentStage = m.moon.stage.current
                end if
            end if
            if m.buggy.state = m.const.BUGGY_DRIVE
                if m.buggy.cursors.jump
                    m.buggy.state = m.const.BUGGY_JUMP
                    m.buggy.frame = 0
                end if
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
                'Check hole collision
                objHit = m.buggy.wheels[2].CheckCollision()
                if objHit <> invalid and objHit.GetData() = "hole"
                    print "buggy front wheels fall into a hole!"
                    m.buggy.state = m.const.BUGGY_CRASH_FRONT
                    m.buggy.frame = 0
                else
                    objHit = m.buggy.wheels[0].CheckCollision()
                    if objHit <> invalid and objHit.GetData() = "hole"
                        print "buggy back wheels fall into a hole!"
                        m.buggy.state = m.const.BUGGY_CRASH_BACK
                        m.buggy.frame = 0
                    end if
                end if
            else if m.buggy.state = m.const.BUGGY_JUMP
                PlaySound("jump", false, 100)
                m.buggy.y += m.buggy.jump[m.buggy.frame].y
                m.buggy.sprite.MoveTo(m.buggy.x, m.buggy.y)
                wx = m.buggy.wheels[0].GetX()
                if m.settings.spriteMode = m.const.MODE_ARCADE
                    bwy = m.buggy.y + 24
                    fwy = m.buggy.y + 26
                else
                    bwy = m.buggy.y + 19
                    fwy = bwy
                end if
                m.buggy.wheels[0].MoveTo(wx, bwy)
                wx = m.buggy.wheels[1].GetX()
                m.buggy.wheels[1].MoveTo(wx, bwy)
                wx = m.buggy.wheels[2].GetX()
                m.buggy.wheels[2].MoveTo(wx, fwy)
                m.buggy.frame++
                if m.buggy.frame = m.buggy.jump.Count()
                    m.buggy.state = m.const.BUGGY_DRIVE
                end if
            else 'crash
                if m.buggy.frame = 0
                    StopAudio()
                    PlaySound("crash")
                    rgn = m.regions.sprites.Lookup("buggy-" + m.buggy.state.ToStr())
                    m.buggy.sprite.SetRegion(rgn)
                    if m.buggy.state = m.const.BUGGY_CRASH_FRONT
                        m.buggy.sprite.MoveOffset(32, 32)
                    else
                        m.buggy.sprite.MoveOffset(-32, 32)
                    end if
                    m.buggy.x = m.buggy.sprite.GetX()
                    m.buggy.y = m.buggy.sprite.GetY()
                    if m.settings.spriteMode = m.const.MODE_ARCADE
                        m.buggy.wheels[0].Remove()
                        m.buggy.wheels[1].Remove()
                        m.buggy.wheels[2].Remove()
                    else
                        m.buggy.loose.frame = 0
                        off = m.buggy.loose.anim[0]
                        m.buggy.wheels[0].MoveOffset(-abs(off), off)
                        m.buggy.wheels[1].MoveOffset(0, off)
                        m.buggy.wheels[2].MoveOffset(Abs(off), off)
                    end if
                else if m.buggy.frame >= 5
                    ex = m.buggy.frame - 5
                    if ex < m.buggy.explode.Count()
                        id = m.buggy.explode[ex].id.ToStr()
                        rgn = m.regions.sprites.Lookup("explosion-" + id)
                        x = m.buggy.x + Int((80 - rgn.GetWidth()) / 2)
                        y = m.buggy.y + Int((32 - rgn.GetHeight()) / 2) + 16
                        m.buggy.sprite.SetRegion(rgn)
                        m.buggy.sprite.MoveTo(x, y)
                    else
                        m.buggy.crashed = true
                    end if
                end if
                if m.buggy.loose.frame <> invalid
                    m.buggy.loose.frame++
                    if m.buggy.loose.frame < m.buggy.loose.anim.Count()
                        off = m.buggy.loose.anim[m.buggy.loose.frame]
                        m.buggy.wheels[0].MoveOffset(-abs(off), off)
                        m.buggy.wheels[1].MoveOffset(0, off)
                        m.buggy.wheels[2].MoveOffset(Abs(off) + Int(m.buggy.loose.frame / 10), off)
                    end if
                end if
                m.buggy.frame++
            end if
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

Sub GameOver()
    text = "GAME OVER"
    textWidth = m.gameFont.GetOneLineWidth(text, m.gameWidth)
    textHeight = m.gameFont.GetOneLineHeight()
    x = Cint((m.gameWidth - textWidth) / 2)
    y = 308
    m.gameScreen.DrawRect(x - 32, y - 32, textWidth + 64, textHeight + 64, m.colors.black)
    m.gameScreen.DrawText(text, x, y, m.colors.white, m.gameFont)
    m.mainScreen.SwapBuffers()
    Sleep(3000)
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
