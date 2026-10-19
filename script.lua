-- โหลด Kavo UI Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()

-- สร้างหน้าต่าง UI หลัก
local Window = Library.CreateLib("Dragon Wing Pro Hub", "DarkTheme")

-- สร้าง Tab และ Section
local Tab = Window:NewTab("Auto Farm & Convert")
local Section = Tab:NewSection("Farm & Convert Controls")

-- ฟังก์ชันแจ้งเตือนบนหน้าจอ
local function notify(title, text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 5
        })
    end)
end

-- แสดงค่าทรัพยากรแบบ Real-Time
local dustLabel = Section:NewLabel("Dust: Loading...")
local goldLabel = Section:NewLabel("Gold: Loading...")

local player = game.Players.LocalPlayer

local function updateStats()
    local dust = player:GetAttribute("Dust") or 0
    local gold = player:GetAttribute("Gold") or 0
    local capacity = player:GetAttribute("Capacity") or 2000000
    dustLabel:UpdateLabel(string.format("Dust: %s / %s", tostring(dust), tostring(capacity)))
    goldLabel:UpdateLabel("Gold: " .. tostring(gold))
end

updateStats()
player:GetAttributeChangedSignal("Dust"):Connect(updateStats)
player:GetAttributeChangedSignal("Gold"):Connect(updateStats)
player:GetAttributeChangedSignal("Capacity"):Connect(updateStats)

-- ตัวแปรควบคุมระบบ
local autoFarmActive = false

-- รายชื่อโซนฟาร์ม
local zones = {
    ["Elder Canopy"] = CFrame.new(36, 53.0499992, -536),
    ["Crystal Caverns"] = CFrame.new(205, 4.04999995, -58)
}

local selectedZoneCFrame = zones["Elder Canopy"] -- ค่าเริ่มต้นโซนฟาร์ม

-- รายชื่อพิกัด Nest ทั้ง 5 จุด
local nests = {
    ["Nest 1"] = CFrame.new(-175, 3.14999998, 180),
    ["Nest 2"] = CFrame.new(-105, 3.14999998, 180),
    ["Nest 3"] = CFrame.new(-35, 3.14999998, 180),
    ["Nest 4"] = CFrame.new(35, 3.14999998, 180),
    ["Nest 5"] = CFrame.new(105, 3.29999995, 180)
}

local selectedNestCFrame = nests["Nest 3"] -- ค่าเริ่มต้นเลือก Nest 3

-- สร้าง Dropdown เลือกโซนฟาร์ม
Section:NewDropdown("Select Farm Zone", "เลือกโซนที่ต้องการไปฟาร์ม", {"Elder Canopy", "Crystal Caverns"}, function(currentOption)
    if zones[currentOption] then
        selectedZoneCFrame = zones[currentOption]
        notify("Zone Selected", "เปลี่ยนโซนฟาร์มเป็น: " .. currentOption)
    end
end)

-- สร้าง Dropdown เลือก Nest สำหรับส่งของแลกเปลี่ยน
Section:NewDropdown("Select Nest (Converter)", "เลือก Nest ที่คุณใช้งานอยู่เพื่อใช้วาร์ปไปแลก", {"Nest 1", "Nest 2", "Nest 3", "Nest 4", "Nest 5"}, function(currentOption)
    if nests[currentOption] then
        selectedNestCFrame = nests[currentOption]
        notify("Nest Selected", "เปลี่ยนจุดแลกเปลี่ยนเป็น: " .. currentOption)
    end
end)

-- ==================== ฟังก์ชันระบบ Auto Farm & Convert (หน่วงเวลา 7 นาที) ====================
local function runAutoFarmLoop()
    notify("Auto Farm", "เริ่มระบบฟาร์มและแลกเปลี่ยนอัตโนมัติแล้ว!")
    
    while autoFarmActive do
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local currentDust = player:GetAttribute("Dust") or 0
            local maxCapacity = player:GetAttribute("Capacity") or 2000000
            
            -- 1. เช็คว่ากระเป๋าเต็ม (หรือถึงขีดจำกัด) ให้วาร์ปไปแลกที่ Nest ที่เลือกไว้
            if currentDust >= maxCapacity and maxCapacity > 0 then
                notify("Inventory Full!", "กระเป๋าเต็ม! กำลังวาร์ปไปที่ Nest ที่เลือก...")
                
                -- วาร์ปไปที่พิกัด Nest ที่ผู้เล่นเลือกไว้ใน Dropdown
                character.HumanoidRootPart.CFrame = selectedNestCFrame
                task.wait(0.5)
                
                -- 2. สั่งกดแลกเปลี่ยนสักครู่เพื่อให้ระบบรับคำสั่ง
                for i = 1, 10 do
                    if not autoFarmActive then break end
                    
                    -- สั่งกด ProximityPrompt ของแท่นแปลง
                    for _, prompt in pairs(workspace:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") then
                            local text = ((prompt.ObjectText or "") .. (prompt.ActionText or "")):lower()
                            if string.find(text, "hoard") or string.find(text, "convert") then
                                prompt.MaxActivationDistance = math.huge
                                prompt.HoldDuration = 0
                                fireproximityprompt(prompt)
                            end
                        end
                    end
                    
                    -- ยิง RemoteEvent สำรอง
                    for _, v in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                        if v:IsA("RemoteEvent") then
                            local nameLower = v.Name:lower()
                            if string.find(nameLower, "convert") or string.find(nameLower, "hoard") then
                                v:FireServer()
                            end
                        end
                    end
                    
                    task.wait(0.3)
                end
                
                notify("Waiting", "ดำเนินการแปลงเสร็จสิ้น เข้าสู่โหมดหน่วงเวลา 7 นาทีก่อนกลับไปฟาร์ม...")
                
                -- 3. หน่วงเวลา 7 นาที (7 นาที * 60 วินาที = 420 วินาที)
                -- โดยจะเช็คสถานะปุ่มปิด (Toggle) ทุกๆ 1 วินาที เพื่อให้กดปิดระบบกลางคันได้ทันทีไม่ค้าง
                for secondsLeft = 420, 1, -1 do
                    if not autoFarmActive then break end
                    task.wait(1)
                end
                
                -- 4. วาร์ปกลับไปยังโซนฟาร์มที่เลือกไว้
                if autoFarmActive and character:FindFirstChild("HumanoidRootPart") then
                    notify("Resuming Farm", "ครบกำหนดเวลา 7 นาที! วาร์ปกลับจุดฟาร์ม...")
                    character.HumanoidRootPart.CFrame = selectedZoneCFrame
                end
            end
        end
        
        task.wait(1)
    end
    
    notify("Auto Farm", "ปิดการทำงานระบบเรียบร้อย")
end

-- ==================== ปุ่ม Toggle เปิด-ปิด ระบบ ====================

Section:NewToggle("Enable Auto Farm & Convert", "เปิด/ปิด ระบบฟาร์มเต็ม -> ไปแลกที่ Nest ที่เลือก -> รอ 7 นาที -> กลับมาฟาร์มต่อ", function(state)
    autoFarmActive = state
    if state then
        -- เมื่อเปิด ให้วาร์ปไปเริ่มที่โซนที่เลือกทันที
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            character.HumanoidRootPart.CFrame = selectedZoneCFrame
        end
        task.spawn(runAutoFarmLoop)
    end
end)
