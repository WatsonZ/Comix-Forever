-- Comix minimap button (+ addon compartment entry).
-- Saved per character: Comix_MinimapAngle (degrees), Comix_MinimapHidden.

local button

local function UpdatePosition()
  local angle = math.rad(Comix_MinimapAngle or 215)
  local radius = (Minimap:GetWidth() / 2) + 5
  button:ClearAllPoints()
  button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function DragUpdate()
  local mx, my = Minimap:GetCenter()
  local px, py = GetCursorPosition()
  local scale = Minimap:GetEffectiveScale()
  px, py = px / scale, py / scale
  Comix_MinimapAngle = math.deg(math.atan2(py - my, px - mx))
  UpdatePosition()
end

-- right click / compartment right click: switch the whole addon on or off
function Comix_ToggleAddon()
  Comix_AddOnEnabled = not Comix_AddOnEnabled
  local T = Comix_OptionsText()
  print(Comix_AddOnEnabled and T.addonOn or T.addonOff)
  if comix_options_frame and comix_options_frame:IsShown() and Comix_RefreshOptions then
    Comix_RefreshOptions()
  end
  if button then
    button.icon:SetDesaturated(not Comix_AddOnEnabled)
  end
end

local function ShowTooltip(owner)
  GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
  for i, line in ipairs(Comix_OptionsText().minimapTip) do
    if i == 1 then
      GameTooltip:SetText(line)
    else
      GameTooltip:AddLine(line, 1, 1, 1)
    end
  end
  GameTooltip:Show()
end

local function CreateButton()
  button = CreateFrame("Button", "ComixMinimapButton", Minimap)
  button:SetSize(31, 31)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel(8)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:RegisterForDrag("LeftButton")
  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local overlay = button:CreateTexture(nil, "OVERLAY")
  overlay:SetSize(53, 53)
  overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  overlay:SetPoint("TOPLEFT")

  local background = button:CreateTexture(nil, "BACKGROUND")
  background:SetSize(20, 20)
  background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  background:SetPoint("TOPLEFT", 7, -5)

  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetSize(17, 17)
  icon:SetTexture("Interface\\Icons\\INV_Misc_Bomb_04")
  icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
  icon:SetPoint("TOPLEFT", 7, -6)
  button.icon = icon

  button:SetScript("OnClick", function(self, mouse)
    if mouse == "RightButton" then
      Comix_ToggleAddon()
    else
      Comix_ToggleOptions()
    end
  end)
  button:SetScript("OnDragStart", function(self)
    self:LockHighlight()
    self:SetScript("OnUpdate", DragUpdate)
    GameTooltip:Hide()
  end)
  button:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    self:UnlockHighlight()
  end)
  button:SetScript("OnEnter", ShowTooltip)
  button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function Comix_UpdateMinimapButton()
  if not button then return end
  if Comix_MinimapHidden then
    button:Hide()
  else
    UpdatePosition()
    button.icon:SetDesaturated(not Comix_AddOnEnabled)
    button:Show()
  end
end

-- Addon compartment (the addon menu button next to the minimap)
function Comix_OnAddonCompartmentClick(addonName, mouseButton)
  if mouseButton == "RightButton" then
    Comix_ToggleAddon()
  else
    Comix_ToggleOptions()
  end
end

function Comix_OnAddonCompartmentEnter(addonName, menuButtonFrame)
  ShowTooltip(menuButtonFrame)
end

function Comix_OnAddonCompartmentLeave()
  GameTooltip:Hide()
end

-- create after saved variables are loaded
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
  CreateButton()
  Comix_UpdateMinimapButton()
  -- one short line instead of the old wall of "Me loaded ..." messages
  DEFAULT_CHAT_FRAME:AddMessage(Comix_OptionsText().loaded)
end)
