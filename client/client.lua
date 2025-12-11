-- =========================================================================================
-- Скрипт движения с автоприменением и системой стамины
-- =========================================================================================

-- *** NATIVE HASHES ***
local NATIVE_DEPLETION_MULTIPLIER = 0xEF5A3D2285D8924B
local NATIVE_RECHARGE_MULTIPLIER = 0x345C9F993A8AB4A4
local NATIVE_GET_STAMINA = 0x775A1CA7893AA8B5

-- *** ПЕРЕМЕННЫЕ СОСТОЯНИЯ ***
local currentIndex = Config.DefaultSpeedIndex
local currentSpeed = Config.Speeds[currentIndex].value
local isExhausted = false
local exhaustedEffectsActive = false
local isPlayerLoaded = false

-- ===================================
-- Функция получения стамины
-- ===================================

local function GetPlayerStamina()
    local ped = PlayerPedId()
    local stamina = Citizen.InvokeNative(NATIVE_GET_STAMINA, ped, Citizen.ResultAsFloat())
    return stamina or 100.0
end

-- ===================================
-- Функции управления выносливостью
-- ===================================

local function SetStaminaRates(depletion, recharge)
    local ped = PlayerPedId()
    Citizen.InvokeNative(NATIVE_DEPLETION_MULTIPLIER, ped, depletion + 0.0)
    Citizen.InvokeNative(NATIVE_RECHARGE_MULTIPLIER, ped, recharge + 0.0)
end

local function GetDepletionMultiplier(speedValue)
    if speedValue >= 2.1 then
        return Config.Stamina.runDepletion
    elseif speedValue >= 1.7 then
        return Config.Stamina.truscaDepletion
    else
        return Config.Stamina.normalDepletion
    end
end

-- ===================================
-- Эффекты истощения
-- ===================================

local function StartExhaustedEffects()
    if exhaustedEffectsActive then return end
    exhaustedEffectsActive = true
    
    CreateThread(function()
        while exhaustedEffectsActive do
            Wait(0)
            
            -- Эффект экрана
            if not AnimpostfxIsRunning(Config.Stamina.screenEffectName) then
                AnimpostfxPlay(Config.Stamina.screenEffectName)
            end
            
            -- Тряска камеры
            if not IsGameplayCamShaking() then
                ShakeGameplayCam("DRUNK_SHAKE", Config.Stamina.cameraShakeIntensity)
            end
        end
    end)
end

local function StopExhaustedEffects()
    exhaustedEffectsActive = false
    
    if AnimpostfxIsRunning(Config.Stamina.screenEffectName) then
        AnimpostfxStop(Config.Stamina.screenEffectName)
    end
    
    StopGameplayCamShaking(true)
end
-- ===================================
-- Уведомления
-- ===================================

local function SendNotification(message, notifyType)
    local icon = "generic_list"
    
    -- Выбираем иконку в зависимости от типа
    if notifyType == "warning" then
        icon = "generic_list"
    elseif notifyType == "warning" then
        icon = "generic_list"
    elseif notifyType == "warning" then
        icon = "generic_list"
    end
    
    TriggerEvent("bln_notify:send", {
        title = "Передвижение",
        description = message,
        icon = "warning",
        placement = "middle-left"
    })
end

local function NotifySpeed(speedData)
    local msg = string.format(Config.Notifications.speedChange, speedData.name)
    SendNotification(msg, "info")
end
local function NotifySpeed(speedData)
    local msg = string.format(Config.Notifications.speedChange, speedData.name)
    SendNotification(msg, "info")
end

-- ===================================
-- Применение скорости
-- ===================================

local function ApplySpeedToPed(ped, targetSpeed)
    local r = targetSpeed
    if r < 0.1 then r = 0.1 end
    if r > 3.0 then r = 3.0 end
    
    local isAiming = IsPlayerFreeAiming(PlayerId())
    local isMoving = IsPedWalking(ped) or IsPedRunning(ped) or IsPedSprinting(ped)
    
    if isAiming then
        r = 1.0
        SetStaminaRates(Config.Stamina.normalDepletion, Config.Stamina.normalRecharge)
    elseif targetSpeed >= 1.7 and isMoving then
        local depletion = GetDepletionMultiplier(targetSpeed)
        SetStaminaRates(depletion, Config.Stamina.movingRecharge)
        
        if targetSpeed >= 2.1 then
            Citizen.InvokeNative(0x6F498F5307DA19F9, ped, 1)
        end
    else
        SetStaminaRates(Config.Stamina.normalDepletion, Config.Stamina.normalRecharge)
    end
    
    SetPedMaxMoveBlendRatio(ped, r)
    Citizen.InvokeNative(0x085BF80FA50A39D1, ped, r)
end

-- ===================================
-- Управление состоянием скорости
-- ===================================

local function SetSpeedIndex(index, notify)
    if index < 1 then index = 1 end
    if index > #Config.Speeds then index = #Config.Speeds end
    
    currentIndex = index
    currentSpeed = Config.Speeds[currentIndex].value
    
    if notify then
        NotifySpeed(Config.Speeds[currentIndex])
    end
end

local function IncreaseSpeed()
    if isExhausted then
        SendNotification(Config.Notifications.cantSpeedUp, "error")
        return
    end
    
    if currentIndex < #Config.Speeds then
        SetSpeedIndex(currentIndex + 1, true)
    end
end

local function DecreaseSpeed()
    if currentIndex > 1 then
        SetSpeedIndex(currentIndex - 1, true)
    end
end

-- ===================================
-- Истощение
-- ===================================

local function EnterExhaustedState()
    if isExhausted then return end
    
    isExhausted = true
    SendNotification(Config.Notifications.exhausted, "warning")
    StartExhaustedEffects()
end

local function ExitExhaustedState()
    if not isExhausted then return end
    
    isExhausted = false
    StopExhaustedEffects()
    SendNotification(Config.Notifications.recovered, "success")
end

-- ===================================
-- Инициализация при загрузке персонажа
-- ===================================

local function InitializePlayer()
    isPlayerLoaded = true
    isExhausted = false
    exhaustedEffectsActive = false
    
    -- Устанавливаем начальную скорость
    SetSpeedIndex(Config.DefaultSpeedIndex, true)
    
    -- Сбрасываем множители стамины
    SetStaminaRates(Config.Stamina.normalDepletion, Config.Stamina.normalRecharge)
    
    print("[MovementSpeed] Система скорости инициализирована. Скорость: " .. Config.Speeds[currentIndex].name)
end

-- ===================================
-- События RSGCore
-- ===================================

RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    Wait(2000) -- Даем время на загрузку
    InitializePlayer()
end)

RegisterNetEvent('RSGCore:Client:OnPlayerUnload', function()
    isPlayerLoaded = false
    isExhausted = false
    StopExhaustedEffects()
end)

-- Альтернативное событие загрузки (на случай если RSGCore событие не сработает)
AddEventHandler('playerSpawned', function()
    if not isPlayerLoaded then
        Wait(3000)
        InitializePlayer()
    end
end)

-- ===================================
-- Основной поток
-- ===================================

CreateThread(function()
    -- Ждем загрузки игрока
    while not isPlayerLoaded do
        Wait(500)
        
        -- Проверяем, загружен ли персонаж
        local ped = PlayerPedId()
        if DoesEntityExist(ped) and not IsEntityDead(ped) then
            -- Если персонаж существует, но событие не сработало - инициализируем
            Wait(5000)
            if not isPlayerLoaded then
                InitializePlayer()
            end
        end
    end
    
    -- Основной цикл
    while true do
        Wait(0)
        
        local ped = PlayerPedId()
        
        if not DoesEntityExist(ped) or IsEntityDead(ped) then
            goto continue
        end
        
        -- *** Горячие клавиши ***
        if IsControlJustPressed(0, Config.Keys.speedUp) then
            IncreaseSpeed()
        elseif IsControlJustPressed(0, Config.Keys.speedDown) then
            DecreaseSpeed()
        end
        
        -- *** Проверка стамины ***
        local stamina = GetPlayerStamina()
        
        -- Вход в состояние истощения
        if stamina <= 0 and not isExhausted then
            EnterExhaustedState()
        end
        
        -- Выход из состояния истощения
        if stamina >= Config.Stamina.recoveryThreshold and isExhausted then
            ExitExhaustedState()
        end
        
        -- *** Применение скорости ***
        if not IsPedOnMount(ped) and not IsPedInAnyVehicle(ped, false) and not IsPedRagdoll(ped) then
            
            local speedToApply
            
            if isExhausted then
                -- При истощении принудительно медленная скорость
                speedToApply = Config.Stamina.exhaustedSpeed
            else
                speedToApply = currentSpeed
            end
            
            local entitySpeed = GetEntitySpeed(ped)
            local isMoving = entitySpeed > 0.02 or IsPedWalking(ped) or IsPedRunning(ped) or IsPedSprinting(ped)
            
            if isMoving then
                ApplySpeedToPed(ped, speedToApply)
            else
                -- Персонаж стоит
                SetStaminaRates(Config.Stamina.normalDepletion, Config.Stamina.normalRecharge)
                SetPedMaxMoveBlendRatio(ped, 1.0)
                Citizen.InvokeNative(0x085BF80FA50A39D1, ped, 1.0)
            end
        else
            -- В транспорте или на лошади
            SetStaminaRates(Config.Stamina.normalDepletion, Config.Stamina.normalRecharge)
        end
        
        ::continue::
    end
end)

-- ===================================
-- Команда /walkspeed
-- ===================================

RegisterCommand('walkspeed', function(source, args)
    local arg = args and args[1] or nil
    
    if arg == 'default' or arg == 'reset' then
        SetSpeedIndex(Config.DefaultSpeedIndex, true)
        return
    end
    
    local num = tonumber(arg)
    if num then
        for i, data in ipairs(Config.Speeds) do
            if data.value == num then
                SetSpeedIndex(i, true)
                return
            end
        end
        SendNotification("Доступные: 0.2, 0.5, 0.8, 1.7, 2.1", "error")
        return
    end
    
    -- Без аргументов - показать текущую скорость
    NotifySpeed(Config.Speeds[currentIndex])
end, false)

-- ===================================
-- Экспорты
-- ===================================

exports('GetCurrentSpeed', function()
    return currentSpeed, Config.Speeds[currentIndex]
end)

exports('SetSpeed', function(speedValue)
    for i, data in ipairs(Config.Speeds) do
        if data.value == speedValue then
            SetSpeedIndex(i, true)
            return true
        end
    end
    return false
end)

exports('IsExhausted', function()
    return isExhausted
end)

exports('GetStamina', function()
    return GetPlayerStamina()
end)