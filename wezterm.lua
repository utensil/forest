-- Pull in the wezterm API
local wezterm = require "wezterm"

-- This will hold the configuration.
local config = wezterm.config_builder()

config.font = wezterm.font "FiraCode Nerd Font Mono"
config.font_size = 16.0

config.color_scheme = "Railscasts (base16)"

config.inactive_pane_hsb = {
    saturation = 0.9,
    brightness = 0.8,
}

-- config.window_background_opacity = 0.5
--
-- Choose one from https://wallpaperaccess.com/4k-mountain
config.window_background_image = "/Users/utensil/Pictures/mountain.jpg"

config.window_background_image_hsb = {
    -- Darken the background image by reducing it
    brightness = 0.03,

    -- You can adjust the hue by scaling its value.
    -- a multiplier of 1.0 leaves the value unchanged.
    hue = 1.0,

    -- You can adjust the saturation also.
    saturation = 1.0,
}

config.default_cwd = "/Users/utensil/projects/forest"

config.window_frame = {
    -- The font used in the tab bar.
    -- Roboto Bold is the default; this font is bundled
    -- with wezterm.
    -- Whatever font is selected here, it will have the
    -- main font setting appended to it to pick up any
    -- fallback fonts you may have used there.
    font = wezterm.font { family = "FiraCode Nerd Font Mono", weight = "Bold" },

    -- The size of the font in the tab bar.
    -- Default to 10.0 on Windows but 12.0 on other systems
    font_size = 16.0,

    -- The overall background color of the tab bar when
    -- the window is focused
    -- active_titlebar_bg = '#333333',

    -- The overall background color of the tab bar when
    -- the window is not focused
    --[[   inactive_titlebar_bg = '#333333', ]]
}

-- Ctrl+Alt+Shift+5 to split horizontally, +" to split vertically
-- Ctrl+Shift+arrow keys to move between panes
config.keys = {
    {
        key = "w",
        mods = "CMD",
        action = wezterm.action.CloseCurrentPane { confirm = true },
    },
}

-- and finally, return the configuration to wezterm
return config
