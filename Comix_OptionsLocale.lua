-- Bilingual (English / 简体中文) text for the Comix options window, minimap button and help.
-- Comix_Language (saved per character): nil = follow the client locale, "zh" or "en" = forced.

local L = {}

L.en = {
  title       = "Comix",
  subtitle    = "Comic hits & silly sounds",
  langButton  = "中文",
  langTip     = "切换为中文界面 (Switch to Chinese)",
  langNow     = "[Comix] Options language: English",
  close       = "Close",
  author      = "Author: |cffffd100迪恩温彻斯特|r",
  original    = "Original Comix by Turaka, Nixxen",
  test        = "Test effects",
  testTip     = "Play every effect once, two seconds apart. Click again to stop.",
  testStop    = "Stop test",
  testStopped = "[Comix] Test stopped",
  helpButton  = "Help",
  helpTip     = "Print the slash commands to chat.",

  sections = {
    general = "General",
    crit    = "Crits & Heals",
    fun     = "Combat Fun",
    skills  = "Abilities & Group",
    tuning  = "Tuning",
    emotes  = "Emotes",
    stats   = "Statistics",
  },

  opt = {
    Comix_AddOnEnabled          = { "Enable Comix", "Master switch for the whole addon." },
    Comix_SoundEnabled          = { "Sounds", "Play Comix sounds." },
    Comix_ImagesEnabled         = { "Images", "Show comic images on screen." },
    minimap                     = { "Minimap button", "Show the Comix button on the minimap." },

    Comix_CritSoundsEnabled     = { "Crit sounds", "Play a sound when your target takes a critical hit." },
    Comix_CritFlashEnabled      = { "Crit flash", "Red screen flash on crits (yours and the ones you take)." },
    Comix_BamEnabled            = { "Replace crit sounds with BAM", "Every crit sound becomes 'BAM!'." },
    Comix_CritHealsEnabled      = { "Heal crit sounds", "Play a sound on critical heals." },
    Comix_HealFlashEnabled      = { "Heal flash", "Green screen flash on critical heals." },
    Comix_CritTakenEnabled      = { "React when you get crit", "Flash and a 'Whoops!' when something crits you." },
    Comix_AvoidEnabled          = { "Dodge / parry", "'Boing!' when you dodge, parry, block, resist or get missed." },
    Comix_OverkillEnabled       = { "Overkill images", "Show an image when a killing blow massively overkills." },

    Comix_KillCountEnabled      = { "Kill streak callouts", "Unreal-style 'Killing Spree', 'Rampage'... Dying resets the streak." },
    Comix_FinishhimEnabled      = { "'Finish Him!'", "Plays when an enemy is almost dead (on restricted clients: when a mob flees in fear)." },
    Comix_DeathSoundEnabled     = { "Death sound & image", "Makes dying more demoralizing, but funnier." },
    Comix_SpecialsEnabled       = { "Specials", "'Impressive' after crit streaks, dungeon entry yell, easter-egg targets." },

    Comix_BSEnabled             = { "Battle Shout", "Image when you cast Battle Shout." },
    Comix_BSSounds              = { "Battle Shout sound", "Sound for Battle Shout." },
    Comix_DemoShoutEnabled      = { "Demoralizing Shout / Roar", "Image when you cast Demoralizing Shout or Roar." },
    Comix_DSSounds              = { "Demoralizing sound", "Sound for Demoralizing Shout / Roar." },
    Comix_AbilitySoundsEnabled  = { "Ability sounds", "Ice Block, Cannibalize, Sprint, Dash, Aspect of the Cheetah." },
    Comix_ResSoundEnabled       = { "Resurrection sound", "Extra Liiiiife!" },
    Comix_ReadySoundEnabled     = { "Ready check sound", "Are you ready?" },
    Comix_ZoneEnabled           = { "Zone change sound", "A sound every time you change zone." },
    Comix_BounceSoundEnabled    = { "Jump 'boing'", "Boing! on every jump." },

    Comix_ObjectionSoundsEnabled = { "Objection sounds", "Phoenix Wright style 'OBJECTION!'." },
    Comix_ObjectionImagesEnabled = { "Objection images", "Portraits only for party / raid members." },
    Comix_PublicObjections       = { "Public objections", "Also react to objections from outside your group." },
  },

  sliders = {
    Comix_Max_Scale     = { "Image size", "Size of the pop-up images." },
    ComixAniSpeed       = { "Animation speed", "How fast images pop in and out." },
    ComixMaxCrits       = { "Crits for 'Impressive'", "Crits in a row needed for 'Impressive'." },
    Comix_CritPercent   = { "Crit trigger chance", "Chance (%) that a crit shows effects." },
    Comix_FinishHimGap  = { "'Finish Him' health %", "Enemy health % below which 'Finish Him' plays." },
    Comix_Overkill      = { "Overkill %", "Overkill share of the killing blow needed for the image." },
  },

  stats = {
    jumps       = "Jumps",
    hugs        = "Hugs",
    show        = "Show",
    showTip     = "Print to your chat only.",
    report      = "Say",
    reportTip   = "Announce it in /say.",
    clear       = "Reset",
    clearTip    = "Reset the counter.",
  },

  minimapTip = {
    "|cffffd100Comix|r",
    "Left-click: open options",
    "Right-click: turn Comix on / off",
    "Drag: move this button",
  },
  loaded   = "|cffffb81aComix|r loaded. Type |cffffd100/comix|r or click the minimap button for options.",
  addonOn  = "[Comix] Enabled",
  addonOff = "[Comix] Disabled",

  help = {
    "------------ Comix Help ------------",
    "/comix - open the options (or click the minimap button)",
    "/comix test - play every effect once",
    "/comix debug - show why events fire or not",
    "/comix lang zh | en | auto - options language",
    "/comix minimap - show / hide the minimap button",
    "/comix showjump | reportjump | clearjump - jump statistics",
    "/fail <target> <text with ~~> , /awesome ... - link [Supermassive Fail] / [Pure Awesome]",
    "   target: say, yell, party, raid, guild, rw, bg, a channel number or a player name",
    "/drama - drama detector, /badjoke - bad joke detector (aims at your target)",
    "/comix about - version and author",
  },
}

L.zh = {
  title       = "Comix",
  subtitle    = "漫画特效 · 设置",
  langButton  = "English",
  langTip     = "Switch to English（切换为英文界面）",
  langNow     = "[Comix] 设置界面语言：中文",
  close       = "关闭",
  author      = "作者：|cffffd100迪恩温彻斯特|r",
  original    = "原版 Comix：Turaka、Nixxen",
  test        = "测试效果",
  testTip     = "每隔 2 秒播放一个效果，检查图片和声音。再点一次停止。",
  testStop    = "停止测试",
  testStopped = "[Comix] 测试已停止",
  helpButton  = "帮助",
  helpTip     = "在聊天框列出所有命令。",

  sections = {
    general = "总开关",
    crit    = "爆击与治疗",
    fun     = "战斗趣味",
    skills  = "技能与队伍",
    tuning  = "参数调整",
    emotes  = "表情互动",
    stats   = "统计",
  },

  opt = {
    Comix_AddOnEnabled          = { "启用 Comix", "整个插件的总开关。" },
    Comix_SoundEnabled          = { "声音", "播放 Comix 的音效。" },
    Comix_ImagesEnabled         = { "图片", "在屏幕上弹出漫画图片。" },
    minimap                     = { "小地图按钮", "在小地图边上显示 Comix 按钮。" },

    Comix_CritSoundsEnabled     = { "爆击音效", "你的目标被爆击时播放音效。" },
    Comix_CritFlashEnabled      = { "爆击闪屏", "爆击时（包括你被爆击）屏幕闪红光。" },
    Comix_BamEnabled            = { "爆击音效全换成 BAM", "所有爆击音效都变成“BAM！”" },
    Comix_CritHealsEnabled      = { "治疗爆击音效", "治疗爆击时播放音效。" },
    Comix_HealFlashEnabled      = { "治疗闪屏", "治疗爆击时屏幕闪绿光。" },
    Comix_CritTakenEnabled      = { "被爆击反应", "你被爆击时闪红屏，并来一句“Whoops!”" },
    Comix_AvoidEnabled          = { "闪避 / 招架", "你闪避、招架、格挡、抵抗或对方未命中时，弹图加“Boing!”" },
    Comix_OverkillEnabled       = { "超杀图片", "致命一击溢出伤害很多时弹出超杀图片。" },

    Comix_KillCountEnabled      = { "连杀播报", "《虚幻竞技场》风格的连杀播报，死亡后清零。" },
    Comix_FinishhimEnabled      = { "“Finish Him!”", "敌人快死时播放（无限客户端：怪物恐惧逃跑时触发）。" },
    Comix_DeathSoundEnabled     = { "死亡音效和图片", "死得更憋屈，也更好笑。" },
    Comix_SpecialsEnabled       = { "特殊效果", "连续爆击的“Impressive”、进副本的喊话、特定目标彩蛋。" },

    Comix_BSEnabled             = { "战斗怒吼", "施放战斗怒吼时弹图。" },
    Comix_BSSounds              = { "战斗怒吼音效", "战斗怒吼的音效。" },
    Comix_DemoShoutEnabled      = { "挫志怒吼 / 咆哮", "施放挫志怒吼或挫志咆哮时弹图。" },
    Comix_DSSounds              = { "挫志怒吼音效", "挫志怒吼 / 咆哮的音效。" },
    Comix_AbilitySoundsEnabled  = { "技能音效", "寒冰屏障、食尸、疾跑、急奔、猎豹守护。" },
    Comix_ResSoundEnabled       = { "复活音效", "多一条命！" },
    Comix_ReadySoundEnabled     = { "就位确认音效", "准备好了吗？" },
    Comix_ZoneEnabled           = { "切换区域音效", "每次切换区域都来一声。" },
    Comix_BounceSoundEnabled    = { "跳跃 Boing", "每次跳跃都“Boing!”一下。" },

    Comix_ObjectionSoundsEnabled = { "异议音效", "《逆转裁判》风格的“异议！”" },
    Comix_ObjectionImagesEnabled = { "异议图片", "只有小队 / 团队成员会显示头像。" },
    Comix_PublicObjections       = { "公开异议", "也响应队伍外玩家的异议。" },
  },

  sliders = {
    Comix_Max_Scale     = { "图片大小", "弹出图片的大小。" },
    ComixAniSpeed       = { "动画速度", "图片弹出和消失的速度。" },
    ComixMaxCrits       = { "Impressive 连续爆击数", "连续爆击多少次触发“Impressive”。" },
    Comix_CritPercent   = { "爆击触发率", "爆击时触发效果的几率（%）。" },
    Comix_FinishHimGap  = { "Finish Him 血线", "敌人血量低于这个百分比时播放。" },
    Comix_Overkill      = { "超杀比例", "致命一击溢出伤害占多少百分比算超杀。" },
  },

  stats = {
    jumps       = "跳跃",
    hugs        = "拥抱",
    show        = "查看",
    showTip     = "只显示在你自己的聊天框。",
    report      = "说出来",
    reportTip   = "用 /说 告诉周围的人。",
    clear       = "清零",
    clearTip    = "把计数清零。",
  },

  minimapTip = {
    "|cffffd100Comix 漫画特效|r",
    "左键：打开设置",
    "右键：开启 / 关闭插件",
    "拖动：移动按钮",
  },
  loaded   = "|cffffb81aComix 漫画特效|r 已加载，输入 |cffffd100/comix|r 或点击小地图按钮打开设置。",
  addonOn  = "[Comix] 已开启",
  addonOff = "[Comix] 已关闭",

  help = {
    "------------ Comix 帮助 ------------",
    "/comix - 打开设置（也可以点小地图按钮）",
    "/comix test - 依次播放所有效果",
    "/comix debug - 显示事件是否触发及原因",
    "/comix lang zh | en | auto - 设置界面语言",
    "/comix minimap - 显示 / 隐藏小地图按钮",
    "/comix showjump | reportjump | clearjump - 跳跃统计",
    "/fail <目标> <含 ~~ 的文字>、/awesome ... - 插入 [Supermassive Fail] / [Pure Awesome] 链接",
    "   目标：say、yell、party、raid、guild、rw、bg、频道编号或玩家名",
    "/drama - 狗血探测器，/badjoke - 烂笑话探测器（可对着目标用）",
    "/comix about - 版本和作者",
  },
}

Comix_OptionsL = L

-- Which language the UI should use right now.
function Comix_GetOptionsLang()
  if Comix_Language == "zh" or Comix_Language == "en" then
    return Comix_Language
  end
  local loc = GetLocale()
  if loc == "zhCN" or loc == "zhTW" then
    return "zh"
  end
  return "en"
end

function Comix_OptionsText()
  return L[Comix_GetOptionsLang()]
end

-- /comix lang [zh|en|auto]; no argument toggles between Chinese and English.
function Comix_SetOptionsLang(arg)
  if arg == "zh" or arg == "cn" or arg == "中文" then
    Comix_Language = "zh"
  elseif arg == "en" then
    Comix_Language = "en"
  elseif arg == "auto" then
    Comix_Language = nil
  else
    Comix_Language = (Comix_GetOptionsLang() == "zh") and "en" or "zh"
  end
  if Comix_RefreshOptionsText then
    Comix_RefreshOptionsText()
  end
  print(Comix_OptionsText().langNow)
end

function Comix_ShowHelp()
  for _, line in ipairs(Comix_OptionsText().help) do
    DEFAULT_CHAT_FRAME:AddMessage(line)
  end
end
