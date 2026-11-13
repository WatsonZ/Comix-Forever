-- Comix options window, built in Lua.
-- Every change is applied immediately; options the current client cannot
-- support are left out of the layout.

local ADDON_PATH = "Interface\\AddOns\\Comix\\"

-- ---------------------------------------------------------------------------
-- What this client can do
-- ---------------------------------------------------------------------------
local function Supports(need)
  if need == nil then return true end
  if need == "combatlog" then
    -- overkill amounts and the crit gap need the combat log
    return Comix_CombatLogAvailable
  elseif need == "health" then
    -- the "Finish Him" health threshold needs readable target health; the
    -- restricted clients that hide the combat log hide health as well
    return Comix_CombatLogAvailable
  elseif need == "englishEmotes" then
    -- hug / objection detection only understands English emote text
    local loc = GetLocale()
    return loc ~= "zhCN" and loc ~= "zhTW"
  end
  return true
end

-- ---------------------------------------------------------------------------
-- Layout description
-- ---------------------------------------------------------------------------
local MINIMAP = {
  get = function() return not Comix_MinimapHidden end,
  set = function(v)
    Comix_MinimapHidden = not v
    if Comix_UpdateMinimapButton then Comix_UpdateMinimapButton() end
  end,
}

local LAYOUT = {
  { -- column 1
    { section = "general", items = {
      { check = "Comix_AddOnEnabled", master = true },
      { check = "Comix_SoundEnabled" },
      { check = "Comix_ImagesEnabled" },
      { check = "minimap", accessor = MINIMAP, master = true },
    }},
    { section = "crit", items = {
      { check = "Comix_CritSoundsEnabled" },
      { check = "Comix_BamEnabled", parent = "Comix_CritSoundsEnabled" },
      { check = "Comix_CritFlashEnabled" },
      { check = "Comix_CritHealsEnabled" },
      { check = "Comix_HealFlashEnabled" },
      { check = "Comix_CritTakenEnabled" },
      { check = "Comix_AvoidEnabled" },
      { check = "Comix_OverkillEnabled", need = "combatlog" },
    }},
  },
  { -- column 2
    { section = "fun", items = {
      { check = "Comix_KillCountEnabled" },
      { check = "Comix_FinishhimEnabled" },
      { check = "Comix_DeathSoundEnabled" },
      { check = "Comix_SpecialsEnabled" },
    }},
    { section = "skills", items = {
      { check = "Comix_BSEnabled" },
      { check = "Comix_BSSounds", parent = "Comix_BSEnabled" },
      { check = "Comix_DemoShoutEnabled" },
      { check = "Comix_DSSounds", parent = "Comix_DemoShoutEnabled" },
      { check = "Comix_AbilitySoundsEnabled" },
      { check = "Comix_ResSoundEnabled" },
      { check = "Comix_ReadySoundEnabled" },
      { check = "Comix_ZoneEnabled" },
      { check = "Comix_BounceSoundEnabled" },
    }},
  },
  { -- column 3
    { section = "tuning", items = {
      { slider = "Comix_Max_Scale",    min = 1.5, max = 3,   step = 0.1 },
      { slider = "ComixAniSpeed",      min = 1,   max = 3,   step = 0.1 },
      { slider = "ComixMaxCrits",      min = 1,   max = 10,  step = 1 },
      { slider = "Comix_CritPercent",  min = 1,   max = 100, step = 1, suffix = "%" },
      { slider = "Comix_FinishHimGap", min = 1,   max = 50,  step = 1, suffix = "%", need = "health" },
      { slider = "Comix_Overkill",     min = 50,  max = 95,  step = 1, suffix = "%", need = "combatlog" },
    }},
    { section = "emotes", need = "englishEmotes", items = {
      { check = "Comix_ObjectionSoundsEnabled" },
      { check = "Comix_ObjectionImagesEnabled" },
      { check = "Comix_PublicObjections" },
    }},
    { section = "stats", items = {
      { stat = "jumps", show = "showjump", report = "reportjump", clear = "clearjump" },
      { stat = "hugs",  show = "showhug",  report = "reporthug",  clear = "clearhug", need = "englishEmotes" },
    }},
  },
}

-- ---------------------------------------------------------------------------
-- Look & feel
-- ---------------------------------------------------------------------------
local COLOR_BG      = { 0.06, 0.06, 0.08, 0.96 }
local COLOR_BORDER  = { 0.85, 0.65, 0.15, 1 }
local COLOR_ACCENT  = { 1.00, 0.72, 0.10 }
local COL_X         = { 22, 282, 542 }
local COL_W         = 236
local TOP_Y         = -74
local ROW_CHECK     = 24
local ROW_SLIDER    = 42
local ROW_STAT      = 28
local SECTION_GAP   = 14
local FOOTER_H      = 54

local function CreateTitleFont()
  local font = CreateFont("ComixTitleFont")
  font:SetFont(ADDON_PATH.."Fonts\\comix.TTF", 28, "OUTLINE")
  if not font:GetFont() then
    font:SetFontObject(GameFontNormalHuge)
  end
  font:SetTextColor(COLOR_ACCENT[1], COLOR_ACCENT[2], COLOR_ACCENT[3])
  font:SetShadowOffset(2, -2)
  font:SetShadowColor(0, 0, 0, 1)
  return font
end

local function PlayClick(on)
  if SOUNDKIT and PlaySound then
    PlaySound(on and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
  end
end

local function ShowTip(owner, title, text)
  if not title then return end
  GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
  GameTooltip:SetText(title, COLOR_ACCENT[1], COLOR_ACCENT[2], COLOR_ACCENT[3])
  if text then
    GameTooltip:AddLine(text, 1, 1, 1, true)
  end
  GameTooltip:Show()
end

local function HideTip()
  GameTooltip:Hide()
end

-- ---------------------------------------------------------------------------
-- Widgets
-- ---------------------------------------------------------------------------
local frame
local widgets = {}        -- everything that carries translated text
local checks = {}         -- var -> checkbutton
local sliders = {}        -- var -> slider

local function GetValue(item)
  if item.accessor then return item.accessor.get() end
  return _G[item.check] and true or false
end

local function SetValue(item, v)
  if item.accessor then
    item.accessor.set(v)
  else
    _G[item.check] = v
  end
end

local function UpdateDependencies()
  for _, cb in pairs(checks) do
    local item = cb.item
    local on = true
    if item.parent then
      on = _G[item.parent] and true or false
    end
    cb:SetEnabled(on)
    if on then
      cb.label:SetTextColor(0.92, 0.92, 0.92)
    else
      cb.label:SetTextColor(0.45, 0.45, 0.45)
    end
    -- grey out everything except the master switches while the addon is off
    if not item.master then
      cb:SetAlpha(Comix_AddOnEnabled and 1 or 0.5)
    end
  end
  for _, s in pairs(sliders) do
    s.row:SetAlpha(Comix_AddOnEnabled and 1 or 0.5)
  end
end

local function NewCheck(parent, x, y, item)
  local indent = item.parent and 18 or 0
  local cb = CreateFrame("CheckButton", nil, parent)
  cb:SetSize(22, 22)
  cb:SetPoint("TOPLEFT", x + indent, y)
  cb:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
  cb:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
  cb:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
  cb:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
  cb:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
  cb:SetHitRectInsets(0, -(COL_W - 30 - indent), 0, 0)

  cb.label = cb:CreateFontString(nil, "ARTWORK", item.parent and "GameFontHighlightSmall" or "GameFontHighlight")
  cb.label:SetPoint("LEFT", cb, "RIGHT", 2, 0)
  cb.label:SetWidth(COL_W - 30 - indent)
  cb.label:SetJustifyH("LEFT")
  cb.label:SetWordWrap(false)

  cb.item = item
  cb:SetScript("OnClick", function(self)
    local v = self:GetChecked() and true or false
    SetValue(self.item, v)
    PlayClick(v)
    UpdateDependencies()
  end)
  cb:SetScript("OnEnter", function(self) ShowTip(self, self.tipTitle, self.tipText) end)
  cb:SetScript("OnLeave", HideTip)

  cb.UpdateText = function(self, T)
    local t = T.opt[item.check] or { item.check }
    self.label:SetText(t[1])
    self.tipTitle, self.tipText = t[1], t[2]
  end
  checks[item.check] = cb
  widgets[#widgets+1] = cb
  return ROW_CHECK
end

local function FormatValue(item, v)
  local s
  if item.step < 1 then
    s = string.format("%.1f", v)
  else
    s = tostring(math.floor(v + 0.5))
  end
  return s..(item.suffix or "")
end

local function NewSlider(parent, x, y, item)
  local row = CreateFrame("Frame", nil, parent)
  row:SetSize(COL_W, ROW_SLIDER)
  row:SetPoint("TOPLEFT", x, y)

  local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  label:SetPoint("TOPLEFT", 2, -2)
  local value = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  value:SetPoint("TOPRIGHT", -14, -2)

  local s = CreateFrame("Slider", nil, row, "BackdropTemplate")
  s:SetOrientation("HORIZONTAL")
  s:SetSize(COL_W - 16, 16)
  s:SetPoint("TOPLEFT", 0, -18)
  s:SetHitRectInsets(0, 0, -6, -6)
  if s.SetBackdrop and COMIX_BACKDROP_SLIDER then
    s:SetBackdrop(COMIX_BACKDROP_SLIDER)
  end
  s:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
  local thumb = s:GetThumbTexture()
  if thumb then thumb:SetSize(32, 32) end
  s:SetMinMaxValues(item.min, item.max)
  s:SetValueStep(item.step)
  if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end

  s.item, s.row, s.label, s.value = item, row, label, value
  s:SetScript("OnValueChanged", function(self, v)
    if self.item.step < 1 then
      v = math.floor(v * 10 + 0.5) / 10
    else
      v = math.floor(v + 0.5)
    end
    _G[self.item.slider] = v
    self.value:SetText(FormatValue(self.item, v))
  end)
  s:SetScript("OnEnter", function(self) ShowTip(self, self.tipTitle, self.tipText) end)
  s:SetScript("OnLeave", HideTip)

  s.UpdateText = function(self, T)
    local t = T.sliders[item.slider] or { item.slider }
    self.label:SetText(t[1])
    self.tipTitle, self.tipText = t[1], t[2]
  end
  sliders[item.slider] = s
  widgets[#widgets+1] = s
  return ROW_SLIDER
end

local function NewButton(parent, width, key, tipKey, onClick)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width, 22)
  b:SetScript("OnClick", onClick)
  b:SetScript("OnEnter", function(self) ShowTip(self, self.tipTitle, self.tipText) end)
  b:SetScript("OnLeave", HideTip)
  b.UpdateText = function(self, T)
    local text = key(T)
    self:SetText(text)
    self.tipTitle = text
    self.tipText = tipKey and tipKey(T) or nil
  end
  widgets[#widgets+1] = b
  return b
end

local function NewStat(parent, x, y, item)
  local label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  label:SetPoint("TOPLEFT", x + 2, y - 5)
  label:SetWidth(52)
  label:SetJustifyH("LEFT")
  local holder = { UpdateText = function(_, T) label:SetText(T.stats[item.stat]) end }
  widgets[#widgets+1] = holder

  local bx = x + 54
  for _, what in ipairs({ "show", "report", "clear" }) do
    local cmd = item[what]
    local b = NewButton(parent, 58, function(T) return T.stats[what] end, function(T) return T.stats[what.."Tip"] end,
      function() Comix_Command(cmd) end)
    b:SetPoint("TOPLEFT", bx, y)
    bx = bx + 60
  end
  return ROW_STAT
end

local function NewSection(parent, x, y, key)
  local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  title:SetPoint("TOPLEFT", x, y)
  title:SetTextColor(COLOR_ACCENT[1], COLOR_ACCENT[2], COLOR_ACCENT[3])

  local line = parent:CreateTexture(nil, "ARTWORK")
  line:SetColorTexture(COLOR_BORDER[1], COLOR_BORDER[2], COLOR_BORDER[3], 0.35)
  line:SetHeight(1)
  line:SetPoint("TOPLEFT", x, y - 16)
  line:SetWidth(COL_W - 10)

  widgets[#widgets+1] = { UpdateText = function(_, T) title:SetText(T.sections[key]) end }
  return 24
end

-- ---------------------------------------------------------------------------
-- Window
-- ---------------------------------------------------------------------------
local function BuildFrame()
  local f = CreateFrame("Frame", "comix_options_frame", UIParent, "BackdropTemplate")
  frame = f
  f:SetFrameStrata("DIALOG")
  f:SetToplevel(true)
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:SetPoint("CENTER")
  f:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  f:SetBackdropColor(unpack(COLOR_BG))
  f:SetBackdropBorderColor(unpack(COLOR_BORDER))
  tinsert(UISpecialFrames, "comix_options_frame")

  -- header band
  local band = f:CreateTexture(nil, "BACKGROUND", nil, 1)
  band:SetPoint("TOPLEFT", 5, -5)
  band:SetPoint("TOPRIGHT", -5, -5)
  band:SetHeight(52)
  band:SetColorTexture(1, 0.6, 0.05, 0.10)
  local bandLine = f:CreateTexture(nil, "ARTWORK")
  bandLine:SetPoint("TOPLEFT", band, "BOTTOMLEFT")
  bandLine:SetPoint("TOPRIGHT", band, "BOTTOMRIGHT")
  bandLine:SetHeight(2)
  bandLine:SetColorTexture(COLOR_BORDER[1], COLOR_BORDER[2], COLOR_BORDER[3], 0.8)

  local icon = f:CreateTexture(nil, "ARTWORK")
  icon:SetSize(34, 34)
  icon:SetPoint("TOPLEFT", 16, -14)
  icon:SetTexture("Interface\\Icons\\INV_Misc_Bomb_04")
  icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

  local title = f:CreateFontString("comixheader", "OVERLAY")
  title:SetFontObject(ComixTitleFont or CreateTitleFont())
  title:SetPoint("LEFT", icon, "RIGHT", 10, 1)
  title:SetText("COMIX")

  local subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  subtitle:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 12, 4)
  widgets[#widgets+1] = { UpdateText = function(_, T) subtitle:SetText(T.subtitle) end }

  local version = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  version:SetPoint("TOPRIGHT", -40, -24)
  version:SetText(ComixVersion or "")

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -4, -4)

  -- columns
  local bottom = 0
  for col, sections in ipairs(LAYOUT) do
    local x, y = COL_X[col], TOP_Y
    for _, sec in ipairs(sections) do
      if Supports(sec.need) then
        local visible = {}
        for _, item in ipairs(sec.items) do
          if Supports(item.need) then visible[#visible+1] = item end
        end
        if #visible > 0 then
          y = y - NewSection(f, x, y, sec.section)
          for _, item in ipairs(visible) do
            if item.check then
              y = y - NewCheck(f, x, y, item)
            elseif item.slider then
              y = y - NewSlider(f, x, y, item)
            elseif item.stat then
              y = y - NewStat(f, x, y, item)
            end
          end
          y = y - SECTION_GAP
        end
      end
    end
    bottom = math.max(bottom, -y)
  end

  local height = bottom + FOOTER_H
  f:SetSize(COL_X[3] + COL_W + 18, height)

  -- footer
  local footLine = f:CreateTexture(nil, "ARTWORK")
  footLine:SetPoint("BOTTOMLEFT", 12, FOOTER_H - 10)
  footLine:SetPoint("BOTTOMRIGHT", -12, FOOTER_H - 10)
  footLine:SetHeight(1)
  footLine:SetColorTexture(COLOR_BORDER[1], COLOR_BORDER[2], COLOR_BORDER[3], 0.35)

  -- author credit, left side of the footer
  local author = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  author:SetPoint("BOTTOMLEFT", 22, 26)
  author:SetJustifyH("LEFT")
  local original = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  original:SetPoint("TOPLEFT", author, "BOTTOMLEFT", 0, -3)
  original:SetJustifyH("LEFT")
  widgets[#widgets+1] = { UpdateText = function(_, T)
    author:SetText(T.author)
    original:SetText(T.original)
  end }

  local closeBtn = NewButton(f, 96, function(T) return T.close end, nil, function() f:Hide() end)
  closeBtn:SetPoint("BOTTOMRIGHT", -18, 14)
  local langBtn = NewButton(f, 96, function(T) return T.langButton end, function(T) return T.langTip end,
    function(self)
      Comix_SetOptionsLang()
      if GameTooltip:IsOwned(self) then ShowTip(self, self.tipTitle, self.tipText) end
    end)
  langBtn:SetPoint("RIGHT", closeBtn, "LEFT", -6, 0)
  local helpBtn = NewButton(f, 96, function(T) return T.helpButton end, function(T) return T.helpTip end,
    function() Comix_ShowHelp() end)
  helpBtn:SetPoint("RIGHT", langBtn, "LEFT", -6, 0)
  local testBtn = NewButton(f, 110, function(T) return Comix_TestRunning and T.testStop or T.test end, function(T) return T.testTip end,
    function() Comix_Command("test") end)
  testBtn:SetPoint("RIGHT", helpBtn, "LEFT", -6, 0)

  f:SetScript("OnShow", function() Comix_RefreshOptions() end)
  f:Hide()
end

-- push current setting values into the widgets
function Comix_RefreshOptions()
  if not frame then return end
  for _, cb in pairs(checks) do
    cb:SetChecked(GetValue(cb.item))
  end
  for var, s in pairs(sliders) do
    local v = tonumber(_G[var]) or s.item.min
    s:SetValue(v)
    s.value:SetText(FormatValue(s.item, v))
  end
  UpdateDependencies()
end

-- push the current language into the widgets
function Comix_RefreshOptionsText()
  if not frame then return end
  local T = Comix_OptionsText()
  for _, w in ipairs(widgets) do
    -- one bad entry must not leave the rest of the window without text
    local ok, err = pcall(w.UpdateText, w, T)
    if not ok then Comix_Dbg("UpdateText:", err) end
  end
end

function Comix_ToggleOptions()
  if not frame then
    BuildFrame()
    Comix_RefreshOptionsText()
  end
  if frame:IsShown() then
    frame:Hide()
  else
    frame:Show()
  end
end
