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

@import "chess.engine.Board"  => Board
@import "chess.engine.Models" => models
@import "chess.engine.Setup"  => setup

@import "chess.network.EventStreamer" => EventStreamer
@import "chess.network.UserProfile"   => UserProfile
@import "chess.network.BoardStreamer" => BoardStreamer

@import "interface.Animations" => animations
@import "interface.Assets"     => assets

static mainWindowState = false

local sizeX, sizeY = getScreenResolution()
local interface    = {
    boardStreamer = nil,
    eventStreamer = nil,
    board         = Board::new(setup.from::forsythEdwardsNotation(CHESS_SIDE_WHITE)),
    canOfferDraw  = true,
    flags         = imgui.WindowFlags.NoDecoration + imgui.WindowFlags.NoMove,
    returning     = nil,
    
    profile       = UserProfile::new(assets.token::get()),
    token         = assets.token::get(),
    tokenInput    = imgui.new.char[144](),
    badTokenClock = nil,

    rightMenu = {
        chatInput = imgui.new.char[1024](),
        body      = {
            alpha = 1.00,
            flags = imgui.WindowFlags.NoBackground,
            clock = nil
        },

        gameSearch = {
            clock = nil,
            alpha = 1.00
        }
    }
}

if string.find(interface.token, "^lip_") {
    interface.profile::update()
}

/**
 * Reset settings after game is finished.
 * @return void
 */
method interface::resetGameSettings() {
    self.boardStreamer  = nil
    self.canOfferDraw   = true
    self.board          = Board::new(setup.from::forsythEdwardsNotation(CHESS_SIDE_WHITE))
    self.rightMenu.body = {
        alpha = 1.00,
        flags = imgui.WindowFlags.NoBackground,
        clock = nil
    }

    self.profile::update()
}

/**
 * Handle opponent draw offers. If opponent is offered the draw - then it will be showed and
 * user then can select option: accept or decline.
 *
 * @return void
 */
method interface::handleDrawOffers() {
    if local offer = self.board.streamer?.information.offers.draw {
        if offer.on != 0 {
            // We can offer draw after 13 moves after declined draw.
            self.canOfferDraw = #self.board.moves >= (offer.on + 26)
        }

        local userSide  = (self.board.userSide == CHESS_SIDE_WHITE) ? "white" : "black"
        local fullWidth = imgui.GetWindowWidth() - imgui.GetCursorPos().x - imgui.GetStyle().WindowPadding.x - 10
        local size      = imgui.ImVec2(fullWidth, 331)
        local pos       = imgui.GetItemRectMin() + imgui.ImVec2(10, 0)
        local duration  = 1.5

        if offer.state != "none" && offer.show {
            if self.rightMenu.body.alpha != 1.00 {
                imgui.SetCursorPos(pos - imgui.GetWindowPos())
                imgui.BeginChild("interface.windows.Main.drawOffersHandler", size, false, imgui.WindowFlags.NoBackground)
                    imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, 1.00 - self.rightMenu.body.alpha)
                        imgui.PushFont(bold10)
                            local itemSpacing   = imgui.GetStyle().ItemSpacing
                            local text          = "Оппонент предложил ничью"
                            local textSize      = imgui.CalcTextSize(text)
                            local buttonSize    = imgui.ImVec2(textSize.x, 25)
                            local setOfferState = fn (state) {
                                offer.state = (state) ? "accepted" : "declined"
                                offer.by    = (state) ? $ : userSide
                                offer.clock = os.clock()
                                self.board.streamer::handleDrawOffer(state)
                            }

                            imgui.SetCursorPos(imgui.ImVec2((size.x - textSize.x) / 2, (size.y - textSize.y - (buttonSize.y * 2) - itemSpacing.y) / 2))
                            imgui.BeginGroup()
                                imgui.Text(text)
                                if animations::button("Принять", buttonSize) { setOfferState(true) }
                                if animations::button("Отклонить", buttonSize) { setOfferState(false) }
                            imgui.EndGroup()
                        imgui.PopFont()
                    imgui.PopStyleVar()
                imgui.EndChild()
            }

            if offer.clock {
                if offer.state == "requested" || offer.state == "accepted" && userSide != offer.by {
                    self.rightMenu.body.flags = imgui.WindowFlags.NoBackground + imgui.WindowFlags.NoMouseInputs
                    self.rightMenu.body.alpha = assets::bringFloatTo($, match offer.state {
                        "requested" => 0.00,
                        "accepted"  => 1.00
                    }, offer.clock, duration)
                } elseif offer.state == "declined" && userSide == offer.by {
                    self.rightMenu.body.flags = imgui.WindowFlags.NoBackground
                    self.rightMenu.body.alpha = assets::bringFloatTo($, 1.00, offer.clock, duration)
                    if os.clock() - offer.clock >= duration {
                        offer.state = "none"
                        offer.by    = "none"
                        offer.clock = nil
                        offer.show  = false
                    }
                }
            }
        } else {
            self.rightMenu.body.flags = imgui.WindowFlags.NoBackground
        }
    }
}

imgui.OnFrame(fn { return mainWindowState }, fn {
    local id = "interface.windows.Main"

    imgui.SetNextWindowSize(imgui.ImVec2(650, 400))
    imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))

    imgui.Begin(id, nil, interface.flags)
        interface.flags = imgui.WindowFlags.NoDecoration + ((imgui.IsWindowHovered()) ? 0 : imgui.WindowFlags.NoMove)

        interface.board::render(id)
        imgui.SetCursorPos(imgui.GetCursorPos() + imgui.ImVec2(410, -390))

        local menuPaddingX  = 10
        local menuCursorPos = imgui.GetCursorPos()
        local menuWidth     = imgui.GetWindowWidth() - imgui.GetCursorPos().x

        if local clock = interface.returning {
            interface.rightMenu.gameSearch.alpha = assets::bringFloatTo($, 1.00, clock, 0.5)
            if os.clock() - clock >= 0.5 {
                interface.returning = nil
            }
        } elseif local clock = interface.boardStreamer?.information.game.fetched {
            interface.rightMenu.gameSearch.alpha = assets::bringFloatTo($, 1.00, clock, 0.5)
            interface.rightMenu.gameSearch.clock = nil
        } elseif local clock = interface.rightMenu.gameSearch.clock {
            interface.rightMenu.gameSearch.alpha = assets::bringFloatTo($, 0.00, clock, 0.5)
        }

        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, interface.rightMenu.gameSearch.alpha)
        imgui.BeginGroup()
            if interface.boardStreamer?.information.game.fetched {
                interface.board = interface.boardStreamer.board

                local streamer        = interface.board.streamer
                local fullWidth       = menuWidth - imgui.GetStyle().WindowPadding.x - menuPaddingX
                local opponentSide    = (interface.board.userSide == CHESS_SIDE_WHITE) ? "black" : "white"
                local userSide        = (interface.board.userSide == CHESS_SIDE_WHITE) ? "white" : "black"
                local gameSearchAlpha = interface.rightMenu.gameSearch.alpha 
                local bodyAlpha       = (gameSearchAlpha == 1.00) ? interface.rightMenu.body.alpha : gameSearchAlpha

                /**
                * Opponent nickname, his rating and his time for moves.
                */
                imgui.BeginGroup()
                    assets::textWithFont(streamer.information.players[opponentSide].name, bold14)
                    imgui.SameLine(nil, 5)
                    imgui.SetCursorPosY(imgui.GetCursorPos().y + 3)
                    assets::textWithFont(streamer.information.players[opponentSide].rating, regular12, nil, imgui.GetStyle().Colors[imgui.Col.TextDisabled])

                    imgui.SameLine()

                    imgui.PushFont(bold12)
                        local key  = string.sub(opponentSide, 1, 1) .. "time"
                        local time = assets::getRenderedSeconds(streamer.information.game.state[key])
                        imgui.SameLine(fullWidth - imgui.CalcTextSize(time).x)
                        imgui.Text(time)
                    imgui.PopFont()
                imgui.EndGroup()

                imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, bodyAlpha)
                    imgui.SetCursorPos(imgui.GetCursorPos() - imgui.ImVec2(10, 10))
                    imgui.BeginChild(id .. ".body", imgui.ImVec2(fullWidth + 20, 336), true, interface.rightMenu.body.flags)
                        imgui.SetCursorPos(imgui.ImVec2(10, 10))
                        imgui.BeginGroup()
                            /**
                            * Group with buttons for some actions during Lichess game:
                            * - resign/cancel game
                            * - offer/accept draw
                            */
                            imgui.BeginGroup()
                                imgui.PushFont(regular10)
                                    local canAbortGame     = #streamer.information.game.state.moves <= 5
                                    local firstButtonTitle = (canAbortGame) ? "Отменить игру" : "Сдаться"
                                    local hintText         = "Нельзя предложить ничью поскольку игру\nвсе еще можно отменить."

                                    if !interface.canOfferDraw {
                                        hintText = "Нельзя предложить ничью поскольку\nвы уже предлагали её недавно."
                                    }

                                    if animations::button(firstButtonTitle, imgui.ImVec2(fullWidth, 25))
                                        && !streamer.information.game.userResigned
                                    {
                                        if canAbortGame {
                                            streamer::abort()
                                        } else {
                                            streamer::resign()
                                        }
                                    }

                                    if animations::button("Предложить ничью", imgui.ImVec2(fullWidth, 25))
                                        && interface.canOfferDraw && !canAbortGame
                                    {
                                        streamer::handleDrawOffer(true)
                                    }

                                    animations::hint(hintText, fn {
                                        return imgui.IsItemHovered() && (!interface.canOfferDraw || canAbortGame)
                                    })
                                imgui.PopFont()
                            imgui.EndGroup()

                            /**
                            * This is chat messages of the current game. User can send message using InputText.
                            * * ENTER sends message.
                            */
                            imgui.BeginChild(id .. ".chatLines", imgui.ImVec2(fullWidth, 230), true)
                                local chatLines = streamer.information.game.chatLines
                                if #chatLines == 0 {
                                    imgui.PushFont(regular9)
                                        for index, line in ({ "Здесь будут отображаться", "сообщения в чате." }) {
                                            local lineSize = imgui.CalcTextSize(line)
                                            local size     = imgui.GetWindowSize()
                                                
                                            imgui.SetCursorPos(imgui.ImVec2((size.x - lineSize.x) / 2, (size.y - lineSize.y) / 2 + ((index - 1) * 15)))
                                            imgui.TextDisabled(line)
                                        }
                                    imgui.PopFont()
                                } else {
                                    imgui.SetCursorPos(imgui.ImVec2(5, 5))
                                    imgui.BeginGroup()
                                        for _, chatLine in chatLines {
                                            assets::textWithFont(chatLine.username .. ":", bold10)
                                            imgui.SameLine(nil, 2)
                                            imgui.SetCursorPosY(imgui.GetCursorPos().y + 1)
                                            imgui.PushFont(regular10)
                                                imgui.TextWrapped(chatLine.text)
                                            imgui.PopFont()
                                        }
                                    imgui.EndGroup()
                                }
                            imgui.EndChild()

                            imgui.PushFont(regular10)
                                imgui.SetNextItemWidth(fullWidth)
                                if imgui.InputTextWithHint(
                                    "##" .. id .. ".chatInput",
                                    "Отправка сообщения в чат",
                                    interface.rightMenu.chatInput,
                                    ffi.sizeof(interface.rightMenu.chatInput),
                                    imgui.InputTextFlags.EnterReturnsTrue
                                ) {
                                    streamer::writeInChat(ffi.string(interface.rightMenu.chatInput))
                                    imgui.StrCopy(interface.rightMenu.chatInput, "")
                                }
                            imgui.PopFont()
                        imgui.EndGroup()
                    imgui.EndChild()
                imgui.PopStyleVar()

                interface::handleDrawOffers()

                if streamer.information.game.status != GAME_STATUS_ACTIVE {
                    interface.rightMenu.body.clock ??= os.clock()
                    interface.rightMenu.body.alpha = assets::bringFloatTo($, 0.0, interface.rightMenu.body.clock, 0.5)

                    local size = imgui.ImVec2(fullWidth, 331)
                    local pos  = imgui.GetItemRectMin() + imgui.ImVec2(10, 0)
                    local text = match streamer.information.game.status {
                        GAME_STATUS_CHECKMATE   => "Поставлен мат.",
                        GAME_STATUS_DRAW        => "Ничья.",
                        GAME_STATUS_OUT_OF_TIME => "Кончилось время.",
                        GAME_STATUS_ABORTED     => "Игра отменена.",

                        GAME_STATUS_RESIGN if streamer.information.game.userResigned  => "Вы сдались.",
                        GAME_STATUS_RESIGN if !streamer.information.game.userResigned => "Оппонент сдался."
                    }

                    imgui.SetCursorPos(pos - imgui.GetWindowPos())
                    imgui.BeginChild("interface.windows.Main.drawOffersHandler", size, false, imgui.WindowFlags.NoBackground)
                        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, 1.00 - interface.rightMenu.body.alpha)
                            for index, line in ({ "Партия окончена", text }) {
                                imgui.PushFont((index == 1) ? bold14 : regular12)
                                    local lineSize = imgui.CalcTextSize(line)
                                    local size     = imgui.GetWindowSize()
                                    imgui.SetCursorPos(imgui.ImVec2((size.x - lineSize.x) / 2, (size.y - lineSize.y - 60) / 2 + ((index - 1) * 25)))
                                    imgui.Text(line)
                                imgui.PopFont()
                            }
                        imgui.PopStyleVar()

                        imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() / 2 - 75, imgui.GetCursorPos().y + 10))
                        imgui.PushFont(regular10)
                            if animations::button("Вернуться к подбору", imgui.ImVec2(150, 25), nil, { 0, 0, 0.4 }) {
                                interface.returning                  = os.clock()
                                interface.rightMenu.gameSearch.alpha = 0.00

                                interface::resetGameSettings()
                            }
                        imgui.PopFont()
                    imgui.EndChild()
                }

                imgui.SetCursorPosY(imgui.GetCursorPos().y + 1)

                /**
                * User nickname, his rating and his time to moves.
                */
                imgui.BeginGroup()
                    assets::textWithFont(streamer.information.players[userSide].name, bold14)
                    imgui.SameLine(nil, 5)
                    imgui.SetCursorPosY(imgui.GetCursorPos().y + 3)
                    assets::textWithFont(streamer.information.players[userSide].rating, regular12, nil, imgui.GetStyle().Colors[imgui.Col.TextDisabled])

                    imgui.SameLine()

                    imgui.PushFont(bold12)
                        local key  = string.sub(userSide, 1, 1) .. "time"
                        local time = assets::getRenderedSeconds(streamer.information.game.state[key])
                        imgui.SameLine(fullWidth - imgui.CalcTextSize(time).x)
                        imgui.Text(time)
                    imgui.PopFont()
                imgui.EndGroup()
            } elseif !string.find(interface.token, "^lip_") {
                for index, line in ({
                    "Необходим токен", "Для корректной работы скрипта", "необходим токен от Lichess API"
                }) {
                    imgui.PushFont((index == 1) ? bold14 : regular12)
                        local lineSize = imgui.CalcTextSize(line)
                        local size     = imgui.ImVec2(menuWidth - menuPaddingX, imgui.GetWindowHeight())
                        local pos      = imgui.ImVec2((size.x - lineSize.x) / 2, (size.y - lineSize.y - 120) / 2 + ((index - 1) * 20))
                    
                        imgui.SetCursorPos(menuCursorPos + pos)
                        imgui.Text(line)
                    imgui.PopFont()
                }

                local size = imgui.ImVec2(imgui.GetItemRectMax().x - imgui.GetItemRectMin().x, 25)

                imgui.SetCursorPos(imgui.ImVec2(imgui.GetItemRectMin().x - imgui.GetWindowPos().x, imgui.GetCursorPos().y + 3))
                imgui.BeginGroup()
                    imgui.PushFont(regular12)
                        imgui.SetNextItemWidth(size.x)
                        imgui.InputTextWithHint("##checkToken", "Введите токен", interface.tokenInput, ffi.sizeof(interface.tokenInput))

                        if animations::button("Проверить", size) {
                            local token = ffi.string(interface.tokenInput)
                            if string.find(token, "^lip_") {
                                local userProfile = UserProfile::new(token)
                                userProfile::update(fn {
                                    interface.token   = token
                                    interface.profile = userProfile
                                    assets.token::save(token)
                                }, fn {
                                    interface.badTokenClock = os.clock()
                                })
                            } else {
                                interface.badTokenClock = os.clock()
                            }
                        }

                        if interface.badTokenClock {
                            animations::hint("Неверный токен.\nУбедитесь, что вы правильно вставили токен и что он начинается с lip_", fn {
                                return os.clock() - interface.badTokenClock <= 3.5
                            })
                        }
                    imgui.PopFont()
                imgui.EndGroup()
            } else {
                local centerTextSize = imgui.ImVec2(0, 0)
                {
                    centerTextSize   += bold14::CalcTextSizeA(bold14.FontSize, math.huge, 0.0, "SAChess")
                    centerTextSize.x += 4
                    centerTextSize   += regular12::CalcTextSizeA(regular12.FontSize, math.huge, 0.0, "v" .. $SACHESS_VERSION)
                }

                local gameSearchFlags = (interface.eventStreamer) ? imgui.WindowFlags.NoMouseInputs : 0

                imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, interface.rightMenu.gameSearch.alpha)
                    imgui.SetCursorPos(menuCursorPos + imgui.ImVec2((menuWidth - centerTextSize.x) / 2, 0))
                    imgui.BeginGroup()
                        assets::textWithFont("SAChess", bold14)
                        imgui.SameLine(nil, 4)
                        imgui.SetCursorPosY(imgui.GetCursorPos().y + 3)
                        assets::textWithFont("v" .. $SACHESS_VERSION, regular12)
                    imgui.EndGroup()

                    imgui.BeginGroup()
                        assets::textWithFont("Ваш профиль", bold12)
                        imgui.SameLine(nil, 5)
                        assets::textWithFont(
                            string.format("(никнейм: %s)", interface.profile.username),
                            regular12,
                            nil,
                            imgui.GetStyle().Colors[imgui.Col.TextDisabled]
                        )
                        
                        assets::textWithFont("Рейтинги", bold12)

                        for _, perf in ({
                            { key = "bullet", title = "Пуля" },
                            { key = "blitz", title = "Блиц" },
                            { key = "rapid", title = "Рапид" },
                            { key = "classical", title = "Классика" }
                        }) {
                            imgui.Bullet()
                            imgui.SetCursorPosY(imgui.GetCursorPos().y - 2)
                            assets::textWithFont(perf.title, bold10)
                            imgui.SameLine()
                            imgui.SetCursorPosY(imgui.GetCursorPos().y + 2)
                            assets::textWithFont(interface.profile.ratings[perf.key], regular10)
                        }

                        assets::textWithFont("Статистика игр", bold12)
                        imgui.SameLine()
                        assets::textWithFont(
                            string.format("(всего: %d)", interface.profile.games.all),
                            regular12,
                            nil,
                            imgui.GetStyle().Colors[imgui.Col.TextDisabled]
                        )

                        for index, type in ({
                            { key = "win", title = "Побед:" },
                            { key = "loss", title = "Проигрышей:" },
                            { key = "draw", title = "Ничьих:" }
                        }) {
                            assets::textWithFont(type.title, bold9)
                            imgui.SameLine(nil, 2)
                            assets::textWithFont(interface.profile.games[type.key], regular9)
                            imgui.SameLine()
                        }
                    imgui.EndGroup()

                    imgui.SetCursorPosY(imgui.GetCursorPos().y + 4)

                    imgui.BeginChild(id .. ".gameSearch", imgui.ImVec2(menuWidth - menuPaddingX, 183), true, gameSearchFlags)
                        imgui.SetCursorPos(imgui.ImVec2(6, 6))
                        imgui.BeginGroup()
                            imgui.PushFont(bold10)
                                assets::textWithFont("Поиск игры", bold12)
                                for _, time in ({
                                    { start = 10, increment = 0 },
                                    { start = 10, increment = 5 },
                                    { start = 15, increment = 10 },
                                    { start = 30, increment = 0 },
                                    { start = 30, increment = 20 }
                                }) {
                                    if animations::button(
                                        string.format("%d + %d", time.start, time.increment),
                                        imgui.ImVec2(menuWidth - menuPaddingX - 12, 26),
                                        nil,
                                        { 0, 0, 0.4 }
                                    ) && !interface.eventStreamer {
                                        interface.eventStreamer              = EventStreamer::new(interface.token)
                                        interface.rightMenu.gameSearch.clock = os.clock()

                                        interface.eventStreamer::onReceiveEvent(fn (event) {
                                            if event.type == "gameStart" && interface.eventStreamer {
                                                local side                    = (event.game.color == "white") ? CHESS_SIDE_WHITE : CHESS_SIDE_BLACK
                                                local board                   = Board::new(setup.from::forsythEdwardsNotation(side))
                                                      interface.boardStreamer = BoardStreamer::new(interface.token, event.game.id, board)

                                                interface.boardStreamer::stream(true)
                                                interface.eventStreamer::stop()
                                
                                                interface.eventStreamer = nil
                                            }
                                        })

                                        interface.eventStreamer::start()

                                        interface.eventStreamer::createSeek({
                                            rated     = true,
                                            time      = time.start,
                                            increment = time.increment,
                                            variant   = "standard"
                                        })
                                    }
                                }
                            imgui.PopFont()
                        imgui.EndGroup()
                    imgui.EndChild()
                imgui.PopStyleVar()
            }
        imgui.EndGroup()
        imgui.PopStyleVar()

        if interface.rightMenu.gameSearch.clock {
            imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, 1.00 - interface.rightMenu.gameSearch.alpha)
                for index, line in ({
                    "Начат поиск соперника",
                    string.format("%0.f секунд назад.", os.clock() - interface.rightMenu.gameSearch.clock)
                }) {
                    imgui.PushFont((index == 1) ? bold14 : regular12)
                        local lineSize = imgui.CalcTextSize(line)
                        local size     = imgui.ImVec2(menuWidth - menuPaddingX, imgui.GetWindowHeight())
                        local pos      = imgui.ImVec2((size.x - lineSize.x) / 2, (size.y - lineSize.y - 40) / 2 + ((index - 1) * 20))
                    
                        imgui.SetCursorPos(menuCursorPos + pos)
                        imgui.Text(line)
                    imgui.PopFont()
                }
            imgui.PopStyleVar()
        }
    imgui.End()
})