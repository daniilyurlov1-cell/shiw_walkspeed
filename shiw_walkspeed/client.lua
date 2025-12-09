-- =========================================================================================
-- Скрипт движения (Смена скорости 0.4 - 2.1)
-- ЛОГИКА РАСХОДА СТАМИНЫ: Управление Natives RDR2.
-- - При скорости >= 1.7 -> Множитель расхода = 3.0.
-- =========================================================================================

-- *** КОНСТАНТЫ УПРАВЛЕНИЯ ***
local KEY_UP = 0x6319DB71        -- Стрелка ВВЕРХ (Для смены скорости)
local KEY_DOWN = 0x05CA7C52      -- Стрелка ВНИЗ (Для смены скорости)

-- *** NATIVE HASHES (Предоставлены пользователем) ***
local NATIVE_DEPLETION_MULTIPLIER = 0xEF5A3D2285D8924B -- SetStaminaDepletionMultiplier
local NATIVE_RECHARGE_MULTIPLIER = 0x345C9F993A8AB4A4 -- SetStaminaRechargeMultiplier

-- *** КОНСТАНТЫ СКОРОСТИ И МНОЖИТЕЛЕЙ ***
local MAX_SPRINT_SPEED = 2.1    
local HIGH_CONSUMPTION_THRESHOLD = 1.7 -- Скорость, с которой начинается высокий расход

-- Настройки множителей расхода
local DEPLETION_MULTIPLIER_HIGH = 3.0   -- Расход, как при скорости 3.0
local DEPLETION_MULTIPLIER_NORMAL = 1.0 -- Стандартный расход RDR2
local RECHARGE_MULTIPLIER_STOP = 0.0    -- Отключение регенерации во время бега/спринта
local RECHARGE_MULTIPLIER_NORMAL = 1.0  -- Стандартная регенерация RDR2

-- *** ПЕРЕМЕННЫЕ СОСТОЯНИЯ ***
local availableSpeeds = {
    0.4, 0.6, 0.8, HIGH_CONSUMPTION_THRESHOLD, MAX_SPRINT_SPEED, 
}
local currentIndex = 4 -- Начинаем с 1.7 (Трусца)
local currentSpeed = availableSpeeds[currentIndex]
local currentDepletionRate = DEPLETION_MULTIPLIER_NORMAL -- Отслеживание текущего множителя

-- *** ТАБЛИЦА НАЗВАНИЙ СКОРОСТИ ***
local speedNames = {
    [0.4] = "Медленный шаг",
    [0.6] = "Шаг",
    [0.8] = "Ходьба",
    [1.7] = "Трусца", 
    [2.1] = "Бег", 
}

-- ===================================
-- Функции управления выносливостью (NATIVE-BASED)
-- ===================================

local function SetStaminaRates(depletion, recharge)
    local ped = PlayerPedId()
    
    -- Устанавливаем множитель расхода стамины
    Citizen.InvokeNative(NATIVE_DEPLETION_MULTIPLIER, ped, depletion)
    
    -- Устанавливаем множитель регенерации стамины
    Citizen.InvokeNative(NATIVE_RECHARGE_MULTIPLIER, ped, recharge)
    
    currentDepletionRate = depletion
end

local function ApplyHighConsumption()
    -- Расход как при 3.0, регенерация отключена
    SetStaminaRates(DEPLETION_MULTIPLIER_HIGH, RECHARGE_MULTIPLIER_STOP)
end

local function RestoreNormalRates()
    -- Возвращаем стандартный расход и регенерацию
    SetStaminaRates(DEPLETION_MULTIPLIER_NORMAL, RECHARGE_MULTIPLIER_NORMAL)
end

-- ===================================
-- Логика переключения скорости ходьбы и оповещения (без изменений)
-- ===================================

local function notifySpeed(speed)
    local title = "~e~Скорость~e~"
    
    local descName = speedNames[speed] or ("Неизвестная (" .. tostring(speed) .. ")")
    
    local desc = "Установлена: " .. descName
    
    if lib and lib.notify then
        lib.notify({ title = title, description = desc, type = 'inform', position = 'left', duration = 2500 })
    else
        print(('[shiw_walkspeed] %s'):format(desc))
    end
end

local function applySpeedByIndex(index)
    currentIndex = index
    currentSpeed = availableSpeeds[currentIndex]
    notifySpeed(currentSpeed)
end

-- ===================================
-- ФУНКЦИЯ ДЛЯ АГРЕССИВНОГО ЗАПУСКА СПРИНТА (без изменений)
-- ===================================

local function ForceSprintStart(ped)
    Citizen.InvokeNative(0x6F498F5307DA19F9, ped, 1) -- Принудительное включение спринта
end

-- ===================================
-- Основная логика применения скорости
-- ===================================

local function ApplySpeedToPed(ped, targetRatio)
    local r = targetRatio
    if r < 0.1 then r = 0.1 end
    if r > 3.0 then r = 3.0 end

    local IS_AIMING = IsPlayerFreeAiming(PlayerId())
    local isMoving = IsPedWalking(ped) or IsPedRunning(ped) or IsPedSprinting(ped)
    
    if IS_AIMING then
        -- Прицеливание: сброс скорости и нормальный расход
        r = 1.0 
        RestoreNormalRates()
        
    -- Условие расхода: Если целевая скорость >= 1.7 и персонаж двигается
    elseif targetRatio >= HIGH_CONSUMPTION_THRESHOLD and isMoving then
        
        -- Применяем высокий множитель расхода (3.0), независимо от того, 1.7 это или 2.1
        ApplyHighConsumption()
        
        if targetRatio == MAX_SPRINT_SPEED then
            -- Если это спринт, форсируем анимацию/движение
            ForceSprintStart(ped) 
        end
        
    else 
        -- Во всех остальных случаях (скорость < 1.7 или не двигается) - нормальные ставки
        RestoreNormalRates()
    end
    
    -- Устанавливаем максимальный коэффициент смешивания движения
    SetPedMaxMoveBlendRatio(ped, r)
    Citizen.InvokeNative(0x085BF80FA50A39D1, ped, r)
end
-- ЗАКРЫВАЕТ: local function ApplySpeedToPed(ped, targetRatio)

-- ===================================
-- Основной поток: Применение скорости и горячих клавиш
-- ===================================

CreateThread(function()
    local ped = PlayerPedId()
    
    -- Убедимся, что по умолчанию ставки нормальные при загрузке
    RestoreNormalRates() 
    
    while true do
        Wait(0) 

        -- *** Горячие клавиши для смены скорости ходьбы ***
        if IsControlJustPressed(0, KEY_UP) then
            local nextIndex = currentIndex + 1
            if nextIndex > #availableSpeeds then nextIndex = #availableSpeeds end
            if nextIndex ~= currentIndex then 
                applySpeedByIndex(nextIndex) 
            end
        elseif IsControlJustPressed(0, KEY_DOWN) then
            local prevIndex = currentIndex - 1
            if prevIndex < 1 then prevIndex = 1 end
            if prevIndex ~= currentIndex then 
                applySpeedByIndex(prevIndex) 
            end
        end

        -- *** Применение скорости ***
        if not IsEntityDead(ped) and not IsPedOnMount(ped) and not IsPedInAnyVehicle(ped, false) and not IsPedRagdoll(ped) then
            local spd = GetEntitySpeed(ped)
            
            if spd > 0.02 or IsPedWalking(ped) or IsPedRunning(ped) or IsPedSprinting(ped) then
                ApplySpeedToPed(ped, currentSpeed)
            else
                -- Если персонаж стоит или не двигается, восстанавливаем ставки
                RestoreNormalRates()
                SetPedMaxMoveBlendRatio(ped, 1.0)
                Citizen.InvokeNative(0x085BF80FA50A39D1, ped, 1.0)
            end
        else
            -- Если персонаж мертв, в транспорте и т.д., восстанавливаем ставки
            RestoreNormalRates()
        end
    end
end) 
-- ЗАКРЫВАЕТ: CreateThread(function()

-- ===================================
-- Команда /walkspeed (без изменений)
-- ===================================

RegisterCommand('walkspeed', function(source, args)
    local arg = args and args[1] or nil
    
    if arg == 'default' or arg == 'reset' then
        applySpeedByIndex(4) -- 1.7
        return
    end

    local num = tonumber(arg)
    if num then
        local found = false
        for i, v in ipairs(availableSpeeds) do
            if v == num then
                applySpeedByIndex(i)
                found = true
                break
            end
        end
        
        if not found then
            notifySpeed("Не найдена. Доступные: 0.4, 0.6, 0.8, 1.7, 2.1")
        end
        return
    end

    notifySpeed(currentSpeed)
end, false)
-- ЗАКРЫВАЕТ: RegisterCommand('walkspeed', function(source, args)