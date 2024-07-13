local QBCore = exports['qb-core']:GetCoreObject()

local ticketHolders = {}
local lastDrawTime = 0

-- Load ticket holders from the database
MySQL.ready(function()
    MySQL.Async.fetchAll('SELECT * FROM lottery_tickets', {}, function(result)
        if result then
            for _, v in pairs(result) do
                table.insert(ticketHolders, {source = v.source, identifier = v.identifier})
            end
        end
    end)
end)

-- Event to purchase lottery ticket
RegisterNetEvent('qb-lottery:buyTicket')
AddEventHandler('qb-lottery:buyTicket', function()
    local _source = source
    local xPlayer = QBCore.Functions.GetPlayer(_source)

    -- Check if the player has already bought a ticket
    for _, holder in ipairs(ticketHolders) do
        if holder.identifier == xPlayer.PlayerData.citizenid then
            TriggerClientEvent('QBCore:Notify', _source, "You have already bought a ticket!", "error")
            return
        end
    end

    -- Check if it's within the cooldown period
    local currentTime = os.time()
    if currentTime < lastDrawTime + Config.CooldownPeriod then
        TriggerClientEvent('QBCore:Notify', _source, "You can't buy a ticket yet. Please wait until the cooldown period is over.", "error")
        return
    end

    if xPlayer.Functions.RemoveMoney("cash", Config.TicketPrice) then
        table.insert(ticketHolders, {source = _source, identifier = xPlayer.PlayerData.citizenid})
        MySQL.Async.execute('INSERT INTO lottery_tickets (source, identifier) VALUES (@source, @identifier)', {
            ['@source'] = _source,
            ['@identifier'] = xPlayer.PlayerData.citizenid
        })
        TriggerClientEvent('QBCore:Notify', _source, "You bought a lottery ticket!")
    else
        TriggerClientEvent('QBCore:Notify', _source, "You don't have enough money!", "error")
    end
end)

-- Function to draw the lottery
local function drawLottery()
    if #ticketHolders > 0 then
        local winnerIndex = math.random(1, #ticketHolders)
        local winner = ticketHolders[winnerIndex]
        local xPlayer = QBCore.Functions.GetPlayer(winner.source)

        -- Announce the winner in chat
        TriggerClientEvent('chatMessage', -1, "Lottery", {255, 0, 0}, "The lottery winner is " .. (xPlayer and (xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname) or "an offline player") .. "!")

        -- Send a webhook to Discord
        if Config.EnableTestWebhook then
            local embedContent = {
                {
                    ["title"] = "Lottery Winner",
                    ["description"] = "The lottery winner is " .. (xPlayer and (xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname) or "an offline player") .. " and won $" .. Config.PrizeAmount,
                    ["color"] = 16711680, -- Red color
                    ["footer"] = {
                        ["text"] = "Lottery System"
                    }
                }
            }
            PerformHttpRequest(Config.DiscordWebhookURL, function(err, text, headers) end, 'POST', json.encode({embeds = embedContent}), { ['Content-Type'] = 'application/json' })
        end

        -- Store the winner
        MySQL.Async.execute('DELETE FROM lottery_tickets WHERE identifier = @identifier', {
            ['@identifier'] = winner.identifier
        })
        if xPlayer then
            xPlayer.Functions.AddMoney("cash", Config.PrizeAmount)
            TriggerClientEvent('QBCore:Notify', winner.source, "You received $" .. Config.PrizeAmount .. " in cash!")
        else
            -- Handle offline player winning
            MySQL.Async.execute('INSERT INTO lottery_winners (identifier, prize) VALUES (@identifier, @prize)', {
                ['@identifier'] = winner.identifier,
                ['@prize'] = Config.PrizeAmount
            })
        end
        ticketHolders = {}
        lastDrawTime = os.time()
    else
        TriggerClientEvent('chatMessage', -1, "Lottery", {255, 0, 0}, "No one bought lottery tickets today.")
    end
end

-- Daily lottery draw
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000) -- Check every minute

        local currentTime = os.date("%H:%M")
        if currentTime == Config.LotteryDrawTime then
            drawLottery()
        end
    end
end)

-- Admin command to test the lottery draw
QBCore.Commands.Add('test', 'Test the lottery draw (if enabled)', {}, false, function(source)
    if Config.EnableTestCommand then
        drawLottery()
    else
        TriggerClientEvent('QBCore:Notify', source, "Test command is disabled.", "error")
    end
end)

-- Command to claim prize for offline winners
RegisterNetEvent('qb-lottery:claimPrize')
AddEventHandler('qb-lottery:claimPrize', function()
    local _source = source
    local xPlayer = QBCore.Functions.GetPlayer(_source)
    local identifier = xPlayer.PlayerData.citizenid

    MySQL.Async.fetchAll('SELECT * FROM lottery_winners WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if result and #result > 0 then
            local prize = result[1].prize
            xPlayer.Functions.AddMoney("cash", prize)
            MySQL.Async.execute('DELETE FROM lottery_winners WHERE identifier = @identifier', {
                ['@identifier'] = identifier
            })
            TriggerClientEvent('QBCore:Notify', _source, "You received $" .. prize .. " in cash!")
        else
            TriggerClientEvent('QBCore:Notify', _source, "You don't have any prize to claim.", "error")
        end
    end)
end)
