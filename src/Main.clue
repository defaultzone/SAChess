/**
 * SAChess - MoonLoader script that implements Lichess API.
 * Copyright (C) 2024 defaultzone.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * SDPX-License-Identifier: GPL-3.0-only
 */

@import "interface.Style" => style
@import "Compressed"      => compressed
@import "Timers"          => timers

@define SACHESS_VERSION "1.0"

static ffi      = require("ffi")
static imgui    = require("mimgui")
static wm       = require("windows.message")
static effil    = require("effil")
static encoding = require("encoding")
static u8       = encoding.UTF8

require("moonloader")

imgui.OnInitialize(fn {
    imgui.GetIO().IniFilename = nil

    local  glyphRanges = imgui.GetIO().Fonts::GetGlyphRangesCyrillic()
    global bold10      = imgui.GetIO().Fonts::AddFontFromMemoryCompressedBase85TTF(compressed.fonts.cantarellBold, 16.0, nil, glyphRanges)
    global bold9       = imgui.GetIO().Fonts::AddFontFromMemoryCompressedBase85TTF(compressed.fonts.cantarellBold, 14.0, nil, glyphRanges)
    global bold12      = imgui.GetIO().Fonts::AddFontFromMemoryCompressedBase85TTF(compressed.fonts.cantarellBold, 16.0, nil, glyphRanges)
    global bold14      = imgui.GetIO().Fonts::AddFontFromMemoryCompressedBase85TTF(compressed.fonts.cantarellBold, 20.0, nil, glyphRanges)
    global regular9    = imgui.GetIO().Fonts::AddFontFromMemoryCompressedBase85TTF(compressed.fonts.cantarellRegular, 14.0, nil, glyphRanges)
    global regular10   = imgui.GetIO().Fonts::AddFontFromMemoryCompressedBase85TTF(compressed.fonts.cantarellRegular, 15.5, nil, glyphRanges)
    global regular12   = imgui.GetIO().Fonts::AddFontFromMemoryCompressedBase85TTF(compressed.fonts.cantarellRegular, 16.0, nil, glyphRanges)

    global cburnett = imgui.CreateTextureFromFileInMemory(
        imgui.new("const char*", compressed.assets.pieces.cburnett),
        #compressed.assets.pieces.cburnett
    )

    style::apply()
})

global fn onWindowMessage(event, wparam) {
    if (event == wm.WM_KEYDOWN || event == wm.WM_SYSKEYDOWN) && wparam == VK_ESCAPE && mainWindowState {
        mainWindowState = false
        consumeWindowMessage(true, false)
        return
    }
}

global fn main() {
    while !isSampAvailable() { wait(0) }
    
    encoding.default = "CP1251"

    sampRegisterChatCommand("sachess.open", fn { mainWindowState = !$ })

    loop {
        wait(0)

        timers::initialize()
    
        if isKeyJustPressed(VK_F2) {
            mainWindowState = !$
        }
    }
}
