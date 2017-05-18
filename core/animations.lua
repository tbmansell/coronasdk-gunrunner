local Anim = {
    -- collection of seqs that will run one after the other if they have the same name
    -- adding more of the same name will buffer them up
    chainSeqs  = {},
    -- collection of seqs that will run all at the same time
    -- adding more of the same name will replace existing items
    oustSeqs = {},

    -- types:
    chain = 1, -- new sequences are chained after existing ones, they run in order
    oust  = 2, -- new sequences replace existing ones, only ones runs
}


local math_round = math.round
local math_abs   = math.abs
local play       = globalSoundPlayer


-- Creates a new seq where the target is not removed after
function Anim:chainSeq(name, target, removeTargetOnFinish)
    return self:newSeq(name, target, self.chain, removeTargetOnFinish)
end


-- Creates a new seq where the target is removed after
function Anim:oustSeq(name, target, removeTargetOnFinish)
    return self:newSeq(name, target, self.oust, removeTargetOnFinish)
end


-- Creates a new seq and adds it to the correct list
function Anim:newSeq(name, target, type, removeTargetOnFinish)
    local seq = {
        name         = name,
        type         = type,
        expired      = false,
        target       = target,
        target2      = nil,
        target3      = nil,
        removeTarget = removeTargetOnFinish or false,
        events       = {},
        timerHandles = {},
        transitionHandles = {},
        index        = 0,
        onStart      = nil,
        onComplete   = nil
    }

    -- add an anim to the seq
    function seq:add(effect, params)
        self.index = self.index + 1
        self.events[self.index] = {}
        self.events[self.index] = Anim:createAnimation(seq, effect, params)
    end

    -- Shortner to seq:add("wait", {time=1000}) for adding a delay
    function seq:wait(time)
        self:add("wait", {time=time})
    end

    -- Shortner to seq:add("tran", params) as its so frequent
    function seq:tran(params)
        self:add("tran", params)
    end

    -- Shortner to seq:add("callback"), params
    function seq:callback(callback)
        self:add("callback", {callback=callback})
    end

    -- Shortner to seq:add("callbackAfter"), params
    function seq:callbackAfter(time, callback)
        self:add("callbackAfter", {time=time, callback=callback})
    end

    -- start the index of anims in the seq
    function seq:start()
        self.index = 1
        local event = self.events[1]

        if event ~= nil then
            event:run(self)
        end
    end

    -- cancels the anims handles for the current index and nils them
    function seq:cancelHandles()
        for i,handle in pairs(self.transitionHandles) do
            transition.cancel(handle)
        end

        for i,handle in pairs(self.timerHandles) do
            timer.cancel(handle)
        end

        self.transitionHandles = {}
        self.timerHandles = {}
    end

    -- Pauses any runnings timers and transitions
    function seq:pause()
        for i,handle in pairs(self.transitionHandles) do
            transition.pause(handle)
        end

        for i,handle in pairs(self.timerHandles) do
            timer.pause(handle)
        end
    end

    -- Resumes any paused timers and transitions
    function seq:resume()
        for i,handle in pairs(self.transitionHandles) do
            transition.resume(handle)
        end

        for i,handle in pairs(self.timerHandles) do
            timer.resume(handle)
        end
    end

    -- Removes all target objects
    function seq:removeTargets()
        if self.target and self.target.removeSelf and self.removeTarget then
            self.target:removeSelf()
            self.target = nil
        end

        if self.target2 and self.target2.removeSelf and self.removeTarget then
            self.target2:removeSelf()
            self.target2 = nil
        end

        if self.target3 and self.target3.removeSelf and self.removeTarget then
            self.target3:removeSelf()
            self.target3 = nil
        end
    end

    -- looks for the next index in the anim chain (load => main => remove)
    function seq:next()
        self.index  = self.index + 1
        local event = self.events[self.index]

        if event ~= nil then
            event:run(self)
        else
            -- check if an onComplete action is set to kickoff now this seq has ended
            if self.onComplete ~= nil then
                seq.onComplete()
            end

            self:removeSeq(self)
        end
    end

    -- Just a nicer way for external callers to close a seq
    function seq:destroy()
        self:removeSeq(self)
    end

    -- determine if we should add to queue or replace existing seq
    self:assignSeq(seq)
    return seq
end


-- Calls seq:start() on the first seq in a sync queue
function Anim:startQueue(name)
    if self.chainSeqs[name] ~= nil then
        local seq = self.chainSeqs[name][1]

        if seq ~= nil then
            seq:start()
        end
    end
end


-- Assigns a new seq to the right list and deals with existing ones accordingly
function Anim:assignSeq(seq)
    local name = seq.name

    if seq.type == self.chain then
        -- create the queue if not exists
        if self.chainSeqs[name] == nil then
            self.chainSeqs[name] = {}
        end
        -- add it onto the end of the queue
        table.insert(self.chainSeqs[name], seq)
    else
        -- Replace any existing entry from the slot
        if self.oustSeqs[name] ~= nil then
            self:removeSeq(self.oustSeqs[name])
        end

        self.oustSeqs[name] = seq
    end
end


-- Removes a seq from a list cleanly, when it has finished all of it's indexes
-- For chained sequences it starts the next one in a chain if it exists
function Anim:removeSeq(seq)
    seq.expired = true
    seq:cancelHandles()
    seq:removeTargets()

    if seq.type == self.chain and self.chainSeqs[seq.name] ~= nil then
        -- It should always be the first element as we run them in order and add to the end
        table.remove(self.chainSeqs[seq.name], 1)

        local nextSeq = self.chainSeqs[seq.name][1]
        if nextSeq ~= nil then
            nextSeq:start(0)
        end
    else
        self.oustSeqs[seq.name] = nil
    end
end


-- Removes all anim seqs from all queues
function Anim:destroy()
    for name,seq in pairs(self.oustSeqs) do
        self:destroyQueue(name)
    end

    for name,queue in pairs(self.chainSeqs) do
        self:destroyQueue(name)
    end
end


-- For chain seqs it will remove all seqs with the same name, for oust it will do the same as removeSeq() as only one is stored at a time
function Anim:destroyQueue(name)
    if self.oustSeqs[name] ~= nil then
        self:destroySeq(self.oustSeqs[name])
        self.oustSeqs[name] = nil

    elseif self.chainSeqs[name] ~= nil then
        local seqs = #self.chainSeqs[name]

        for i=1,seqs do
            local seq = self.chainSeqs[name][1]
            self:destroySeq(seq)
        end

        if self.chainSeqs[name] ~= nil then
            self.chainSeqs[name] = nil
        end
    end
end


-- Removes a seq from a list cleanly, when it has finished all of it's indexs
function Anim:destroySeq(seq)
    seq.expired = true
    seq:cancelHandles()
    seq:removeTargets()

    if seq.type == self.chain and self.chainSeqs[seq.name] ~= nil then
        -- It should always be the first element as we run them in order and add to the end
        table.remove(self.chainSeqs[seq.name], 1)
    end
end


-- Pauses all running sequences timer and transitions
function Anim:pause()
    for name,seq in pairs(self.oustSeqs) do
        self:pauseQueue(name)
    end

    for name,queue in pairs(self.chainSeqs) do
        self:pauseQueue(name)
    end
end


-- Pauses a queue with a given name
function Anim:pauseQueue(name)
    if self.oustSeqs[name] ~= nil then
        self.oustSeqs[name]:pause()

    elseif self.chainSeqs[name] ~= nil then
        for i=1,#self.chainSeqs[name] do
            self.chainSeqs[name][i]:pause()
        end
    end
end


-- Resumes all paused sequences timer and transitions
function Anim:resume()
    for name,seq in pairs(self.oustSeqs) do
        self:resumeQueue(name)
    end

    for name,queue in pairs(self.chainSeqs) do
        self:resumeQueue(name)
    end
end


-- Resumes a queue with a given name
function Anim:resumeQueue(name)
    if self.oustSeqs[name] ~= nil then
        self.oustSeqs[name]:resume()
        
    elseif self.chainSeqs[name] ~= nil then
        for i=1,#self.chainSeqs[name] do
            self.chainSeqs[name][i]:resume()
        end
    end
end



-- Creates an event handler to run an anim, by encapsulating the params needed and the handler in a table
function Anim:createAnimation(seq, effect, params)
    local eventHandler = {
        name   = effect,
        params = params
    }

    if     effect == "tran"        then  self:createTransitionEffect(seq, eventHandler)
    elseif effect == "flexout"     then  self:createFlexOut(seq, eventHandler)
    elseif effect == "pulse"       then  self:createPulse(seq, eventHandler)
    elseif effect == "glow"        then  self:createGlow(seq, eventHandler)
    elseif effect == "countnum"    then  self:createCountNum(seq, eventHandler)
    elseif effect == "progressbar" then  self:createProgressBar(seq, eventHandler)
    elseif effect == "spin"        then  self:createSpin(seq, eventHandler)
    elseif effect == "filter"      then  self:createFilter(seq, eventHandler)
    elseif effect == "callback"    then
        -- Do nothing but call a function passed in
        function eventHandler:run(seq)
            self.params.callback()
            seq:next()
        end
    elseif effect == "callbackAfter" then
        -- Do nothing but call a function passed AFTER a delay period
        function eventHandler:run(seq)
            local time   = self.params.time or 0
            local handle = timer.performWithDelay(time, function() 
                self.params.callback()
                seq:next() 
            end)
            table.insert(seq.timerHandles, handle)
        end
    elseif effect == "callbackLoop" then
        -- Do nothin but call a function repeatedly on a timer
        function eventHandler:run(seq)
            local loops = self.params.loops or 0
            local delay = self.params.delay or 1000

            local handle = timer.performWithDelay(delay, function()
                self.params.callback()
            end, loops)
            table.insert(seq.timerHandles, handle)

            if loops > 0 then
                local terminator = timer.performWithDelay(delay*loops, function() seq:next() end)
                table.insert(seq.timerHandles, terminator)
            end
        end
    elseif effect == "wait" then
        -- Doing nothing but trigger the next anim after waiting
        function eventHandler:run(seq)
            local time = self.params.time or 0
            table.insert(seq.timerHandles, timer.performWithDelay(time, function() seq:next() end))
        end
    else
        -- Catchup in-case of typos, so we dont crash the app
        function eventHandler:run(seq)
            print("Warning: invalid anim name: "..self.name)
            seq:next()
        end
    end

    return eventHandler
end


-- Performs actions common to any effect, called from within each eventHandler created 
function Anim:createCommonEffect(seq, handler)
    local playSound = handler.params.playSound or nil
    local playDelay = handler.params.playDelay or nil
    
    -- Check for loading sounds
    if playSound then
        if playDelay then
            local soundHandle = timer.performWithDelay(playDelay,function()
                play(playSound)
            end)
            table.insert(seq.timerHandles, soundHandle)
        else
            play(playSound)
        end
    end
end


------------ anims for seqs -----------------

-- General single transition
function Anim:createTransitionEffect(seq, eventHandler)
    function eventHandler:run(seq)
        Anim:createCommonEffect(seq, self)

        local params = self.params

        if params.scale ~= nil then
            params.xScale, params.yScale = params.scale, params.scale
            params.scale = nil
        end

        if params.ease then
            if     params.ease == "bounce" then params.transition = easing.outBounce
            elseif params.ease == "whizz"  then params.transition = easing.inQuart
            elseif params.ease == "spring" then params.transition = easing.outBack
            else   params.transition = params.ease end
            params.ease = nil
        end

        -- do extra targets first, so they dont include the onComplete event
        if seq.target2 then
            table.insert(seq.transitionHandles, transition.to(seq.target2, params))
        end
        if seq.target3 then
            table.insert(seq.transitionHandles, transition.to(seq.target3, params))
        end

        -- Add the following properties to handler params and we can use it
        params.onComplete = function()
            seq:next()
        end
        table.insert(seq.transitionHandles, transition.to(seq.target, params))
    end
end


-- Fades the target alpha to 0
function Anim:createFlexOut(seq, eventHandler)
    function eventHandler:run(seq)
        Anim:createCommonEffect(seq, self)

        local time      = self.params.time  or 1000
        local delay     = self.params.delay or 0
        local scale     = self.params.scale or 1.2
        local scaleBack = self.params.scaleBack or 1
        local alpha     = self.params.alpha or 1

        local handle = transition.to(seq.target, {xScale=scale, yScale=scale, time=time/2, delay=delay, alpha=alpha, onComplete=function()
            local subhandle = transition.to(seq.target, {xScale=scaleBack, yScale=scaleBack, time=time/2, delay=delay, onComplete=function()
                seq:next()
            end})
            table.insert(seq.transitionHandles, subhandle)
        end})

        table.insert(seq.transitionHandles, handle)
    end
end


-- looper for createPulse()
local function pulseLoop(seq, handler)
    if handler.expired == true or seq.expired == true then
        return
    end

    local time   = handler.params.time/2
    local delay  = handler.params.delay
    local scale  = handler.params.baseScale
    local handle = nil

    if handler.larger then
        handler.larger = false
        scale = scale * (1-handler.params.scale)
    else
        handler.larger = true
        scale = scale * (1+handler.params.scale)
    end

    handle = transition.to(seq.target, {xScale=scale, yScale=scale, time=time, delay=delay, onComplete=function() pulseLoop(seq, handler) end})
    table.insert(seq.transitionHandles, handle)

    if seq.target2 ~= nil then
        handle2 = transition.to(seq.target2, {xScale=scale, yScale=scale, time=time, delay=delay})
        table.insert(seq.transitionHandles, handle2)
    end

    if seq.target3 ~= nil then
        handle3 = transition.to(seq.target3, {xScale=scale, yScale=scale, time=time, delay=delay})
        table.insert(seq.transitionHandles, handle3)
    end
end

-- Repeatedly zooms in and out for a duration
function Anim:createPulse(seq, eventHandler)
    function eventHandler:run(seq)
        self.params.baseScale = self.params.baseScale or 1

        local handler = self
        local expires = self.params.expires or nil

        if expires then
            local handle = timer.performWithDelay(expires, function()
                handler.expired = true
                seq:next()
            end)
            table.insert(seq.timerHandles, handle)
        end

        pulseLoop(seq, self)
    end
end


-- looper for createGlow()
local function glowLoop(seq, handler)
    if handler.expired == true or seq.expired == true then
        return
    end

    local time   = handler.params.time/2
    local delay  = handler.params.delay
    local switch = handler.params.switch
    local handle = nil
    local alpha  = nil
    local salpha = nil

    if handler.larger then
        handler.larger = false
        alpha  = seq.target.alpha + handler.params.alpha
        salpha = seq.target.alpha - handler.params.alpha

        delay = handler.params.delayFaded or delay
    else
        handler.larger = true
        alpha  = seq.target.alpha - handler.params.alpha
        salpha = seq.target.alpha + handler.params.alpha

        
    end

    if salpha > 1 then salpha = 1 elseif salpha < 0 then salpha = 0 end

    handle = transition.to(seq.target, {alpha=alpha, time=time, delay=delay, onComplete=function() glowLoop(seq, handler) end})
    table.insert(seq.transitionHandles, handle)

    if seq.target2 then
        if switch then alpha = salpha end
        handle2 = transition.to(seq.target2, {alpha=alpha, time=time, delay=delay})
        table.insert(seq.transitionHandles, handle2)
    end

    if seq.target3 then
        if switch then alpha = salpha end
        handle3 = transition.to(seq.target3, {alpha=alpha, time=time, delay=delay})
        table.insert(seq.transitionHandles, handle3)
    end    
end

-- Repeatedly fades in and out for a duration
function Anim:createGlow(seq, eventHandler)
    function eventHandler:run(seq)
        local handler    = self
        local expires    = self.params.expires or nil
        local delayStart = self.params.delayStart or 0

        if seq.target.alpha < 0 then handler.larger = true else handler.larger = false end

        if expires then
            local handle = timer.performWithDelay(expires, function()
                handler.expired = true
                seq:next()
            end)
            table.insert(seq.timerHandles, handle)
        end

        after(delayStart, function() glowLoop(seq, self) end)
    end
end


-- helper for createCountNum()
local function countNumLoopUpdateTarget(handler, target, ratio, align, xpos)
    local ratio = ratio or 1
    local align = align or "left"
    
    if ratio >= 1 then
        target:setText(math_round(tonumber(target.text) + ratio))
    else
        local runningValue = handler.currentRunValue * ratio
        
        if runningValue > 0 and runningValue % 1 == 0 then
            target:setText(math_round(tonumber(target.text)) + 1)
        end
    end
end

-- Looperfor creatCountNum()
local function countNumLoop(seq, handler)
    if handler.expired == true or seq.expired == true then
        return
    end
    
    local p = handler.params
    local playSound  = p.playSound  or nil
    local countStep  = p.countStep  or 1
    local appendText = p.appendText or ""
    local align      = p.align      or "left"
    local xpos       = p.xpos       or seq.target.x
    
    handler.currentNumValue = handler.currentNumValue + countStep
    handler.currentRunValue = handler.currentRunValue + math_abs(countStep)
    
    seq.target:setText(handler.currentNumValue..appendText)
    
    if seq.target2 then
        countNumLoopUpdateTarget(handler, seq.target2, p.ratio2, p.align2, p.xpos2)
    end
    
    if seq.target3 then
        countNumLoopUpdateTarget(handler, seq.target3, p.ratio3, p.align3, p.xpos3)
    end
    
    if playSound then play(playSound) end
end

-- Counts up a number and updates a text target with the value
function Anim:createCountNum(seq, eventHandler)
    function eventHandler:run(seq)
        local handler    = self
        local countDelay = self.params.countDelay or 25
        local countFrom  = self.params.countFrom  or tonumber(seq.target.text)
        local countTo    = self.params.countTo    or 0
        local countStep  = self.params.countStep  or 1
        
        local loops = (countTo - countFrom) / countStep
        
        handler.currentNumValue = countFrom
        handler.currentRunValue = 0
        handler.currentIter     = 1
        
        local handle = timer.performWithDelay(countDelay, function()
            countNumLoop(seq, handler)
            
            if handler.currentIter == loops then
                seq:next()
            else
                handler.currentIter = handler.currentIter + 1
            end
        end, loops)
        
        table.insert(seq.timerHandles, handle)
    end
end


-- looper for createProgressBar()
local function progressBarLoop(seq, handler)
    if handler.expired == true or seq.expired == true then
        return
    end

    local countStep = handler.params.countStep or 1
    local origX     = seq.target.x

    if seq.target.width ~= nil then  -- shield against early exit
        seq.target.width = seq.target.width + countStep
        --seq.target:setReferencePoint(display.CenterLeftReferencePoint)
        seq.target.anchorX = 0
        seq.target.x = origX
    end
end

-- Creates a progress bar from left to right, using a basic shape
function Anim:createProgressBar(seq, eventHandler)
    function eventHandler:run(seq)
        local handler    = self
        local countDelay = self.params.countDelay or 25
        local loops      = self.params.loops      or 1

        handler.currentIter = 1

        local handle = timer.performWithDelay(countDelay, function()
            progressBarLoop(seq, handler)

            if handler.currentIter == loops then
                seq:next()
            else
                handler.currentIter = handler.currentIter + 1
            end
        end, loops)

        table.insert(seq.timerHandles, handle)
    end
end


-- Iterates from one number, an amount of times, adding a certain amount per iteration, updating a text object
function Anim:addNumber(label, iterations, delay, addPerIteration, onComplete)
    local start = tonumber(label.text)
    local add   = addPerIteration or 1
    local Delay = delay or 25
    local i     = 1
    
    timer.performWithDelay(Delay, function()
        start = start + add
        label.text = start
        i = i + 1
        -- call back on last iteration
        if i >= iterations and onComplete then
            onComplete()
        end
    end, iterations)
end


-- Removes numbers from one label to another, by a ratio of addPerIteration
function Anim:addNumberFrom(labelFrom, labelTo, delay, addPerIteration, onComplete)
    local to   = tonumber(labelTo.text) or 0
    local from = tonumber(labelFrom.text) or 1
    local loop = from
    local add  = addPerIteration or 1
    local Delay = delay or 25
    
    timer.performWithDelay(Delay, function()
        to = to + add
        from = from - 1
        labelTo.text = to
        labelFrom.text = from
        -- call back on last iteration if passed
        if from < 1 and onComplete then
            onComplete()
        end
    end, loop)
end



-- Repeatedly applies a corona filter for a duration - in one direction
function Anim:createFilter(seq, eventHandler)
    function eventHandler:run(seq)
        self.params.baseScale = self.params.baseScale or 1

        local handler    = self
        local target     = seq.target
        local delay      = self.params.delay or 100
        local start      = self.params.start
        local finish     = self.params.finish
        local increment  = self.params.increment or 1
        local effect     = self.params.effect

        -- setup the filter effect before we start to animate
        target.fill.effect = "filter."..effect

        local iterations = (finish-start) / math_abs(increment)
        local area       = target.fill.effect
        local loop       = 0

        local handle = timer.performWithDelay(delay, function()
            if     effect == "frostedGlass" then area.scale     = area.scale     + increment
            elseif effect == "pixelate"     then area.numPixels = area.numPixels + increment
            elseif effect == "opTile"       then area.numPixels = area.numPixels + increment
            elseif effect == "bulge"        then area.intensity = area.intensity + increment
            elseif effect == "crystallize"  then area.numTiles  = area.numTiles  + increment
            elseif effect == "scatter"      then area.intensity = area.intensity + increment
            end

            loop = loop + 1
            if loop >= iterations then
                handler.expired = true
                seq:next()
            end
        end, iterations)

        table.insert(seq.timerHandles, handle)
    end
end


return Anim