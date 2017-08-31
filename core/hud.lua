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

-- Aliases
local PI    = 180 / math.pi
local abs   = math.abs
local cos   = math.cos
local sin   = math.sin
local rad   = math.rad
local atan2 = math.atan2

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



-- Class Members

function Hud:create(camera, player, pauseGameHandler, resumeGameHandler)
    self.camera            = camera
    self.player            = player
    self.pauseGameHandler  = pauseGameHandler
    self.resumeGameHandler = resumeGameHandler
    self.group             = display.newGroup()
    
    self.debugMode         = false
    self.physicsMode       = false
    self.time              = os.date('*t')
    self.score             = 0

    self.background        = display.newRect(self.group, globalCenterX, globalCenterY, globalWidth, globalHeight)
    self.playerIcon        = draw:newImage(self.group, "hud/player-icon", 45, 45, 0.5)
    self.textScore         = draw:newText(self.group,  self.score, globalWidth-5, 25, 0.7, "green", "RIGHT")
    self.controlMove       = draw:newImage(self.group, "hud/control-move",  100,             globalHeight-110, nil, 0.7)
    self.controlShoot      = draw:newImage(self.group, "hud/control-shoot", globalWidth-100, globalHeight-130, nil, 0.7)
    self.healthCounter     = display.newRoundedRect(self.group, globalCenterX, globalHeight-100, 200, 50, 10)
    self.ammoCounter       = draw:newText(self.group,  player.weapon.ammo,  globalWidth-100, globalHeight-40,  0.8, "red")

    self.background:setFillColor(0.5, 0.2, 0.5, 0.2)
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
    self.controlMove:addEventListener("tap",    self.eventJumpPlayer)
    self.controlShoot:addEventListener("touch", eventShootPlayer)
    self.controlShoot:addEventListener("tap",   eventShootPlayerTap)

    if globalDebugGame then
        self.textDebugMode   = draw:newText(self.group, "game mode",    globalCenterX, 25,  0.4, "green")
        self.textPhysicsMode = draw:newText(self.group, "hide physics", globalCenterX, 65,  0.4, "blue")

        self.textDebugMode:addEventListener("tap",   self.switchDebugMode)
        self.textPhysicsMode:addEventListener("tap", self.switchPhysicsMode)
    end
end


function Hud:destroy()
    if self.pauseMenu then 
        self.pauseMenu:removeSelf()
        self.pauseMenu = nil 
    end

    if self.splash then
        self.splash:removeSelf()
        self.splash = nil
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
        heading.alpha = 0

        local seq = anim:chainSeq("pauseMenu", heading)
        seq:tran({time=150, scale=1.5, alpha=1})
        seq:add("pulse", {time=2000, scale=0.03})
        seq:start()

        self:createButtonExit(self.pauseMenu,   globalCenterX-100, 230)
        self:createButtonReplay(self.pauseMenu, globalCenterX+100, 230)
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
        -- befor emoving player, check if any force has been applied and cancel it
        self.player:stopMomentum()

        local angle = atan2(moveControllerY - movePlayerY, moveControllerX - movePlayerX) * PI
        local dx    = movePlayerSpeedX * -cos(rad(angle))
        local dy    = movePlayerSpeedY * -sin(rad(angle))

        self.player:moveBy(dx, dy)

        --self.player.legs:loop("strafe_left")
    end

    if aimPlayerAllow then
        local angle = 90 + atan2(aimPlayerY - shootControllerY, aimPlayerX - shootControllerX) * PI
        
        self.player:rotate(angle, event)
        self.player:shoot(self.camera)
    end


    self.player:moveBy(0, forcePlayerMoveY)
end


function Hud:eventJumpPlayer(event)
    self = Hud

    if self.player:canJump() then

    end
end


function Hud:collect(item)
    item:emit("collected")
    item:collect(self.camera)
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
    return draw:newButton(group, x, y, "menu", function() hud:exitZone(); end)
end


function Hud:createButtonReplay(group, x, y)
    return draw:newButton(group, x, y, "replay", function() hud:replayLevel() end)
end


function Hud:createButtonShop(group, x, y)
    return draw:newButton(group, x, y, "shop", function() hud:exitToShop() end)
end


function Hud:createButtonSkipZone(group, x, y)
    return draw:newButton(group, x, y, "playvideo", function() hud:playVideoToSkipZone() end)
end


function Hud:createButtonPlayerSelect(group, x, y)
    return draw:newButton(group, x, y, "charselect", function() hud:exitToPlayerSelect() end)
end


function Hud:createButtonNext(group, x, y)
    return draw:newButton(group, x, y, "next", function() hud:nextLevel() end)
end


function Hud:startLevelSequence(level, player)

end


return Hud