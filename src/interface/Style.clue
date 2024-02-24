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

local style = {}

/**
 * Theme for board. Colors were taked from Lichess Pretier extension:
 *    https://prettierlichess.github.io/
 */
style.board = {
    check = assets::convertHex2ImVec4("AB4249"),
    arrow = assets::convertHex2ImVec4("A0DAB4"),

    [CHESS_SIDE_WHITE] = {
        background  = assets::convertHex2ImVec4("C7C7C7"),
        active      = assets::convertHex2ImVec4("BDCABE"),
        moveTo      = assets::convertHex2ImVec4("608977"),
        lastMove    = assets::convertHex2ImVec4("B4CDB6")
    }, [CHESS_SIDE_BLACK] = {
        background  = assets::convertHex2ImVec4("71828F"),
        active      = assets::convertHex2ImVec4("799392"),
        moveTo      = assets::convertHex2ImVec4("9CB99E"),
        lastMove    = assets::convertHex2ImVec4("81A395")
    }
}

/**
 * Globally apply the ImGui theme. **Only for use in `imgui.OnInitialize`!**
 * @return void
 */
method style::apply() {
    local style, colors, color = imgui.GetStyle(), imgui.GetStyle().Colors, imgui.Col
    local ImVec2, ImVec4 = imgui.ImVec2, imgui.ImVec4

    imgui.SwitchContext()
    style.WindowPadding     = ImVec2(0, 0)
    style.FramePadding      = ImVec2(5, 5)
    style.ItemSpacing       = ImVec2(5, 5)
    style.ItemInnerSpacing  = ImVec2(0, 0)
    style.TouchExtraPadding = ImVec2(0, 0)
    style.IndentSpacing     = 0
    style.ScrollbarSize     = 10
    style.GrabMinSize       = 10

    style.WindowBorderSize = 0
    style.ChildBorderSize  = 0
    style.PopupBorderSize  = 1
    style.FrameBorderSize  = 1
    style.TabBorderSize    = 1

    style.WindowRounding    = 8
    style.ChildRounding     = 8
    style.FrameRounding     = 5
    style.PopupRounding     = 5
    style.ScrollbarRounding = 5
    style.GrabRounding      = 5
    style.TabRounding       = 5

    style.ButtonTextAlign     = ImVec2(0.5, 0.5)
    style.SelectableTextAlign = ImVec2(0.5, 0.5)

    colors[color.Text]                  = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[color.TextDisabled]          = ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[color.WindowBg]              = assets::convertHex2ImVec4("222222")
    colors[color.ChildBg]               = assets::convertHex2ImVec4("2B2B2B")
    colors[color.PopupBg]               = assets::convertHex2ImVec4("222222")
    colors[color.Border]                = ImVec4(0.25, 0.25, 0.26, 0.54)
    colors[color.BorderShadow]          = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[color.FrameBg]               = assets::convertHex2ImVec4("424242")
    colors[color.FrameBgHovered]        = assets::convertHex2ImVec4("2B2B2B")
    colors[color.FrameBgActive]         = assets::convertHex2ImVec4("555554")
    colors[color.TitleBg]               = ImVec4(0.12, 0.12, 0.12, 1.00)
    colors[color.TitleBgActive]         = ImVec4(0.12, 0.12, 0.12, 1.00)
    colors[color.TitleBgCollapsed]      = ImVec4(0.12, 0.12, 0.12, 1.00)
    colors[color.MenuBarBg]             = ImVec4(0.12, 0.12, 0.12, 1.00)
    colors[color.ScrollbarBg]           = ImVec4(0.12, 0.12, 0.12, 1.00)
    colors[color.ScrollbarGrab]         = assets::convertHex2ImVec4("424242")
    colors[color.ScrollbarGrabHovered]  = assets::convertHex2ImVec4("555554")
    colors[color.ScrollbarGrabActive]   = assets::convertHex2ImVec4("333333")
    colors[color.CheckMark]             = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[color.SliderGrab]            = assets::convertHex2ImVec4("222222")
    colors[color.SliderGrabActive]      = assets::convertHex2ImVec4("222222")
    colors[color.Button]                = assets::convertHex2ImVec4("424242")
    colors[color.ButtonHovered]         = assets::convertHex2ImVec4("555554")
    colors[color.ButtonActive]          = assets::convertHex2ImVec4("333333")
    colors[color.Header]                = assets::convertHex2ImVec4("5B5B5B")
    colors[color.HeaderHovered]         = assets::convertHex2ImVec4("838383")
    colors[color.HeaderActive]          = assets::convertHex2ImVec4("424242")
    colors[color.ResizeGrip]            = ImVec4(1.00, 1.00, 1.00, 0.25)
    colors[color.ResizeGripHovered]     = ImVec4(1.00, 1.00, 1.00, 0.67)
    colors[color.ResizeGripActive]      = ImVec4(1.00, 1.00, 1.00, 0.95)
    colors[color.Tab]                   = ImVec4(0.12, 0.12, 0.12, 1.00)
    colors[color.TabHovered]            = ImVec4(0.28, 0.28, 0.28, 1.00)
    colors[color.TabActive]             = ImVec4(0.30, 0.30, 0.30, 1.00)
    colors[color.TabUnfocused]          = ImVec4(0.07, 0.10, 0.15, 0.97)
    colors[color.TabUnfocusedActive]    = ImVec4(0.14, 0.26, 0.42, 1.00)
    colors[color.PlotLines]             = ImVec4(0.61, 0.61, 0.61, 1.00)
    colors[color.PlotLinesHovered]      = ImVec4(1.00, 0.43, 0.35, 1.00)
    colors[color.PlotHistogram]         = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[color.PlotHistogramHovered]  = ImVec4(1.00, 0.60, 0.00, 1.00)
    colors[color.TextSelectedBg]        = ImVec4(1.00, 0.00, 0.00, 0.35)
    colors[color.DragDropTarget]        = ImVec4(1.00, 1.00, 0.00, 0.90)
    colors[color.NavHighlight]          = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[color.NavWindowingHighlight] = ImVec4(1.00, 1.00, 1.00, 0.70)
    colors[color.NavWindowingDimBg]     = ImVec4(0.80, 0.80, 0.80, 0.20)
    colors[color.ModalWindowDimBg]      = ImVec4(0.00, 0.00, 0.00, 0.70)
}

return style
