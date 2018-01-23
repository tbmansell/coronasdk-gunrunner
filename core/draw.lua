local composer  = require("composer")
local TextCandy = require("text_candy.lib_text_candy")

-- Class
Draw = {
    debugPanel      = nil,
    debugText       = nil,
    interSceneGroup = display.newGroup()
}

-- Aliases:
local math_round     = math.round
local math_random    = math.random
local play           = globalSoundPlayer
local new_image      = display.newImage
local new_image_rect = display.newImageRect


TextCandy.AddCharsetFromBMF("gamefont_aqua",   "text_candy/ingamefont_aqua.fnt",   32)
TextCandy.AddCharsetFromBMF("gamefont_blue",   "text_candy/ingamefont_blue.fnt",   32)
TextCandy.AddCharsetFromBMF("gamefont_green",  "text_candy/ingamefont_green.fnt",  32)
TextCandy.AddCharsetFromBMF("gamefont_pink",   "text_candy/ingamefont_pink.fnt",   32)
TextCandy.AddCharsetFromBMF("gamefont_purple", "text_candy/ingamefont_purple.fnt", 32)
TextCandy.AddCharsetFromBMF("gamefont_red",    "text_candy/ingamefont_red.fnt",    32)
TextCandy.AddCharsetFromBMF("gamefont_white",  "text_candy/ingamefont_white.fnt",  32)
TextCandy.AddCharsetFromBMF("gamefont_grey",   "text_candy/ingamefont_grey.fnt",   32)
TextCandy.AddCharsetFromBMF("gamefont_yellow", "text_candy/ingamefont_yellow.fnt", 32)
TextCandy.AddCharsetFromBMF("gamefont_black",  "text_candy/ingamefont_black.fnt",  32)


function Draw:printDate(text)
    print(os.date("%H:%M:%S ")..text)
end


function Draw:newText(group, text, x, y, scale, color, align, wrapWidth)
    local font = TextCandy.CreateText({
        fontName    = "gamefont_"..color,
        x           = x,
        y           = y,
        text        = text,
        textFlow    = align,
        fontSize    = size,
        originX     = align,
        originY     = "CENTER",
        wrapWidth   = wrapWidth or nil,
        lineSpacing = 0,
        showOrigin  = false,
        parentGroup = group,
    })

    if scale ~= 1 then
        font:scale(scale,scale)
    end

    return font
end


function Draw:animateText(label, onComplete)
    local effect = {
        startNow            = true,
        loop                = true,
        restartOnChange     = true,
        restoreOnComplete   = false,

        inDelay             = 0,
        inCharDelay         = 40,
        inMode              = "LEFT_RIGHT",
        AnimateFrom         = { alpha=0, xScale=0.5, yScale=0.5, time=2000 },

        outDelay            = 0,
        outCharDelay        = 40,
        outMode             = "RIGHT_LEFT",
        AnimateTo           = { alpha=0, xScale=0.5, yScale=0.5, time=2000 },

        CompleteListener    = onComplete
    }

    label:applyInOutTransition(effect)
end


function Draw:newImage(group, image, x, y, scale, alpha)
    local image = new_image(group, "images/"..image..".png", x, y)

    if scale then image:scale(scale, scale) end
    if alpha then image.alpha = alpha end

    return image
end


function Draw:newImageRect(group, image, x, y, width, height, scale, alpha)
    local image = new_image_rect(group, "images/"..image..".png", width, height)
    image.x = x
    image.y = y

    if scale then image:scale(scale, scale) end
    if alpha then image.alpha = alpha end

    return image
end


function Draw:newBackground(group, image)
    return self:newImageRect(group, image, globalCenterX, globalCenterY, globalBackgroundWidth, globalBackgroundHeight)
end


function Draw:newBlocker(group, alpha, r,g,b, onclick, touchEvent)
    -- default to blocking all tap and touch events
    if onclick == nil then 
        onclick = function() return true end
    end

    local rect = display.newRect(group, globalCenterX, globalCenterY, 1400, 1000)
    rect.alpha = alpha or 0.5
    rect:setFillColor(r or 0, g or 0, b or 0)
    rect:addEventListener("tap", onclick)

    if touchEvent == "block" then
        rect:addEventListener("touch", function() return true end)
    elseif touchEvent ~= "ignore" then
        rect:addEventListener("touch", onclick)
    end

    return rect
end


function Draw:newButton(group, x, y, image, callback, multiClick, clickSound, size)
    local btn        = draw:newImage(group, "buttons/button-"..image.."-up",   x, y)
    local btnOverlay = draw:newImage(group, "buttons/button-"..image.."-down", x, y, nil, 0)

    if size then
        btn:scale(size, size)
        btnOverlay:scale(size, size)
    end

    btn.activated = false

    btn:addEventListener("tap", function(event)
        if not btn.activated then
            btn.activated = true

            if multiClick then
                after(multiClick, function() if btn then btn.activated = false end end)
            end

            sounds:general("button")

            btn.alpha, btnOverlay.alpha = 0, 1
            after(150, function()
                callback()
                btn.alpha, btnOverlay.alpha = 1, 0
            end)
        end
        return true
    end)

    return btn, btnOverlay
end


function Draw:newSceneTransition(time)
    self.interSceneGroup.alpha = 0

    local bgr = display.newRect(self.interSceneGroup, globalCenterX, globalCenterY, contentWidth+200, contentHeight+200)
    bgr:setFillColor(0,0,0)

    newBackground(self.interSceneGroup, "scene-transition")

    local text = draw:newText(self.interSceneGroup, "loading...", globalCenterX, 500, 0.5, "yellow")
    text.alpha = 0

    self.interSceneGroup:toFront(self.interSceneGroup)
    transition.to(self.interSceneGroup, {alpha=1, time=time or 1000})

    globalTransitionTimer = timer.performWithDelay(100, function()
        if text and text.alpha then
            if text.alpha >= 1 then
                text.backward = true
            elseif text.alpha <= 0 then
                text.backward = false
            end

            if text.backward then 
                text.alpha = text.alpha - 0.1
            else
                text.alpha = text.alpha + 0.1
            end
        end
    end, 0)
end


function Draw:clearTransitionTimer()
    if globalTransitionTimer then
        timer.cancel(globalTransitionTimer)
    end
end


function Draw:clearSceneTransition(time)
    if time then
        transition.to(self.interSceneGroup, {alpha=0, time=time, onComplete=function()
            clearTransitionTimer()
            self.interSceneGroup:removeSelf()
            self.interSceneGroup = display.newGroup()
        end})
    else
        draw:clearTransitionTimer()
        self.interSceneGroup:removeSelf()
        self.interSceneGroup = display.newGroup()
    end
end


function Draw:recordImageColor(image)
    if image.setFillColor and not image.preColor then
        image.preColor = {r=image.fill.r, g=image.fill.g, b=image.fill.b, alpha=image.alpha}
    end
end


function Draw:randomizeImage(image, doAlpha, alphaMin)
    local r, g, b = math_random(), math_random(), math_random()

    if image.setFillColor then
        image:setFillColor(r,g,b)
    end

    if doAlpha then
        local alpha = math_random()
        local min   = alphaMin or 0

        if alpha < min then alpha = min end
        image.alpha = alpha
    end
end


function Draw:restoreImage(image)
    if image.setFillColor then
        local pre = image.preColor

        if pre then
            image:setFillColor(pre.r, pre.g, pre.b)
            image.alpha = pre.alpha
            image.preColor = nil
        else
            image:setFillColor(1,1,1)
            image.alpha = 1
        end
    end
end


function Draw:displayPerformance()
    local self = Draw
    local data = " mem: "..math_round(collectgarbage("count")/1024).."mb text: "..math_round(system.getInfo("textureMemoryUsed") / 1024/1024).."mb fps: "..globalFPS
    globalFPS  = 0

    if self.performanceLabel == nil then
        self.performanceLabel = self:newText(nil, data, globalCenterX, 10, 0.4, "white", "CENTER")
    else
        self.performanceLabel:setText(data)
    end

    self.performanceLabel:toFront()
end


function Draw:toggleDebugPerformance()
    if self.performanceLabel then
        if globalDebugGame then
            self.performanceLabel.alpha = 1
        else
            self.performanceLabel.alpha = 0
        end
    end
end


function Draw:displayDebugPanel(text, x, y, width, height)
    if globalDebugStatus then
        x      = x      or globalCenterX
        y      = y      or globalCenterY
        width  = width  or 1000
        height = height or 600

        self.debugPanel = display.newRoundedRect(x, y, width, height, 15)
        self.debugPanel:setFillColor(0.3,    0.3,  0.3,  0.85)
        self.debugPanel:setStrokeColor(0.75, 0.75, 0.75, 0.75)
        self.debugPanel.strokeWidth = 2

        self.debugText = display.newText({text=text, x=x, y=y, width=width, height=height, fontSize=22, align="center"})

        self.debugPanel:addEventListener("tap", closeDebugPanel)
        self.debugText:addEventListener("tap", closeDebugPanel)
    end
end


function Draw:updateDebugPanel(text, skipNewLine)
    if globalDebugStatus then
        if self.debugText == nil then
            self:displayDebugPanel(text)
        else
            if skipNewLine then
                self.debugText.text = self.debugText.text..text
            else
                self.debugText.text = self.debugText.text.."\n"..text
            end
        end
    end
end


function Draw:closeDebugPanel()
    if self.debugPanel then
        self.debugPanel:removeSelf()
        self.debugText:removeSelf()
        self.debugPanel = nil
        self.debugText  = nil
    end
    return true
end


function Draw:displayLoader()
    self:hideLoader()
    globalLoadingDisplay = display.newGroup()

    local x, y   = globalCenterX, 500
    
    local loader = display.newRoundedRect(globalLoadingDisplay, x, y, globalWidth, 100, 15)
    loader:setFillColor(0.3,    0.3,  0.3)
    loader:setStrokeColor(0.75, 0.75, 0.75)
    loader.strokeWidth = 2

    local heading = self:newText(globalLoadingDisplay, "loading", x, y, 0.8, "white")

    --[[
    local progressHolder = display.newRoundedRect(globalLoadingDisplay, x, y, globalWidth-100, 75, 15)
    progressHolder:setFillColor(0.8, 0.3,  0.3)
    progressHolder:setStrokeColor(1, 0.75, 0.75)
    progressHolder.strokeWidth = 2

    local progress = display.newRoundedRect(globalLoadingDisplay, x, y, 0, 75, 15)
    progress:setFillColor(0.3, 0.8,  0.3)
    progress:setStrokeColor(1, 0.75, 0.75)
    progress.strokeWidth = 2

    globalLoadingDisplay.progress  = progress
    globalLoadingDisplay.increment = (globalWidth-100) / globalMaxSections
    ]]
end


function Draw:updateLoader()
    globalLoadingDisplay.progress.width = globalLoadingDisplay.progress.width + globalLoadingDisplay.increment
    globalLoadingDisplay:toFront()
end


function Draw:hideLoader()
    if globalLoadingDisplay then
        globalLoadingDisplay:removeSelf()
        globalLoadingDisplay = nil
    end
end





return Draw