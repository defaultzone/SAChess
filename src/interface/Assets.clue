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

local assets = { token = {} }

/**
 * Translation of RGB (or RGBA) string color into ImVec4 format.
 *
 * @param hex string    RGB (or RGBA) represented as a string in decimal format.
 * @param alpha number  Last argument in ImVec4, by default it's `255`.
 * @return ImVec4
 */
method assets::convertHex2ImVec4(hex, alpha = 255) {
    local rgb = tonumber(hex, 16)
    local r, g, b, a

    if (#hex == 6) {
        r = (rgb >> 16) & 255
        g = (rgb >> 8) & 255
        b = rgb & 255
        a = alpha
    } elseif (#hex == 8) {
        r, g, b, a = assets::explodeARGB(rgb) 
    }

    return imgui.ImVec4(r / 255, g / 255, b / 255, a / 255)
}

/**
 * Get MM:SS from given milliseconds.
 * @param milliSeconds number
 * @return string
 */
method assets::getRenderedSeconds(milliSeconds) {
    local totalSeconds = milliSeconds / 1000
    local minutes      = math.floor(totalSeconds / 60)
    local seconds      = totalSeconds % 60
    return string.format("%02d:%02d", minutes, seconds)
}

/**
 * Drawing imgui text with a specific font, optionally with a position.
 *
 * @param text string
 * @param font ImFont
 * @param pos ImVec2
 * @return void
 */
 method assets::textWithFont(text, font, pos, color = imgui.GetStyle().Colors[imgui.Col.Text]) {
    imgui.PushFont(font)
        if pos { imgui.SetCursorPos(pos) }
        imgui.TextColored(color, tostring(text))
    imgui.PopFont()
}

/**
 * Bring float from first to second float.
 *
 * @param from number
 * @param to number
 * @param startTime number os.clock()
 * @param duration number
 * @return number, boolean 
 */
method assets::bringFloatTo(from, to, startTime, duration) {
    local timer = os.clock() - startTime
    if timer >= 0.00 && timer <= duration {
        local count = timer / (duration / 100)
        return from + (count * (to - from) / 100), true
    }
    return ((timer > duration) ? to : from), false
}

/**
 * Bring ImVec2 from first to second ImVec2.
 *
 * @param from ImVec2
 * @param second ImVec2
 * @param startTime number os.clock()
 * @param duration number
 * @return number, boolean
 */
method assets::bringVec2To(from, to, startTime, duration) {
    local timer = os.clock() - startTime
    if timer >= 0.00 && timer <= duration {
        local count = timer / (duration / 100)
        return imgui.ImVec2(
            from.x + (count * (to.x - from.x) / 100),
            from.y + (count * (to.y - from.y) / 100)
        ), true
    }
    return ((timer > duration) ? to : from), false
}

/**
 * Bring ImVec4 from first to second ImVec4
 *
 * @param from ImVec4
 * @param to ImVec4
 * @param startTime number os.clock()
 * @param duration number
 * @return number, boolean
 */
method assets::bringVec4To(from, to, startTime, duration) {
    local timer = os.clock() - startTime
    if timer >= 0.00 && timer <= duration {
        local count = timer / (duration / 100)
        return imgui.ImVec4(
            from.x + (count * (to.x - from.x) / 100),
            from.y + (count * (to.y - from.y) / 100),
            from.z + (count * (to.z - from.z) / 100),
            from.w + (count * (to.w - from.w) / 100)
        ), true
    }
    return ((timer > duration) ? to : from), false
}

/**
 * Get previously saved (or not) token from `$PWD/SAChessToken.txt`.
 * @return string
 */
method assets.token::get() {
    if doesFileExist(getWorkingDirectory() .. "/SAChessToken.txt") {
        local handle = io.open(getWorkingDirectory() .. "/SAChessToken.txt", "r")
        local token  = handle::read("*all")
        handle::close()
        return token
    }
    return ""
}

/**
 * Save `token` in `$PWD/SAChessToken.txt`.
 * @param token string
 * @return void
 */
method assets.token::save(token) {
    local handle, error = io.open(getWorkingDirectory() .. "/SAChessToken.txt", "w")
    if !error {
        handle::write(token)
        handle::close()
    }
}

return assets
