require "prefabutil"

local function entangle(inst)
	print(tostring(inst).." has been entangled(aka added to TUNING.QUANTA).")
	table.insert(TUNING.QUANTA, inst)
end

local function unentangle(inst)
	print(tostring(inst).." has been unentangled(aka removed to TUNING.QUANTA).")
	local position = nil
	--backup chest incase the destroyed/unentangled chest is the one currently holding the items
	local backup = nil
	for k, v in pairs(TUNING.QUANTA) do
		if v.GUID == inst.GUID then
			position = k
		elseif v.components.container:IsEmpty() then
			backup = k
		end
	end
	if not TUNING.QUANTA[position].components.container:IsEmpty() and backup ~= nil then
		quantumtunnel(TUNING.QUANTA[position], TUNING.QUANTA[backup])
	end
	table.remove(TUNING.QUANTA, position)
end

local function onopen(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("open")
        inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
		--this loop will go through every chest that's in QUANTUM looking for which has the items
		for k, v in pairs(TUNING.QUANTA) do
			if not v.components.container:IsEmpty() then
				--this will protect the items incase the chest with the items is destroyed/burned
				quantumtunnel(v, inst)
			end
		end
    end
end 

local function onclose(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("close")
        inst.AnimState:PushAnimation("closed", false)
        inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
    end
end

local function onhammered(inst, worker)
	unentangle(inst)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
	--when destroyed...
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("closed", false)
        if inst.components.container ~= nil then
            --inst.components.container:DropEverything()
            inst.components.container:Close()
        end
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("closed", false)
    inst.SoundEmitter:PlaySound("dontstarve/common/chest_craft")
end

local function onsave(inst, data)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt and inst.components.burnable ~= nil then
        inst.components.burnable.onburnt(inst)
	else
		--to make sure they're still entangled whe you load the world/game
		entangle(inst)
	end
end

local function MakeChest(name, bank, build, indestructible, custom_postinit, prefabs)
    local assets =
    {
        Asset("ANIM", "anim/"..build..".zip"),
        Asset("ANIM", "anim/ui_chest_3x2.zip"),
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        inst.MiniMapEntity:SetIcon(name..".png")

        inst:AddTag("structure")
        inst:AddTag("chest")
		inst:AddTag("quantum")

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation("closed")

        MakeSnowCoveredPristine(inst)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst:AddComponent("container")
        inst.components.container:WidgetSetup(name)
        inst.components.container.onopenfn = onopen
        inst.components.container.onclosefn = onclose

        if not indestructible then
            inst:AddComponent("lootdropper")
            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
            inst.components.workable:SetWorkLeft(2)
            inst.components.workable:SetOnFinishCallback(onhammered)
            inst.components.workable:SetOnWorkCallback(onhit)

            --MakeSmallBurnable(inst, nil, nil, true)
            --MakeMediumPropagator(inst)
        end

        inst:AddComponent("hauntable")
        inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

        inst:ListenForEvent("onbuilt", onbuilt)
        MakeSnowCovered(inst)

        inst.OnSave = onsave 
        inst.OnLoad = onload

		entangle(inst)
		
        if custom_postinit ~= nil then
            custom_postinit(inst)
        end

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return MakeChest("treasurechest_quantum", "chest", "treasure_chest", false, nil, { "collapse_small" })
    --MakePlacer("treasurechest_placer", "chest", "treasure_chest", "closed")
