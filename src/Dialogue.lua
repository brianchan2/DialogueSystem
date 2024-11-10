type node = {
    id: any,
    text: string,
    nextNode: node,
    options: {option},
}

type option = {
    text: string,
    nextNode: node,
    conditional: (any) -> node,
    choice: boolean
}

local playerData = {}

local options = {}

function options.new(text: string, nextNode: node)
    local self = {
        text = text,
        nextNode = nextNode
    }
    setmetatable(self, {__index = options})
    return self
end

local node = {}

--[=[

    Creates a new node

    @class node
    @param text string -- Value to be stored in the node
    @param nextNode node -- The next node
    @param options {option} -- The options for the node can be a choice or conditional node
    @return node

]=]

function node.new(id, text: string, nextNode: node, options: {option})
    local self = {
        id = id,
        text = text,
        nextNode = nextNode,
        options = options
    } 
    setmetatable(self, {__index = node})
    return self
end

local Dialogue = {}
local dialogueData = {}

--[=[
    Creates a new Dialogue line

    @class Dialogue
    @param name string -- The name of the dialogue
    @return Dialogue
]=]

function Dialogue.new(name: string)
    local self = setmetatable({}, {__index = Dialogue})
    self.name = name
    self.root = nil
    return self
end

--[=[
    Adds a new text path
    
    @param id any -- The id of the node
    @param text string -- Value to be stored in the node
    @param options {option} -- Array of options
]=]

function Dialogue:add(id: any, text: string, nextNode: node, options: {option})
    if dialogueData[id] ~= nil then
        warn("Dialogue ID already exists")
        return
    end

    dialogueData[id] = node.new(id, text, nextNode, options)

    if self.root == nil then
        self.root = id
        return
    end

    return id
end

--[=[
    Gets the dialouge by id

    @param id any -- The id of the node  
]=]

function Dialogue:get(id: any)
    return dialogueData[id]    
end

--[=[
    Chooses a dialogue option

    @param player Player -- The player to display the options to
    @param options {option} -- Array of options
    @return nil

]=]

function Dialogue:choose(player: Player, choice: option)
    -- TODO: Implement choices for player to select

    for _, option in pairs(options) do
        if option.choice and choice then
            playerData[player.UserId]["Dialogue"][self.name] = choice.nextNode.id
        end
    end
end

--[=[
    Displays the dialogue
    @param player Player -- The player to display the dialogue to  
]=]

function Dialogue:show(player: Player)
    -- Stores the player data information for saving and loading
    if not playerData[player.UserId] then
        -- If the dialogue is unnamed, we name it "Main", otherwise we use its existing name.
        if self.name == nil then
            playerData[player.UserId]["Dialogue"]["Main"] = self.root.id
            return
        end
        playerData[player.UserId]["Dialogue"][self.name] = self.root.id
    end

    -- Displays the dialogue
    local dialogue = Dialogue:get(playerData[player.UserId]["Dialogue"][self.name]) or nil
    
    -- Checks player options to determine what to display.

    local choice = false

    if dialogue then
        if dialogue.options then
            for _, option in pairs(dialogue.options) do
                -- Checks for conditional; if found, checks if it's a choice, otherwise moves to next node.
                if option.conditional then
                    if not option.choice then
                        local nextNode = option.conditional(playerData[player.UserId])
                        if nextNode then
                            playerData[player.UserId]["Dialogue"][self.name] = nextNode.id
                            return
                        end
                    end
                end
            end

            -- Checks for choices and if found, else moves to next node
            if choice then
                self:choose(player, dialogue.options)
            else
                playerData[player.UserId]["Dialogue"][self.name] = dialogue.nextNode.id
            end

            return
        end
    end
end


return Dialogue
