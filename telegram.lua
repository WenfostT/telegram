-- telegram.lua
local telegram = {}

local effil = require("effil")
local encoding = require("encoding")
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local chat_id = ''
local token = ''
local updateid

function telegram.setConfig(id, t)
    chat_id = id
    token = t
end

local function encodeUrl(str)
    str = str:gsub(' ', '%+')
    str = str:gsub('\n', '%%0A')
    return u8:encode(str, 'CP1251')
end

local function requestRunner()
    return effil.thread(function(u, a)
        local https = require 'ssl.https'
        local ok, result = pcall(https.request, u, a)
        if ok then return {true, result} else return {false, result} end
    end)
end

local function async_http_request(url, args, resolve, reject)
    local runner = requestRunner()
    if not reject then reject = function() end end
    lua_thread.create(function()
        local t = runner(url, args)
        local r = t:get(0)
        while not r do
            r = t:get(0)
            wait(0)
        end
        local status = t:status()
        if status == 'completed' then
            local ok, result = r[1], r[2]
            if ok then resolve(result) else reject(result) end
        else
            reject(status)
        end
        t:cancel(0)
    end)
end

function telegram.sendMessage(msg)
    if not chat_id or not token then return end
    msg = msg:gsub('{......}', '')
    msg = encodeUrl(msg)
    async_http_request('https://api.telegram.org/bot' .. token .. '/sendMessage?chat_id=' .. chat_id .. '&text='..msg, '', function(result) end)
end

function telegram.getLastUpdate()
    async_http_request('https://api.telegram.org/bot'..token..'/getUpdates?chat_id='..chat_id..'&offset=-1','', function(result)
        if result then
            local proc_table = decodeJson(result)
            if proc_table.ok then
                if #proc_table.result > 0 then
                    updateid = proc_table.result[1].update_id
                else
                    updateid = 1
                end
            end
        end
    end)
end

return telegram
