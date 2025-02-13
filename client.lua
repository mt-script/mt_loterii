Citizen.CreateThread(function()
    -- NPC setup
    RequestModel(GetHashKey("a_m_m_farmer_01"))
    while not HasModelLoaded(GetHashKey("a_m_m_farmer_01")) do
        Wait(1)
    end

    local npc = CreatePed(4, GetHashKey("a_m_m_farmer_01"), Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z, 3374176, false, true)
    SetEntityHeading(npc, 0)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)

    -- Register target for NPC
    exports['qb-target']:AddTargetModel(GetHashKey("a_m_m_farmer_01"), {
        options = {
            {
                type = "client",
                event = "qb-lottery:client:buyTicket",
                icon = "fas fa-ticket-alt",
                label = "Buy Lottery Ticket ($" .. Config.TicketPrice .. ")",
            },
        },
        distance = 2.5
    })
end)

RegisterNetEvent('qb-lottery:client:buyTicket')
AddEventHandler('qb-lottery:client:buyTicket', function()
    TriggerServerEvent('qb-lottery:buyTicket')
end)
