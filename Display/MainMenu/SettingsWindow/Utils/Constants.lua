-- Paths, dimensions, and class-specific background textures for the settings window.

RaceLocked_Settings = RaceLocked_Settings or {}

local S = RaceLocked_Settings

S.TEXTURE_PATH = 'Interface\\AddOns\\RaceLocked\\Textures'

S.CLASS_BACKGROUND_MAP = {
  WARRIOR = S.TEXTURE_PATH .. '\\bg_warrior.png',
  PALADIN = S.TEXTURE_PATH .. '\\bg_pally.png',
  HUNTER = S.TEXTURE_PATH .. '\\bg_hunter.png',
  ROGUE = S.TEXTURE_PATH .. '\\bg_rogue.png',
  PRIEST = S.TEXTURE_PATH .. '\\bg_priest.png',
  MAGE = S.TEXTURE_PATH .. '\\bg_mage.png',
  WARLOCK = S.TEXTURE_PATH .. '\\bg_warlock.png',
  DRUID = S.TEXTURE_PATH .. '\\bg_druid.png',
  SHAMAN = S.TEXTURE_PATH .. '\\bg_shaman.png',
}

S.CLASS_BACKGROUND_ASPECT_RATIO = 1200 / 700

-- Tall enough for wrapped explainer + footer under the grid without clipping (see SetClipsChildren on frame).
S.FRAME_WIDTH = 490
S.FRAME_HEIGHT = 540
