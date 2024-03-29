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

@import "interface.Assets" => assets

local animations = {}

/**
 * Get Limit number between `min` and `max` (`min` < `v` < `max`).
 * @return number
 */
method animations::limit(v, min = 0.0, max = 1.0) {
    return (v < min) ? min : ((v > max) ? max : v)
}

/**
 * Get contrast color (`colorA` or `colorB`) based on `backgroundColor`.
 *
 * @param backgroundColor ImVec4
 * @param colorA ImVec4
 * @param colorB ImVec4
 * @return ImVec4
 */
method animations::getContrastColor(
    backgroundColor,
    colorA = imgui.ImVec4(0, 0, 0, 1),
    colorB = imgui.ImVec4(1, 1, 1, 1)
) {
    return ((1 - (0.299 * backgroundColor.x + 0.587 * backgroundColor.y + 0.114 * backgroundColor.z)) < 0.5) 
        ? colorA
        : colorB
}

/**
 * Render custom button.
 * 
 * @author https://github.com/Vadim-Kamalov/GAdmin/blob/main/src/imgui/Animations.clue
 *
 * @param label string
 * @param size ImVec2|nil
 * param onHoveredFlags number|nil
 * @param duration number[]
 * @param colors table<string, ImVec4>
 * @return boolean
 */
method animations::button(
    label,
    size,
    onHoveredFlags  = 15,
    duration        = { 0.2, 0.4, 0.3 },
    colors          = {
        def     = imgui.GetStyle().Colors[imgui.Col.Button],
        hovered = imgui.GetStyle().Colors[imgui.Col.ButtonHovered],
        active  = imgui.GetStyle().Colors[imgui.Col.ButtonActive],
        window  = imgui.GetStyle().Colors[imgui.Col.WindowBg]
    }
) {
    local result   = false
    local rounding = imgui.GetStyle().FrameRounding
    local id       = label

    for key, color of colors {
        colors[key] = imgui.ImVec4(color.x, color.y, color.z, imgui.GetStyle().Alpha)
    }
   
    if !UI_ANIMATED_BUTTON {
        global UI_ANIMATED_BUTTON = {}
    }

    if !UI_ANIMATED_BUTTON[id] {
        UI_ANIMATED_BUTTON[id] = {
            radius  = 0
            clock   = { 0, 0 }
            pos     = nil
            size    = nil
            hovered = {
                state   = false
                before  = nil
                clock   = 0
                color   = colors.hovered
            }
        }
    }

    local this     = UI_ANIMATED_BUTTON[id]
    local label    = string.gsub(label, "##.*$", "")
    local textSize = imgui.CalcTextSize(label)
    local p        = imgui.GetCursorScreenPos()

    if !size {
        local padding = imgui.GetStyle().FramePadding
        size = imgui.ImVec2(textSize.x + (padding.x * 2), textSize.y + (padding.y * 2))
    }

    local pos = imgui.GetCursorPos()
    local dl  = imgui.GetWindowDrawList()

    if this.size {
        this.hovered.color = match this.hovered.state {
            true => assets::bringVec4To($, colors.hovered, this.hovered.clock, duration[3]),
            false => assets::bringVec4To($, imgui.ImVec4(
                colors.hovered.x,
                colors.hovered.y,
                colors.hovered.z,
                0.0
            ), this.hovered.clock, duration[3])
        }

        dl::AddRectFilled(
            p - imgui.ImVec2(1, 1),
            imgui.ImVec2(p.x + size.x + 1, p.y + size.y + 1),
            imgui.ColorConvertFloat4ToU32(this.hovered.color),
            rounding,
            onHoveredFlags
        )
    }
    
    dl::AddRectFilled(p, p + size, imgui.ColorConvertFloat4ToU32(colors.def), rounding, onHoveredFlags)
    dl::PushClipRect(p + imgui.ImVec2(1, 1), p + size - imgui.ImVec2(1, 1))

    if this.pos {
        local alpha = 0.00

        local timer = os.clock() - this.clock[2]
        if timer <= duration[2] {
            alpha = self::limit(1.00 - ((1.00 / duration[2]) * timer), 0.0, 1.0)
        }

        local timer = os.clock() - this.clock[1]
        if timer <= duration[1] {
            alpha = self::limit((1.00 / duration[1]) * timer, 0.0, 1.0)
            this.radius = (size.x * 1.5 / duration[1]) * timer
        }

        local col = imgui.GetStyle().Colors[imgui.Col.ButtonActive]
        dl::AddCircleFilled(
            this.pos, 
            this.radius, 
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(col.x, col.y, col.z, alpha)), 
            0xFF
        )
            
        if alpha <= 0 { this.pos = nil }
    }

    dl::PopClipRect()

    local al = imgui.GetStyle().ButtonTextAlign
    imgui.SetCursorPos(imgui.ImVec2((size.x - textSize.x) * al.x, (size.y - textSize.y) * al.y) + pos)
    imgui.TextUnformatted(label)

    imgui.SetCursorPos(pos)
    if imgui.InvisibleButton(id .. ".UI_ANIMATED_BUTTON", size) {
        this.radius     = 0
        this.pos        = imgui.GetMousePos()
        this.clock      = { os.clock(), os.clock() + duration[1] }
        result          = true
    }

    this.size           = imgui.ImVec2(size.x + 2, size.y + 2)
    this.hovered.state  = imgui.IsItemHovered() || os.clock() - this.clock[2] < 0
    
    if this.hovered.state != this.hovered.before {
        this.hovered.before = this.hovered.state
        this.hovered.clock  = os.clock()
    }

    return result
}

/**
 * Render custom hint when user is hovering the previous element.
 *
 * @author https://github.com/Vadim-Kamalov/GAdmin/blob/main/src/imgui/Animations.clue 
 *
 * @param label string
 * @param hoverCallback (fun(): boolean)|nil (default = imgui.IsItemHovered)
 * @param duration number|nil
 * @param hintColor ImVec4|nil
 * @return void
 */
method animations::hint(
    label,
    hoverCallback = imgui.IsItemHovered,
    duration = 0.2,
    hintColor = imgui.GetStyle().Colors[imgui.Col.FrameBg]
) {
    local originalPos   = imgui.GetCursorPos()
    local hovered       = hoverCallback()
    local id            = label
    local show          = true
    label               = string.gsub($, "##.*", "")

    imgui.SameLine(nil, 0)

    if !UI_HINTS {
        global UI_HINTS = {}
    }

    if !UI_HINTS[id] {
        UI_HINTS[id] = {
            status  = false,
            timer   = 0
        }
    }

    for uiId, hint of UI_HINTS {
        if uiId != id && os.clock() - hint.timer <= duration {
            show = false
        }
    }

    if local this = UI_HINTS[id] {
        if show && this.status != hovered {
            this.status = hovered
            this.timer  = os.clock()
        }

        local fn render(alpha) {
            local size      = imgui.GetItemRectSize()
            local screenPos = imgui.GetCursorScreenPos()
            local dl        = imgui.GetWindowDrawList()
            local center    = imgui.ImVec2(screenPos.x - (size.x / 2), screenPos.y + (size.y / 2) - (alpha * 4) + 10)
            local a         = imgui.ImVec2(center.x - 7, center.y - size.y - 3)
            local b         = imgui.ImVec2(center.x + 7, center.y - size.y - 3)
            local c         = imgui.ImVec2(center.x, center.y - size.y + 3)
            local color     = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(hintColor.x, hintColor.y, hintColor.z, alpha))
            local flags     = imgui.WindowFlags.Tooltip + imgui.WindowFlags.NoResize 
                + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoTitleBar 

            dl::AddTriangleFilled(a, b, c, color)
            imgui.SetNextWindowPos(imgui.ImVec2(center.x, center.y - size.y - 3), imgui.Cond.Always, imgui.ImVec2(0.5, 1))
            imgui.PushStyleColor(imgui.Col.PopupBg, hintColor)
            imgui.PushStyleColor(imgui.Col.Border, hintColor)
            imgui.PushStyleColor(imgui.Col.Text, self::getContrastColor(hintColor))
		    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
		    imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 6)
		    imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, alpha)
                local fn maxWidth(text) {
                    local result = 0
                    for line with string.gmatch(text, "[^\n]+") {
                        if imgui.CalcTextSize(line).x > result {
                            result = imgui.CalcTextSize(line).x
                        }
                    }
                    return result
                }

                imgui.SetNextWindowSize(imgui.ImVec2(maxWidth(label) + imgui.GetStyle().WindowPadding.x * 2, -1), imgui.Cond.Always)
                imgui.Begin(id, nil, flags)
                    for line with string.gmatch(label, "[^\n]+") {
                        imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(line).x) / 2)
                        imgui.Text(line)
                    }
                imgui.End()
		    imgui.PopStyleVar(3)
		    imgui.PopStyleColor(3)
        }

        if show {
            local between = os.clock() - this.timer
            if between <= duration {
                render((hovered) ? self::limit(between / duration, 0.00, 1.00) : self::limit(1.00 - between / duration, 0.00, 1.00))
            } elseif hovered {
                render(1.00)
            }
        }
    }

    imgui.SetCursorPos(originalPos)
}

return animations