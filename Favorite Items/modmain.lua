local json = require("json")

local INVENTORY_UPDATE_TIME = 0.2 -- Default sync time
local HAVE_FAVORITED = false
local FAVORITED_ITEMS = {}
local FAVITSAVE = "FAVORITEITEMS"

local LANG = GetModConfigData("LANGUAGE") or "en"
local STRINGS_MOD = {
	en = {
		REMOVED = " was removed from slot ",
		REPLACED = " replaced item in slot ",
		MOVED = " was moved to slot ",
		FAVORITED = " was favorited on slot ",
		FAVORITE_HINT = "Favorite",
	},
	pt = {
		REMOVED = " foi removido do slot ",
		REPLACED = " substituiu o item no slot ",
		MOVED = " foi movido para o slot ",
		FAVORITED = " foi favoritado no slot ",
		FAVORITE_HINT = "Favoritar",
	},
	zh = {
		REMOVED = " 已从格子中移除 ",
		REPLACED = " 已替换格子中的物品 ",
		MOVED = " 已移动到格子 ",
		FAVORITED = " 已收藏到格子 ",
		FAVORITE_HINT = "收藏",
	},
	ru = {
		REMOVED = " был удален из слота ",
		REPLACED = " заменил предмет в слоте ",
		MOVED = " был перемещен в слот ",
		FAVORITED = " был добавлен в избранное в слот ",
		FAVORITE_HINT = "Избранное",
	},
	es = {
		REMOVED = " fue eliminado de la ranura ",
		REPLACED = " reemplazó el objeto en la ranura ",
		MOVED = " fue movido a la ranura ",
		FAVORITED = " fue marcado como favorito en la ranura ",
		FAVORITE_HINT = "Favorito",
	}
}
local S = STRINGS_MOD[LANG] or STRINGS_MOD.en

local function SavePersistentData(name, data)
	local tstring = json.encode(data)
	GLOBAL.TheSim:SetPersistentString(name, tstring, false)
end

local function ContainsItemInTable(table, item)
	for k, v in pairs(table) do
		if v.item == item then return k end
	end
	return false
end

local function SlotIsBusy(table, slot)
	for k, v in pairs(table) do
		if v.slot == slot then return k end
	end
	return false
end


AddClassPostConstruct("widgets/invslot", function(invslot)
	-- Visual elements for Favorite Items
	invslot.star = invslot:AddChild(require("widgets/image")("images/crafting_menu.xml", "favorite_checked.tex"))
	invslot.star:SetScale(0.9, 0.9)
	invslot.star:SetPosition(1, 40, 0)
	invslot.star:Hide()

	invslot.border = invslot:AddChild(require("widgets/image")("images/crafting_menu.xml", "slot_frame_highlight.tex"))
	invslot.border:SetScale(0.55, 0.55)
	invslot.border:SetTint(1, 0.9, 0.3, 1)
	invslot.border:Hide()

	invslot.star:MoveToBack()
	invslot.border:MoveToBack()
	if invslot.bgimage then
		invslot.bgimage:MoveToBack()
	end

	local old_SetTile = invslot.SetTile
	invslot.SetTile = function(self, tile)
		if old_SetTile then
			old_SetTile(self, tile)
		end

		local is_favorite = false
		if tile and tile.item and tile.item.prefab then
			if FAVORITED_ITEMS then
				for k, v in pairs(FAVORITED_ITEMS) do
					if v.slot == self.num and v.item == tile.item.prefab then
						-- Highlight only if it's the main inventory
						if self.owner and self.container and self.container == self.owner.replica.inventory then
							is_favorite = true
							break
						end
					end
				end
			end
		end

		if is_favorite then
			self.star:Show()
			self.border:Show()
			self.star:MoveToBack()
			self.border:MoveToBack()
			if self.bgimage then
				self.bgimage:MoveToBack()
			end
		else
			self.star:Hide()
			self.border:Hide()
		end
	end


	local old_OnMouseButton = invslot.OnMouseButton
	invslot.OnMouseButton = function(self, button, down, x, y)
		local success, result = GLOBAL.pcall(function()
			if button == GLOBAL.MOUSEBUTTON_MIDDLE and down then
				if GLOBAL.TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_TRADE) then
					if self.tile and self.tile.item and self.container and self.owner and self.container == self.owner.replica.inventory then
						local prefab = self.tile.item.prefab
						local slot = self.num
						local item_name = tostring(self.tile.item.name)

						local item_idx = ContainsItemInTable(FAVORITED_ITEMS, prefab)
						local slot_idx = SlotIsBusy(FAVORITED_ITEMS, slot)

						if item_idx and FAVORITED_ITEMS[item_idx].slot == slot then
							table.remove(FAVORITED_ITEMS, item_idx)
							GLOBAL.ThePlayer.components.talker:Say(item_name .. S.REMOVED .. tostring(slot))
						else
							if item_idx then
								table.remove(FAVORITED_ITEMS, item_idx)
							end

							slot_idx = SlotIsBusy(FAVORITED_ITEMS, slot)
							if slot_idx then
								FAVORITED_ITEMS[slot_idx].item = prefab
								GLOBAL.ThePlayer.components.talker:Say(item_name .. S.REPLACED .. tostring(slot))
							else
								table.insert(FAVORITED_ITEMS, {
									item = prefab,
									slot = slot
								})
								if item_idx then
									GLOBAL.ThePlayer.components.talker:Say(item_name .. S.MOVED .. tostring(slot))
								else
									GLOBAL.ThePlayer.components.talker:Say(item_name .. S.FAVORITED .. tostring(slot))
								end
							end
						end

						HAVE_FAVORITED = GLOBAL.next(FAVORITED_ITEMS) ~= nil
						SavePersistentData(FAVITSAVE, FAVORITED_ITEMS)

						-- Update all slots visuals
						if GLOBAL.ThePlayer and GLOBAL.ThePlayer.HUD and GLOBAL.ThePlayer.HUD.controls.inv then
							for k, v in pairs(GLOBAL.ThePlayer.HUD.controls.inv.inv) do
								if v.SetTile then
									v:SetTile(v.tile)
								end
							end
						end
					end
					return true
				end
			end
		end)

		if success and result then return true end
		if old_OnMouseButton then return old_OnMouseButton(self, button, down, x, y) end
	end
end)

AddClassPostConstruct("widgets/itemtile", function(self)
	local old_GetDescriptionString = self.GetDescriptionString
	self.GetDescriptionString = function(self)
		local success, str = GLOBAL.pcall(function()
			local s = old_GetDescriptionString(self)
			if GLOBAL.TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_TRADE) then
				-- Only show MMB hint if it's in the main inventory (since favorites are restricted there)
				if self.parent and self.parent.container and self.parent.owner and self.parent.container == self.parent.owner.replica.inventory then
					s = s .. "\n\238\132\130: " .. S.FAVORITE_HINT .. "\n\n "
				end
			end
			return s
		end)
		return success and str or (old_GetDescriptionString and old_GetDescriptionString(self) or "")
	end
end)

local task_running = false

local function doRunTask()
	GLOBAL.pcall(function()
		task_running = false

		if not GLOBAL.TheFrontEnd or not GLOBAL.TheFrontEnd:GetActiveScreen() then return end
		if GLOBAL.TheFrontEnd:GetActiveScreen().name ~= "HUD" then return end

		if not HAVE_FAVORITED then return end

		local inventory = GLOBAL.ThePlayer and GLOBAL.ThePlayer.replica.inventory
		if not inventory then return end

		-- Do not organize if player is actively holding an item with the mouse
		if inventory:GetActiveItem() ~= nil then return end

		local changed = false

		-- 1. Snapshot of the main inventory
		local virtual_inv = {}
		for k, item in pairs(inventory:GetItems()) do
			if item and item.prefab then
				virtual_inv[k] = item.prefab
			end
		end

		-- 2. Snapshot of the backpack (to rescue favorites that ended up there)
		local virtual_overflow = {}
		local overflow = inventory:GetOverflowContainer()
		if overflow then
			for k, item in pairs(overflow:GetItems()) do
				if item and item.prefab then
					virtual_overflow[k] = item.prefab
				end
			end
		end

		for _, fav in pairs(FAVORITED_ITEMS) do
			local found_slot = nil
			local found_in_overflow = false

			-- Check if it's already in the correct place first (avoids stealing the item from the right place if there are two favorites of the same type)
			if virtual_inv[fav.slot] == fav.item then
				found_slot = fav.slot
				found_in_overflow = false
			else
				-- Search in another slot of the main inventory
				for k, prefab in pairs(virtual_inv) do
					if prefab == fav.item then
						found_slot = k
						break
					end
				end

				-- If not found, search in the backpack
				if not found_slot and overflow then
					for k, prefab in pairs(virtual_overflow) do
						if prefab == fav.item then
							found_slot = k
							found_in_overflow = true
							break
						end
					end
				end
			end

			if found_slot then
				if not found_in_overflow and found_slot == fav.slot then
					-- Already in the correct slot, do nothing
				else
					-- Take from the current slot (using backpack entity if it's there)
					if found_in_overflow then
						GLOBAL.SendRPCToServer(GLOBAL.RPC.TakeActiveItemFromAllOfSlot, found_slot, overflow.inst)
					else
						GLOBAL.SendRPCToServer(GLOBAL.RPC.TakeActiveItemFromAllOfSlot, found_slot)
					end
					
					-- If the target slot already has something, swap
					if virtual_inv[fav.slot] ~= nil then
						GLOBAL.SendRPCToServer(GLOBAL.RPC.SwapActiveItemWithSlot, fav.slot)
						
						-- Put the remainder back where it came from
						if found_in_overflow then
							GLOBAL.SendRPCToServer(GLOBAL.RPC.PutAllOfActiveItemInSlot, found_slot, overflow.inst)
							virtual_overflow[found_slot] = virtual_inv[fav.slot]
							virtual_inv[fav.slot] = fav.item
						else
							GLOBAL.SendRPCToServer(GLOBAL.RPC.PutAllOfActiveItemInSlot, found_slot)
							virtual_inv[found_slot] = virtual_inv[fav.slot]
							virtual_inv[fav.slot] = fav.item
						end
					else
						-- Put directly if empty
						GLOBAL.SendRPCToServer(GLOBAL.RPC.PutAllOfActiveItemInSlot, fav.slot)
						
						virtual_inv[fav.slot] = fav.item
						if found_in_overflow then
							virtual_overflow[found_slot] = nil
						else
							virtual_inv[found_slot] = nil
						end
					end
					
					changed = true
				end
			end
		end

		if changed then
			GLOBAL.SendRPCToServer(GLOBAL.RPC.ReturnActiveItem)
		end
	end)
end

local function runTask()
	if task_running then return end
	if GLOBAL.ThePlayer then
		task_running = true
		GLOBAL.ThePlayer:DoTaskInTime(0.15, doRunTask)
	end
end

AddPlayerPostInit(function(inst)
	inst:DoTaskInTime(0, function(inst)
		if inst ~= GLOBAL.ThePlayer then return end

		inst:ListenForEvent("itemget", runTask)
		inst:ListenForEvent("itemlose", runTask)
		inst:ListenForEvent("gotnewitem", runTask)
		inst:ListenForEvent("dropitem", runTask)
		inst:ListenForEvent("equip", runTask)
		inst:ListenForEvent("unequip", runTask)
		inst:ListenForEvent("newactiveitem", runTask)

		GLOBAL.TheSim:GetPersistentString(FAVITSAVE,
			function(load_success, str)
				if load_success then
					local success, sTable = GLOBAL.pcall(function() return json.decode(str) end)
					
					if success and type(sTable) == "table" then
						FAVORITED_ITEMS = sTable
						HAVE_FAVORITED = true

						if GLOBAL.ThePlayer and GLOBAL.ThePlayer.HUD and GLOBAL.ThePlayer.HUD.controls.inv then
							for k, v in pairs(GLOBAL.ThePlayer.HUD.controls.inv.inv) do
								if v.SetTile then
									v:SetTile(v.tile)
								end
							end
						end
					end
				end
			end)
	end)
end)

GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_Z, function()
	if GLOBAL.TheInput:IsKeyDown(GLOBAL.KEY_CTRL) and GLOBAL.TheInput:IsKeyDown(GLOBAL.KEY_SHIFT) then
		HAVE_FAVORITED = false
		FAVORITED_ITEMS = {}

		GLOBAL.TheSim:ErasePersistentString(FAVITSAVE)

		if GLOBAL.ThePlayer and GLOBAL.ThePlayer.HUD and GLOBAL.ThePlayer.HUD.controls.inv then
			for k, v in pairs(GLOBAL.ThePlayer.HUD.controls.inv.inv) do
				if v.SetTile then
					v:SetTile(v.tile)
				end
			end
		end
	end
end)
