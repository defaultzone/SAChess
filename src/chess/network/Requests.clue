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

local requests = {}

/**
 * Convert `str` to `application/x-www-form-urlencoded` schema string.
 *
 * @param str string
 * @return string
 */
method requests::encodeURLString(str) {
    str = string.gsub(str, "\n", "\r\n")
    str = string.gsub(str, "([^%w ])", fn (c) { return string.format("%%%02X", string.byte(c)) })
    str = string.gsub(str, " ", "+")
    return str
}

/**
 * Send asynchronous HTTP request with specific method (`type`). 
 * Use this function only in the thread! (`lua_thread.create(fn { ... })`).
 *
 * @param type string
 * @param url string
 * @param args table<string, string|table>
 * @param resolve (fun(table): void)|nil
 * @param reject (fun(string): void)|nil
 * @return void
 */
method requests::asyncHttpRequest(type, url, args, resolve = fn {}, reject = fn {}) {
    local thread = effil.thread(fn (type, url, args) {
        local requests = require("requests")
        local result, response = pcall(requests.request, type, url, args)
        if result {
            response.json, response.xml = nil, nil
            return true, response
        } else {
            return false, response
        }
    })(type, url, args)
    
    loop {
        wait(0)
        local status, err = thread::status()

        if !err {
            if status == "completed" {
                local result, response = thread::get()
                return (result) ? resolve(response) : reject(response)
            }
        } elseif status == "canceled" {
            return reject(status)
        } else {
            return reject(err)
        }
    }
}

/**
 * Send POST request to the Lichess API.
 *
 * @param directive string
 * @param token string
 * @param reject (fun(table<string, string>): void)|nil
 * @param arguments table<string, string|table>|nil
 * @return void
 */
method requests::postLichess(directive, token, reject = fn {}, arguments = {}) {
    arguments.headers             ??= {}
    arguments.headers.Authorization = "Bearer " .. token

    local status = {}

    lua_thread.create(fn {
        self::asyncHttpRequest("POST", "https://lichess.org" .. directive, arguments, fn (response) {
            status.error = match response.status_code {
                400 || 404  => response.text,
                429         => "429 status code. Wait full minute before usaging API.",
                default     => nil
            }

            if status.error {
                reject(status)
            }
        }, fn (warning) {
            status.warning = warning
            reject(status)
        })
    })
}

return requests
