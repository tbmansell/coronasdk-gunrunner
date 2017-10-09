local composer = require("composer")
local scene    = composer.newScene()



-- Called when the scene's view does not exist:
function scene:create(event)
    --local tileSize = 75
    local tileSize = 77
    local scale    = 0.5
    local cols     = 15
    local rows     = 24
    --local startX   = 20
    local startX   = 10
    --local startY   = 10
    local startY   = 360

    local rect = display.newRect(self.view, 0, 0, 2000, 2000)
    --local bgr  = display.newImage(self.view, "images/tiles-grid-new.png", globalCenterX, globalCenterY)
    local bgr  = display.newImage(self.view, "images/objectMap.png", globalCenterX, globalCenterY)

    rect:setFillColor(0.7, 0.5, 0.7)
    bgr:scale(scale, scale)

    for x=1,cols do
        for y=1,rows do
            local index = x + ((y-1)*cols)
            local xpos  = x * (tileSize*scale)
            local ypos  = y * (tileSize*scale)

            index = index + 360

            local number = display.newText(self.view, index, startX + xpos, startY + ypos, "arial", 12)
            number:setTextColor(0,0,0)
        end
    end
end


-- Called immediately after scene has moved onscreen:
function scene:show(event)
end


-- Called when scene is about to move offscreen:
function scene:hide(event)
end


-- Called prior to the removal of scene's "view" (display group)
function scene:destroy(event)
end


---------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------

scene:addEventListener("create",  scene)
scene:addEventListener("show",    scene)
scene:addEventListener("hide",    scene)
scene:addEventListener("destroy", scene)

return scene