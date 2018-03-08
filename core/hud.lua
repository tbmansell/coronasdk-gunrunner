local composer   = require("composer")
local anim       = require("core.animations")
local particles  = require("core.particles")

-- Class
local Hud = {}

-- Locals
local localPlayer      = nil
local forcePlayerMoveY = -2
local movePlayerX      = nil
local movePlayerY      = nil
local movePlayerAllow  = false
local movePlayerSpeedX = 0
local movePlayerSppedY = 0
local aimPlayerAllow   = false
local aimPlayerX       = nil
local aimPlayerY       = nil
local forceScroll      = true

local moveControllerX  = 0
local moveControllerY  = 0
local shootControllerX = 0
local shootControllerY = 0
local lastTime         = 0
local resetAimHandle   = nil
local resettingAim     = false
local transitionMapType= false

-- Aliases
local PI     = 180 / math.pi
local abs    = math.abs
local cos    = math.cos
local sin    = math.sin
local rad    = math.rad
local atan2  = math.atan2
local random = math.random
local round  = math.round

-- Local Event Handlers

local function eventMovePlayer(event)
    if event.phase == "began" then
        display.getCurrentStage():setFocus(event.target, event.id)
        movePlayerAllow = Hud.player:canMove()
        movePlayerX     = event.x
        movePlayerY     = event.y

        player.hudMovement = true

    elseif event.phase == "moved" and movePlayerAllow then
        -- NOTE: as we have to keep the player moving while the touch is in progress, even if their finger does not move,
        -- All we do in this event is update the x and y
        -- The Hud:checkEventMove() called by Hud:eventUpdateFrame() does the actual moving
        movePlayerX     = event.x
        movePlayerY     = event.y
    elseif event.phase == "ended" or event.phase == "cancelled" then
        display.getCurrentStage():setFocus(event.target, nil)
        movePlayerAllow = false

        player.hudMovement = false
        player:updateLegs("run")
    end
    return true
end


local function eventShootPlayer(event)
    aimPlayerAllow = Hud.player:canAim()

    if event.phase == "began" then
        Hud:clearResetAim()
        display.getCurrentStage():setFocus(event.target, event.id)
        aimPlayerX     = event.x
        aimPlayerY     = event.y
    elseif event.phase == "moved" and aimPlayerAllow then
        aimPlayerX     = event.x
        aimPlayerY     = event.y
    elseif event.phase == "ended" or event.phase == "cancelled" then
        display.getCurrentStage():setFocus(event.target, nil)
        aimPlayerAllow = false
        Hud:resetAim()
    end
    return true
end


local function eventShootPlayerTap(event)
    if Hud.player:canAim() then
        local angle = 90 + atan2(event.y - Hud.controlShoot.y, event.x - Hud.controlShoot.x) * PI

        Hud.player:rotate(angle)
        Hud.player:shoot(Hud.camera)
        Hud:resetAim()
    end
end


-- Triggered only when game over occurs
local function eventUpdateFrameGameOver(event)
    if Hud.gameOverSprites then
        local currentTime = event.time / 1000
        local delta       = currentTime - lastTime
        lastTime          = currentTime

        for _,item in pairs(Hud.gameOverSprites) do
            item:updateSpine(delta)
        end
    end
end



-- Class Members

function Hud:create(camera, player, pauseGameHandler, resumeGameHandler, changeMusicHandler, loadLevelHandler)
    self.camera            = camera
    self.player            = player
    self.pauseGameHandler  = pauseGameHandler
    self.resumeGameHandler = resumeGameHandler
    self.changeMusicHandler= changeMusicHandler
    self.loadLevelHandler  = loadLevelHandler
    self.group             = display.newGroup()
    
    self.debugMode         = false
    self.physicsMode       = false

    self.playerIcon        = draw:newImage(self.group, "hud/pause", 45, 45, 0.5)
    self.textScore         = draw:newText(self.group,  "", globalWidth-5, 25, 0.7, "green", "RIGHT")
    self.controlMove       = draw:newImage(self.group, "hud/control-move",  100,             globalHeight-110, nil, 0.7)
    self.controlShoot      = draw:newImage(self.group, "hud/control-shoot", globalWidth-100, globalHeight-130, nil, 0.7)
    self.healthCounter     = display.newRoundedRect(self.group, globalCenterX, globalHeight-100, 200, 50, 10)
    self.ammoCounter       = draw:newText(self.group,  player.weapon.ammo,  globalWidth-100, globalHeight-40,  0.8, "red")

    self.playerIcon:scale(4, 4)
    self.healthCounter:setFillColor(0.5,   1,   0.5, 0.5)
    self.healthCounter:setStrokeColor(0.2, 0.5, 0.2, 0.9)
    self.healthCounter.strokeWidth    = 3
    self.healthCounter.originalWidth  = self.healthCounter.width
    self.healthCounter.widthPerHealth = self.healthCounter.width / player.health

    -- assign shortcuts variables
    localPlayer = player
    forceScroll = true
    movePlayerSpeedX, movePlayerSpeedY = player.strafeSpeed,  player.verticalSpeed
    moveControllerX,  moveControllerY  = self.controlMove.x,  self.controlMove.y
    shootControllerX, shootControllerY = self.controlShoot.x, self.controlShoot.y + (self.controlShoot.height/2)

    self.playerIcon:addEventListener("tap",     self.eventPauseGame)
    self.controlMove:addEventListener("touch",  eventMovePlayer)
    self.controlShoot:addEventListener("touch", eventShootPlayer)
    self.controlShoot:addEventListener("tap",   eventShootPlayerTap)

    self:drawDebug()
end


function Hud:drawDebug()
    self.debugPanel = display.newGroup()
    self.group:insert(self.debugPanel)

    local panelBack = display.newRect(self.debugPanel, 0, 200, 350, globalHeight)
    panelBack:setFillColor(0.3, 0.3, 0.3, 0.6)

    self.textDebugMode        = draw:newText(self.debugPanel, "game mode",    5, 100, 0.4, "green", "LEFT")
    self.textPhysicsMode      = draw:newText(self.debugPanel, "hide physics", 5, 140, 0.4, "blue",  "LEFT")
    self.debugSizeEntites     = draw:newText(self.debugPanel, "",   5, 180, 0.4, "aqua",  "LEFT")
    self.debugNumEntites      = draw:newText(self.debugPanel, "",   5, 220, 0.4, "white", "LEFT")
    self.debugNumEnemies      = draw:newText(self.debugPanel, "",   5, 260, 0.4, "white", "LEFT")
    self.debugNumObstacles    = draw:newText(self.debugPanel, "",   5, 300, 0.4, "white", "LEFT")
    self.debugNumCollectables = draw:newText(self.debugPanel, "",   5, 340, 0.4, "white", "LEFT")
    self.debugNumProjectiles  = draw:newText(self.debugPanel, "",   5, 380, 0.4, "white", "LEFT")
    self.debugNumParticles    = draw:newText(self.debugPanel, "",   5, 420, 0.4, "white", "LEFT")
    self.debugSection         = draw:newText(self.debugPanel, "",   5, 460, 0.4, "white", "LEFT")
    self.debugYPos            = draw:newText(self.debugPanel, "",   5, 500, 0.4, "white", "LEFT")
    self.debugCustomMap       = draw:newText(self.debugPanel, "",   5, 540, 0.4, "white", "LEFT")
    self.debugSectionEnemies  = draw:newText(self.debugPanel, "",   5, 580, 0.4, "white", "LEFT")
    
    self.textDebugMode:addEventListener("tap",   self.switchDebugMode)
    self.textPhysicsMode:addEventListener("tap", self.switchPhysicsMode)
    
    if globalDebugGame == false then
        self.debugPanel.alpha = 0
    end
end


function Hud:destroy()
    Runtime:removeEventListener("enterFrame", eventUpdateFrameGameOver)

    if self.pauseMenu then 
        self.pauseMenu:removeSelf()
        self.pauseMenu = nil 
    end

    if self.splash then
        self.splash:removeSelf()
        self.splash = nil
    end

    if self.gameOverSprites then
        for _,item in pairs(self.gameOverSprites) do
            item:destroy()
            item = nil
        end
        self.gameOverSprites = nil
    end

    self.group:removeSelf()
    self.group              = nil
    self.pauseGameHandler   = nil
    self.resumeGameHandler  = nil
    self.camera             = nil
    self.player             = nil
    localPlayer             = nil
    self.playerIcon         = nil
    self.textScore          = nil
    self.ammoCounter        = nil
end


function Hud:switchDebugMode()
    local self = Hud
    self.debugMode = not self.debugMode

    if self.debugMode then
        self.textDebugMode:setText("debug mode")
        level:debugInfo(1)
    else
        self.textDebugMode:setText("game mode")
        level:debugInfo(0)
    end
end


function Hud:switchPhysicsMode()
    local self = Hud
    self.physicsMode = not self.physicsMode

    if self.physicsMode then
        physics.setDrawMode("hybrid")
        self.textPhysicsMode:setText("show physics")
    else
        physics.setDrawMode("normal")
        self.textPhysicsMode:setText("hide physics")
    end
end


function Hud:eventPauseGame()
    self = Hud

    if globalGameMode == GameMode.playing then
        self.pauseGameHandler()

        self.pauseMenu = display.newGroup()
        draw:newBlocker(self.pauseMenu, 0.8, 0,0,0, self.eventResumeGame, "block")
        
        local heading = draw:newText(self.pauseMenu, "game paused", globalCenterX, 100, 0.1, "white")
        local info    = draw:newText(self.pauseMenu, "(tap background to resume)", globalCenterX, 400, 0.5, "green", "CENTER")
        local debug   = draw:newImage(self.pauseMenu, "hud/settings", globalCenterX, 600)

        heading.alpha = 0

        debug:addEventListener("tap", function()
            globalDebugGame = not globalDebugGame
            
            draw:toggleDebugPerformance()
    
            if globalDebugGame then
                self.debugPanel.alpha = 1
            else
                self.debugPanel.alpha = 0
            end
        
            return true
        end)

        local seq = anim:chainSeq("pauseMenu", heading)
        seq:tran({time=150, scale=1.5, alpha=1})
        seq:add("pulse", {time=2000, scale=0.03})
        seq:start()

        self:createButtonReplay(self.pauseMenu, globalCenterX, 270)
    end
    return true
end


function Hud:eventResumeGame()
    self = Hud

    if self.pauseMenu then
        self.pauseMenu:removeSelf()
        self.pauseMenu = nil
    end

    self.resumeGameHandler(nil, gameState)

    return true
end


function Hud:eventUpdateFrame(event)
    if movePlayerAllow then
        self:updateFrameUserMovement(event)
    end

    if resettingAim then
        -- allow camera to follow player transition
        self.camera:setAngleOffset(localPlayer.angle)
    elseif aimPlayerAllow then
        self:updateFrameShooting(event)
    end

    if forceScroll then
        localPlayer:moveBy(0, forcePlayerMoveY)

        -- It's possible to be moving when in stationary animation. This fixes that for vertical movement
        if not movePlayerAllow and localPlayer:verticalMovement() > 8 and localPlayer.legAnimation == "stationary" then
            localPlayer:updateLegs("run_slow")
        end
    end

    if localPlayer.shieldEntity then
        localPlayer.shieldEntity:moveTo(localPlayer:x(), localPlayer:y())
    end

    if localPlayer.laserSightEntity then
        localPlayer:drawLaserSight()
    end

    if localPlayer.flameShot then
        localPlayer.flameShot:moveTo(localPlayer:x() + localPlayer.boneBarrel.worldX, localPlayer:y() - localPlayer.boneBarrel.worldY)
        localPlayer.flameShot:rotate(localPlayer.angle-180)
    end
end


function Hud:updateFrameUserMovement(event)
    local moveY  = moveControllerY - movePlayerY
    local speedY = movePlayerSpeedY

    -- If player is moving backward, we have to counteract the forceMove value if in effect
    if forceScroll and moveY < 0 then
        speedY = speedY - forcePlayerMoveY
    end

    local angle = atan2(moveY, moveControllerX - movePlayerX) * PI
    local dx    = movePlayerSpeedX * -cos(rad(angle))
    local dy    = speedY * -sin(rad(angle))
    local legs  = "run"

    localPlayer:stopMomentum()
    localPlayer:moveBy(dx, dy)

    if forceScroll then
        if localPlayer:verticalMovement() <= 0 or dy > 0 then
            legs = "run_slow"
        elseif dy < 0 then
            legs = "run_fast"
        end
    end

    if legs ~= localPlayer.legAnimation then
        localPlayer:loopLegs(legs)
    end
end


function Hud:updateFrameShooting(event)
    local angle = 90 + atan2(aimPlayerY - shootControllerY, aimPlayerX - shootControllerX) * PI
    
    localPlayer:rotate(angle, event)
    localPlayer:shoot(self.camera)
    self.camera:setAngleOffset(angle)
end


function Hud:resetAim()
    self:clearResetAim()
    resetAimHandle = transition.to(self.player, {angle=0, time=1000, delay=4000, 
                                                onStart=function() resettingAim=true end, 
                                                onComplete=function() resettingAim=false; resetAimHandle=nil end})
end


function Hud:clearResetAim()
    if resetAimHandle then 
        transition.cancel(resetAimHandle)
        resetAimHandle = nil
        resettingAim   = false
    end
end


function Hud:updateMapSection()
    if not transitionMapType then
        if localPlayer.currentSection.isCustom then
            self:handleCustomMapTransition()

        elseif localPlayer.currentSection.isLast then
            transitionMapType = true
            self.player:completedCallback() 
        end
    end
end


function Hud:handleCustomMapTransition()
    local enemies = level:getNumberEnemies(localPlayer.currentSection.number)
    
    if forceScroll and enemies > 0 then
        transitionMapType = true
        self.changeMusicHandler(nil, sounds.music.customScene)
        sounds:voice("getReady")
        after(1000, function() sounds:voice("fight") end)

        after(1000, function() 
            transitionMapType = false
            self:forceMoving(false)
        end)

    elseif not forceScroll and enemies == 0 then
        transitionMapType = true

        self.loadLevelHandler(nil, localPlayer.currentSection.number + 2)
        self.changeMusicHandler(nil, sounds.music.rollingGame, 20000)

        localPlayer.currentSection.securityDoorExit:open()
        
        sounds:general("mapComplete")

        after(2000, function()
            transitionMapType = false
            self:forceMoving(true)
            localPlayer:loopLegs("run")
        end)
    end
end


function Hud:updateDebugData()
    local section        = self.player.currentSection
    local sectionEnemies = level:getNumberEnemies(section.number)

    self.debugSizeEntites:setText("size: "..level:getSizeEntities())
    self.debugNumEntites:setText("entities: "..level:getNumberEntities())
    self.debugNumEnemies:setText("enemies: "..level:getNumberEnemies())
    self.debugNumObstacles:setText("obstacles: "..level:getNumberObstacles())
    self.debugNumCollectables:setText("collect: "..level:getNumberCollectables())
    self.debugNumProjectiles:setText("shots: "..level:getNumberProjectiles())
    self.debugNumParticles:setText("particles: "..level:getNumberParticles())
    self.debugSection:setText("section: "..section.number)
    self.debugYPos:setText("ypos: "..round(self.player:y()))
    self.debugCustomMap:setText("custom: "..tostring(section.isCustom))
    self.debugSectionEnemies:setText("enemies at: "..sectionEnemies)
end


function Hud:updateSpeed(player)
    movePlayerSpeedX, movePlayerSpeedY = player.strafeSpeed,  player.verticalSpeed

    if player:hasFastMove() then
        forcePlayerMoveY = -3
    else
        forcePlayerMoveY = -2
    end
end


function Hud:updateHealth(player)
    if player.health <= 0 then
        self.healthCounter.alpha = 0
    else
        self.healthCounter.width = self.healthCounter.widthPerHealth * player.health
    end
end


function Hud:forceMoving(move)
    forceScroll = move
end


function Hud:collect(item)
    item:emit("collected")
    item:collect(self.camera)
end


function Hud:updatePoints()
    self.textScore:setText(stats.points)
end


function Hud:setAmmoCounter(number)
    if self.ammoCounter then
        self.ammoCounter:setText(number or "0")
    end
end


function Hud:displayMessage(message, color, ypos)
    color = color or "purple"
    ypos  = ypos  or globalCenterY

    local text = draw:newText(self.group, message, globalCenterX, ypos, 0.8, color, "CENTER")
    local seq  = anim:oustSeq("levelMessage", text, true)
    seq:add("pulse", {time=1000, scale=0.025, expires=3000})
    seq:tran({time=750, scale=0.1, alpha=0})
    seq:start()
end


function Hud:showTutorialSplash()
    self.splash = display.newImage("images/message-tabs/tutorial-splash.png", globalCenterX-50, globalCenterY)

    -- block touch event
    self.splash:addEventListener("touch", function() return true end)

    self.splash:addEventListener("tap", function()
        self.splash:removeSelf()
        self.splash = nil
    end)
end


function Hud:animateScoreText(scoreadd, scoreCategory, textX, textY)
    local color = "white"
    if     scoreCategory == scoreCategoryFirst  then color = "green"
    elseif scoreCategory == scoreCategorySecond then color = "yellow"
    elseif scoreCategory == scoreCategoryThird  then color = "red" end

    local textScore = draw:newText(nil, scoreadd, textX, textY+15, 1, color, "CENTER")
    
    textScore.alpha = 0
    self.camera:add(textScore, 2)
    
    local seq = anim:chainSeq("jumpScore", textScore, true)
    seq:tran({time=250, alpha=1,  xScale=1.25, yScale=1.25})
    seq:tran({time=750, delay=500, x=hud.textScore.x, y=hud.textScore.y, xScale=0.5, yScale=0.5, transition=easing.inQuad})
    seq:callback(function() hud:addJumpScore(scoreadd) end)
    seq:start()
end


function Hud:createButtonExit(group, x, y)
    return draw:newButton(group, x, y, "menu", function() composer.gotoScene("scenes.game") end)
end


function Hud:createButtonReplay(group, x, y)
    return draw:newButton(group, x, y, "replay", function() composer.gotoScene("scenes.game") end)
end


function Hud:createButtonNext(group, x, y)
    return draw:newButton(group, x, y, "next", function() composer.gotoScene("scenes.game") end)
end


function Hud:startLevelSequence(level, player)
end


function Hud:displayGameOver(completed)
    self = Hud

    if globalGameMode == GameMode.over then
        local group      = self.group
        local distance   = stats:getDistance()
        local mins, secs = stats:getTime()

        --draw:newBlocker(group, 0.9, 0,0,0)
        draw:newBlocker(group, 0, 0,0,0)
        draw:newImage(group, "summaryScreen", globalCenterX, globalCenterY)
        self:createButtonReplay(group, globalCenterX, globalCenterY+250)

        local score  = display.newText({parent=group, text=stats.points, x=350, y=635, fontSize=32, font="arial", align="left"})

        --[[if completed then
            draw:newText(group, "well done!",                   globalCenterX, 50,  1, "yellow")
            draw:newText(group, "you have completed the game!", globalCenterX, 100, 0.7, "green")
        else
            draw:newText(group, "game over", globalCenterX, 50, 1, "white")
        end]]

        --local pointsLabel   = draw:newText(group, "score:",    300, 150, 0.6, "grey", "RIGHT")
        --local pointsValue   = draw:newText(group, stats.points, 330, 150, 0.6, "green", "LEFT")
        

        --local timeLabel     = draw:newText(group, "survived:",  300, 200, 0.6, "grey", "RIGHT")
        --local minValue      = draw:newText(group, mins,         330, 200, 0.6, "aqua", "LEFT")
        --local minUnit       = draw:newText(group, "mins",       minValue.x + minValue.width - 20, 205, 0.3, "aqua", "LEFT")
        --local secValue      = draw:newText(group, secs,         minUnit.x  + minUnit.width  - 95, 200, 0.6, "aqua", "LEFT")
        --local secUnit       = draw:newText(group, "secs",       secValue.x + secValue.width - 20, 205, 0.3, "aqua", "LEFT")

        --local distanceLabel = draw:newText(group, "distance:",  300, 250, 0.6, "grey", "RIGHT")
        --local distanceValue = draw:newText(group, distance,     330, 250, 0.6, "yellow", "LEFT")
        --local distanceUnit  = draw:newText(group, "metres",     distanceValue.x + distanceValue.width - 20, 255, 0.3, "yellow", "LEFT")
        --local weaponTitles  = draw:newText(group, "shots  accuracy  kills", 250, 350, 0.4, "grey", "LEFT")

        --self:displayWeaponStats(group, Weapons.rifle.name,    400)
        --self:displayWeaponStats(group, Weapons.shotgun.name,  450)
        --self:displayWeaponStats(group, Weapons.launcher.name, 500)
        --self:displayWeaponStats(group, Weapons.laserGun.name, 550)

        self.gameOverSprites = {}

        --self:displayMeleeEnemiesKilled(group,   self.gameOverSprites, 660)
        --self:displayShooterEnemiesKilled(group, self.gameOverSprites, 660)

        Runtime:addEventListener("enterFrame", eventUpdateFrameGameOver)
    end
end


function Hud:displayWeaponStats(group, weaponName, ypos)
    local weapon   = Weapons[weaponName]
    local stats    = stats.weapons[weaponName]
    local accuracy = math.round((stats.hits / stats.shots) * 100)

    local icon  = draw:newImage(group, "collectables/"..weapon.name, 150, ypos)
    local shots = draw:newText(group,  stats.shots,                  280, ypos, 0.4, "white",  "CENTER")
    local acc   = draw:newText(group,  accuracy.."%",                380, ypos, 0.4, "yellow", "CENTER")
    local kills = draw:newText(group,  stats.kills,                  480, ypos, 0.4, "red",    "CENTER")

    if stats.shots == 0 then
        icon.alpha = 0.2
        shots:setText("-")
        acc:setText("-")
        kills:setText("-")
    end
end


function Hud:displayMeleeEnemiesKilled(group, enemies, ypos)
    local xpos = 100

    for rank=1, 3 do
        self:displayEnemyKills(group, enemies, "melee", rank, xpos, ypos)

        ypos = ypos + 75
    end
end


function Hud:displayShooterEnemiesKilled(group, enemies, ypos)
    local xpos = 200

    for rank=1, 12 do
        self:displayEnemyKills(group, enemies, "shooter", rank, xpos, ypos)

        xpos = xpos + 100

        if rank % 4 == 0 then
            xpos = 200
            ypos = ypos + 75
        end
    end
end


function Hud:displayEnemyKills(group, enemies, enemyType, rank, xpos, ypos)
    --[[local enemy = self:createSpineEnemy(enemyType, rank)

    enemy:moveTo(xpos, ypos)

    after(random(10)*100, function()
        enemies[#enemies+1] = enemy
    end)

    local kills = stats.enemies[enemyType][rank]

    if kills > 0 then
        draw:newText(group, kills, xpos+30, ypos, 0.45, "red", "LEFT")
    else
        enemy:visible(0.2)
    end]]
end


function Hud:createSpineEnemy(enemyType, rank)
    --[[local spec   = EnemyTypes[enemyType][rank]
    local weapon = Weapons[spec.weapon]
    local enemy  = builder:newCharacter({}, {jsonName="characterBody", imagePath="character", skin=spec.skin, animation="stationary_1"})

    enemy.skeleton:setAttachment(weapon.slot, weapon.skin)
    enemy.image:scale(0.5, 0.5)

    return enemy]]
end


return Hud