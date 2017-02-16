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
Library "v30/bslDefender.brs"

Sub Main()
    'Constants
    m.code = bslUniversalControlEventCodes()
    m.const = GetConstants()
    m.colors = {black: &hFF, white: &hFFFFFFFF, darkgray: &h0F0F0FFF, red: &hFF0000FF, green: &h00FF00FF, blue: &h0000FFFF, cyan: &h00FFFFFF, yellow: &hFFD800FF}
    'Util objects
    app = CreateObject("roAppManager")
    app.SetTheme(GetTheme())
    m.port = CreateObject("roMessagePort")
    m.clock = CreateObject("roTimespan")
    m.audioPlayer = CreateObject("roAudioPlayer")
    m.audioPort = CreateObject("roMessagePort")
    m.audioPlayer.SetMessagePort(m.audioPort)
    m.sounds = LoadSounds(false)
    m.fonts = CreateObject("roFontRegistry")
    m.fonts.Register("pkg:/assets/fonts/PressStart2P.ttf")
    m.gameFont = m.fonts.getFont("Press Start 2P", 16, false, false)
    m.manifest = GetManifestArray()
    m.settings = LoadSettings()
    m.isOpenGL = isOpenGL()
    m.speed = m.const.GAME_SPEED
    selection = m.const.MENU_START
    SetupGameScreen()
    'Main Menu Loop
    while true
        selection = StartMenu(selection)
        if selection = m.const.MENU_START
            print "Starting game..."
            m.gameScore = 0
            m.highScore = m.settings.highScores[0].score
            m.currentLevel = 1
            m.currentStage = 1
            LoadGameSprites()
            ResetGame()
            GameLogo(5000)
            PlayGame()
        else if selection = m.const.MENU_HISCORES
            'ShowHighScores()
        else if selection = m.const.MENU_CREDITS
            ShowCredits()
        end if
    end while
End Sub

Sub GameLogo(waitTime as integer)
    Sleep(500) ' Give time to Roku clear list screen from memory
    ticks = m.clock.TotalMilliseconds()
    m.mainScreen.Clear(m.colors.black)
    m.mainScreen.SwapBuffers()
    if m.moon = invalid then m.moon = {}
    rgn = m.regions.Lookup("game-logo")
    m.moon.top = m.compositor.NewSprite(0, 0, rgn, m.const.LAYER2_Z)
    DrawMoon()
    m.compositor.AnimationTick(ticks)
    m.compositor.DrawAll()
    m.mainScreen.SwapBuffers()
	while true
    	key = wait(waitTime, m.port)
		if key = invalid or key < 100 then exit while
	end while
End Sub

Sub ResetGame()
    g = GetGlobalAA()
    print "Reseting Stage "; itostr(g.currentStage)
    if g.moon = invalid then g.moon = {}
    if g.moon.layers <> invalid then DestroyMoon()
    'Update moon landscape
    if g.moon.landscape = g.const.MOON_MOUNTAIN
        g.moon.landscape = g.const.MOON_CITY
    else
        g.moon.landscape = g.const.MOON_MOUNTAIN
    end if
    'Create Buggy
    'if g.buggy = invalid then g.buggy = CreateBuggy()
    m.startup = true
    StopAudio()
    StopSound()
End Sub

Sub LoadGameSprites()
    if m.regions = invalid then m.regions = {}
    path = "pkg:/assets/images/"
    if m.settings.spriteMode = m.const.MODE_ARCADE
        path += "arcade/"
    else
        path += "atari/"
    end if
    m.regions.AddReplace("game-logo", GetRegion(path + "game-logo.png"))
    m.regions.AddReplace("score-board", GetRegion(path + "score-board.png"))
    m.regions.AddReplace("back-mountain", GetRegion(path + "back-mountain.png", true))
    m.regions.AddReplace("front-mountain", GetRegion(path + "front-mountain.png", true))
    m.regions.AddReplace("front-city", GetRegion(path + "front-city.png", true))
    m.regions.AddReplace("ground-level", GetRegion(path + "ground-level.png", true))
End Sub

Sub SetupGameScreen()
	if IsHD()
		m.mainWidth = 854
		m.mainHeight = 480
	else
		m.mainWidth = 640
		m.mainHeight = 480
	end if
    m.gameWidth = 640
    m.gameHeight = 480
    ResetScreen(m.mainWidth, m.mainHeight, m.gameWidth, m.gameHeight)
End Sub

Sub ResetScreen(mainWidth as integer, mainHeight as integer, gameWidth as integer, gameHeight as integer)
    g = GetGlobalAA()
    g.mainScreen = CreateObject("roScreen", true, mainWidth, mainHeight)
    g.mainScreen.SetMessagePort(g.port)
    xOff = Cint((mainWidth-gameWidth) / 2)
    drwRegions = dfSetupDisplayRegions(g.mainScreen, xOff, 0, gameWidth, gameHeight)
    g.gameScreen = drwRegions.main
    g.gameScreen.SetAlphaEnable(true)
    g.compositor = CreateObject("roCompositor")
    g.compositor.SetDrawTo(g.gameScreen, g.colors.black)
End Sub

Function GetTheme() as object
    theme = {
            BackgroundColor: "#000000",
            OverhangSliceSD: "pkg:/images/overhang_sd.jpg",
            OverhangSliceHD: "pkg:/images/overhang_hd.jpg",
            ListScreenHeaderText: "#FFFFFF",
            ListScreenDescriptionText: "#FFFFFF",
            ListItemHighlightText: "#FFD801"
            }
    return theme
End Function
