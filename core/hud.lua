local composer   = require("composer")
local anim       = require("core.animations")
local particles  = require("core.particles")

-- Class
local Hud = {}

-- Locals
local forcePlayerMoveY = -2
local movePlayerX      = nil
local movePlayerY      = nil
local movePlayerAllow  = false
local movePlayerSpeedX = 0
local movePlayerSppedY = 0
local aimPlayerAllow   = false
local aimPlayerX       = nil
local aimPlayerY       = nil

local moveControllerX  = 0
local moveControllerY  = 0
local shootControllerX = 0
local shootControllerY = 0
local lastTime         = 0

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
    elseif event.phase == "moved" and movePlayerAllow then
        -- NOTE: as we have to keep the player moving while the touch is in progress, even if their finger does not move,
        -- All we do in this event is update the x and y
        -- The Hud:checkEventMove() called by Hud:eventUpdateFrame() does the actual moving
        movePlayerX     = event.x
        movePlayerY     = event.y
    elseif event.phase == "ended" or event.phase == "cancelled" then
        display.getCurrentStage():setFocus(event.target, nil)
        movePlayerAllow = false
    end
    return true
end


local function eventShootPlayer(event)
    if event.phase == "began" then
        display.getCurrentStage():setFocus(event.target, event.id)
        aimPlayerAllow = Hud.player:canAim()
        aimPlayerX     = event.x
        aimPlayerY     = event.y
    elseif event.phase == "moved" and aimPlayerAllow then
        aimPlayerX     = event.x
        aimPlayerY     = event.y
    elseif event.phase == "ended" or event.phase == "cancelled" then
        display.getCurrentStage():setFocus(event.target, nil)
        aimPlayerAllow = false
    end
    return true
end


local function eventShootPlayerTap(event)
    if Hud.player:canAim() then
        local angle = 90 + atan2(event.y - Hud.controlShoot.y, event.x - Hud.controlShoot.x) * PI

        Hud.player:rotate(angle)
        Hud.player:shoot(Hud.camera)
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

function Hud:create(camera, player, pauseGameHandler, resumeGameHandler)
    self.camera            = camera
    self.player            = player
    self.pauseGameHandler  = pauseGameHandler
    self.resumeGameHandler = resumeGameHandler
    self.group             = display.newGroup()
    
    self.debugMode         = false
    self.physicsMode       = false

    self.background        = display.newRect(self.group, globalCenterX, globalCenterY, globalWidth, globalHeight)
    self.playerIcon        = draw:newImage(self.group, "hud/pause", 45, 45, 0.5)
    self.textScore         = draw:newText(self.group,  "", globalWidth-5, 25, 0.7, "green", "RIGHT")
    self.controlMove       = draw:newImage(self.group, "hud/control-move",  100,             globalHeight-110, nil, 0.7)
    self.controlShoot      = draw:newImage(self.group, "hud/control-shoot", globalWidth-100, globalHeight-130, nil, 0.7)
    self.healthCounter     = display.newRoundedRect(self.group, globalCenterX, globalHeight-100, 200, 50, 10)
    self.ammoCounter       = draw:newText(self.group,  player.weapon.ammo,  globalWidth-100, globalHeight-40,  0.8, "red")

    self.background:setFillColor(0.5, 0.2, 0.5, 0.2)
    self.playerIcon:scale(4, 4)
    self.healthCounter:setFillColor(0.5,   1,   0.5, 0.5)
    self.healthCounter:setStrokeColor(0.2, 0.5, 0.2, 0.9)
    self.healthCounter.strokeWidth    = 3
    self.healthCounter.originalWidth  = self.healthCounter.width
    self.healthCounter.widthPerHealth = self.healthCounter.width / player.health

    -- assign shortcuts variables
    movePlayerSpeedX, movePlayerSpeedY = player.strafeSpeed,  player.verticalSpeed
    moveControllerX,  moveControllerY  = self.controlMove.x,  self.controlMove.y
    shootControllerX, shootControllerY = self.controlShoot.x, self.controlShoot.y + (self.controlShoot.height/2)

    self.playerIcon:addEventListener("tap",     self.eventPauseGame)
    self.controlMove:addEventListener("touch",  eventMovePlayer)
    self.controlShoot:addEventListener("touch", eventShootPlayer)
    self.controlShoot:addEventListener("tap",   eventShootPlayerTap)

    if globalDebugGame then
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
        
        self.textDebugMode:addEventListener("tap",   self.switchDebugMode)
        self.textPhysicsMode:addEventListener("tap", self.switchPhysicsMode)
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
    self.playerIcon         = nil
    self.textScore          = nil
    self.ammoCounter        = nil
end


function Hud:switchDebugMode()
    local self = Hud
    self.debugMode = not self.debugMode
    
    if self.debugMode then
        self.textDebugMode:setText("debug mode")
        self.debugGroup = display.newGroup()

        -- loop through elements to add debug info here ...
        
        self.camera:add(self.debugGroup, 2, false)
    else
        self.textDebugMode:setText("game mode")
        self.camera:remove(self.debugGroup)
        
        if self.debugPoint ~= nil then
            self.debugPoint:removeSelf()
            self.debugPointInfo:removeSelf()
            self.debugPoint = nil
            self.debugPointInfo = nil
        end
        
        if self.debugGroup ~= nil then
            self.debugGroup:removeSelf()
            self.debugGroup = nil
        end

        -- loop through elements to clear debug info
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
    local player = self.player

    if movePlayerAllow then
        -- before moving player, check if any force has been applied and cancel it
        player:stopMomentum()

        local angle = atan2(moveControllerY - movePlayerY, moveControllerX - movePlayerX) * PI
        local dx    = movePlayerSpeedX * -cos(rad(angle))
        local dy    = movePlayerSpeedY * -sin(rad(angle))

        player:moveBy(dx, dy)
        --self.player.legs:loop("strafe_left")
    end

    if aimPlayerAllow then
        local angle = 90 + atan2(aimPlayerY - shootControllerY, aimPlayerX - shootControllerX) * PI
        
        player:rotate(angle, event)
        player:shoot(self.camera)
        self.camera:setAngleOffset(angle)
    end

    player:moveBy(0, forcePlayerMoveY)

    if player.shieldEntity then
        player.shieldEntity:moveTo(player:x(), player:y())
    end

    if player:hasLaserSight() then
        player:drawLaserSight()
    end
end


function Hud:updateDebugData()
    self.debugSizeEntites:setText("size: "..level:getSizeEntities())
    self.debugNumEntites:setText("entities: "..level:getNumberEntities())
    self.debugNumEnemies:setText("enemies: "..level:getNumberEnemies())
    self.debugNumObstacles:setText("obstacles: "..level:getNumberObstacles())
    self.debugNumCollectables:setText("collect: "..level:getNumberCollectables())
    self.debugNumProjectiles:setText("shots: "..level:getNumberProjectiles())
    self.debugNumParticles:setText("particles: "..level:getNumberParticles())
    self.debugSection:setText("section: "..self.player.currentSection)
    self.debugYPos:setText("ypos: "..round(self.player:y()))
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


function Hud:displayGameOver()
    self = Hud

    if globalGameMode == GameMode.over then
        local group      = self.group
        local distance   = stats:getDistance()
        local mins, secs = stats:getTime()

        draw:newBlocker(group, 0.9, 0,0,0)
        draw:newText(group, "game over", globalCenterX, 50, 1, "white")
        self:createButtonReplay(group, globalCenterX, globalHeight-50)

        local pointsLabel   = draw:newText(group, "score:",    300, 150, 0.6, "grey", "RIGHT")
        local pointsValue   = draw:newText(group, stats.points, 330, 150, 0.6, "green", "LEFT")

        local timeLabel     = draw:newText(group, "survived:",  300, 200, 0.6, "grey", "RIGHT")
        local minValue      = draw:newText(group, mins,         330, 200, 0.6, "aqua", "LEFT")
        local minUnit       = draw:newText(group, "mins",       minValue.x + minValue.width - 20, 205, 0.3, "aqua", "LEFT")
        local secValue      = draw:newText(group, secs,         minUnit.x  + minUnit.width  - 95, 200, 0.6, "aqua", "LEFT")
        local secUnit       = draw:newText(group, "secs",       secValue.x + secValue.width - 20, 205, 0.3, "aqua", "LEFT")

        local distanceLabel = draw:newText(group, "distance:",  300, 250, 0.6, "grey", "RIGHT")
        local distanceValue = draw:newText(group, distance,     330, 250, 0.6, "yellow", "LEFT")
        local distanceUnit  = draw:newText(group, "metres",     distanceValue.x + distanceValue.width - 20, 255, 0.3, "yellow", "LEFT")

        local weaponTitles  = draw:newText(group, "shots  accuracy  kills", 250, 350, 0.4, "grey", "LEFT")

        self:displayWeaponStats(group, Weapons.rifle.name,    400)
        self:displayWeaponStats(group, Weapons.shotgun.name,  450)
        self:displayWeaponStats(group, Weapons.launcher.name, 500)
        self:displayWeaponStats(group, Weapons.laserGun.name, 550)

        self.gameOverSprites = {}

        self:displayMeleeEnemiesKilled(group,   self.gameOverSprites, 660)
        self:displayShooterEnemiesKilled(group, self.gameOverSprites, 660)

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
    local enemy = self:createSpineEnemy(enemyType, rank)

    enemy:moveTo(xpos, ypos)

    after(random(10)*100, function()
        enemies[#enemies+1] = enemy
    end)

    local kills = stats.enemies[enemyType][rank]

    if kills > 0 then
        draw:newText(group, kills, xpos+30, ypos, 0.45, "red", "LEFT")
    else
        enemy:visible(0.2)
    end
end


function Hud:createSpineEnemy(enemyType, rank)
    local spec   = EnemyTypes[enemyType][rank]
    local weapon = Weapons[spec.weapon]
    local enemy  = builder:newCharacter({}, {jsonName="characterBody", imagePath="character", skin=spec.skin, animation="stationary_1"})

    enemy.skeleton:setAttachment(weapon.slot, weapon.skin)
    enemy.image:scale(0.5, 0.5)

    return enemy
end


return Hud