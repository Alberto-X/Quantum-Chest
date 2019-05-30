PrefabFiles = 
{
	"treasurechest_quantum",
}

Assets = 
{
	Asset( "IMAGE", "minimap/treasurechest_quantum.tex" ),
	Asset( "ATLAS", "minimap/treasurechest_quantum.xml" ),
	Asset( "IMAGE", "images/inventoryimages/treasurechest_quantum.tex" ),
	Asset( "ATLAS", "images/inventoryimages/treasurechest_quantum.xml" ),
}
AddMinimapAtlas("minimap/treasurechest_quantum.xml")

GLOBAL.STRINGS.NAMES.TREASURECHEST_QUANTUM = "Quantumly Entangled Chest"
GLOBAL.STRINGS.RECIPE_DESC.TREASURECHEST_QUANTUM = "Instant accessibility."
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.TREASURECHEST_QUANTUM = "This could be useful..."
GLOBAL.STRINGS.CHARACTERS.WICKERBOTTOM.DESCRIBE.TREASURECHEST_QUANTUM = "Quantum mechanics is not my specialty, but I won't question it."
GLOBAL.STRINGS.CHARACTERS.WENDY.DESCRIBE.TREASURECHEST_QUANTUM = "Are you in there Abigail?"
GLOBAL.STRINGS.CHARACTERS.WAXWELL.DESCRIBE.TREASURECHEST_QUANTUM = "Oh Charlie, what have you done..."

AddRecipe("treasurechest_quantum", {GLOBAL.Ingredient("boards", 3), GLOBAL.Ingredient("nightmarefuel", 2)}, GLOBAL.RECIPETABS.MAGIC, GLOBAL.TECH.MAGIC_ONE, "treasurechest_placer", 1, nil, 1, nil, "images/inventoryimages/treasurechest_quantum.xml", "treasurechest_quantum.tex")

GLOBAL.TUNING.QUANTA = {}

local RUMMAGEFN = GLOBAL.ACTIONS.RUMMAGE.fn

--this is the only code that actually changes original game code
GLOBAL.ACTIONS.RUMMAGE.fn = function(act)
	local targ = act.target or act.invobject
	if targ.prefab == "treasurechest_quantum" and not targ.components.container:IsOpen() then
		for k, v in pairs(TUNING.QUANTA) do
			if v.components.container:IsOpen() then
				return false, "INUSE"
			end
		end
		return RUMMAGEFN(act)
	else
		return RUMMAGEFN(act)
	end
end

--'from' is from which container, and target is where the items are going
GLOBAL.quantumtunnel = function(from, target)
	if from ~= nil and target ~= nil then
		for i, slot in pairs(from.components.container.slots) do
			--This will loop through every item in the chest with the items and move them to the called one
			target.components.container:GiveItem(from.components.container:RemoveItemBySlot(i), i)
		end
	end
end

--keep burnable functionality if you want it back
-- local function quantumburnt(component)
	-- if component.inst:HasTag("quantum") then
		-- component.inst:ListenForEvent("onburnt", GLOBAL.unentangle)
	-- end
-- end
	
-- AddComponentPostInit("burnable", quantumburnt)

--container for the chest
--------------------------------------------------------------------------
--[[ treasurechest_quantum ]]
--------------------------------------------------------------------------
--since 'params' is localin 'containers.lua'
local params = {}

params.treasurechest_quantum =
{
    widget =
    {
        slotpos = {},
        animbank = "ui_chest_3x3",
        animbuild = "ui_chest_3x3",
        pos = GLOBAL.Vector3(0, 200, 0),
        side_align_tip = 160,
    },
    type = "chest",
}

for y = 2, 0, -1 do
    for x = 0, 2 do
        table.insert(params.treasurechest_quantum.widget.slotpos, GLOBAL.Vector3(80 * x - 80 * 2 + 80, 80 * y - 80 * 2 + 80, 0))
    end
end

local containers = GLOBAL.require "containers"
containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, params.treasurechest_quantum.widget.slotpos ~= nil and #params.treasurechest_quantum.widget.slotpos or 0)
local old_widgetsetup = containers.widgetsetup
function containers.widgetsetup(container, prefab, data)
	local pref = prefab or container.inst.prefab
	if pref == "treasurechest_quantum" then
		local t = params[pref]
		for k, v in pairs(t) do
			container[k] = v
		end
		container:SetNumSlots(container.widget.slotpos ~= nil and #container.widget.slotpos or 0)
	else
		return old_widgetsetup(container, prefab)
	end
end