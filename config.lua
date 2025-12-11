Config = {}

-- Клавиши управления
Config.Keys = {
    speedUp = 0x6319DB71,    -- Стрелка ВВЕРХ
    speedDown = 0x05CA7C52   -- Стрелка ВНИЗ
}

-- Состояния скорости
Config.Speeds = {
    [1] = { value = 0.2, name = "Медленный шаг" },
    [2] = { value = 0.5, name = "Шаг" },
    [3] = { value = 0.8, name = "Быстрый шаг" },
    [4] = { value = 1.7, name = "Трусца" },
    [5] = { value = 2.1, name = "Бег" }
}

-- Начальный индекс скорости при заходе на сервер
Config.DefaultSpeedIndex = 2  -- "Шаг" (0.5)

-- Настройки стамины
Config.Stamina = {
    -- Множители расхода стамины
    normalDepletion = 1.0,           -- Обычный расход
    truscaDepletion = 2.5,           -- Трусца - в 2 раза быстрее
    runDepletion = 2.5,              -- Бег - в 4 раза быстрее
    
    -- Регенерация
    normalRecharge = 2.0,            -- Обычная регенерация
    movingRecharge = 0.3,            -- Регенерация при движении (отключена)
    
    -- Истощение
    exhaustedSpeed = 0.8,            -- Скорость при истощении
    recoveryThreshold = 30.0,        -- Порог восстановления (%)
    
    -- Эффекты
    cameraShakeIntensity = 0.3,      -- Интенсивность тряски
    screenEffectName = "PlayerWakeUpInterrogation"  -- Эффект экрана
}

-- Уведомления
Config.Notifications = {
    speedChange = "Скорость: %s",
    exhausted = "Вы истощены! Восстановите силы...",
    recovered = "Силы восстановлены!",
    cantSpeedUp = "Вы слишком устали!"
}