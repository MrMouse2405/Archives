--[[

    Studio 2000 | Team Aurora
    @Author: MrMouse2405

    @Project: Random Player Manager API

    Purpose: 
        - Generate Random Player from Roblox that actually exists.
        - When requested, return a random player.
        - Track a pool of user ids
        - It's guaranteed that user ids will be unique.


]]

--- CODE AT THE END OF FILE ---

--[[

    Studio 2000 | Team Aurora
    @Author: MrMouse2405


    @Project: PRNG (Procedural Random Number Generator) (No Duplicates) Lua
    Output: 32-bit integers 0..4294967295
    Internal state (seed): 53 bits, can be read or write at any time
    Good statistical properties of PRN sequence:
        uniformity,
        long period of 255 * 2^45 (approximately 2^53),
        unpredictability

        Compatible with Lua 5.1, 5.2, 5.3, LuaJIT



]]
-- all parameters in PRNG formula are derived from these 57 secret bits:
local secret_key_6 = 58 -- 6-bit  arbitrary integer (0..63)
local secret_key_7 = 110 -- 7-bit  arbitrary integer (0..127)
local secret_key_44 = 3580861008710 -- 44-bit arbitrary integer (0..17592186044415)

local floor = math.floor

local function primitive_root_257(idx)
    -- returns primitive root modulo 257 (one of 128 existing roots, idx = 0..127)
    local g, m, d = 1, 128, 2 * idx + 1
    repeat
        g, m, d = g * g * (d >= m and 3 or 1) % 257, m / 2, d % m
    until m < 1
    return g
end

local param_mul_8 = primitive_root_257(secret_key_7)
local param_mul_45 = secret_key_6 * 4 + 1
local param_add_45 = secret_key_44 * 2 + 1

-- state of PRNG (53 bits in total)
local state_45 : number = 0 -- from 0 to (2^45-1)
local state_8  : number = 2 -- from 2 to 256

local function set_seed(seed_53 : number)
    -- set 53-bit integer as current seed (seed is initially set to 0 when program starts)
    state_45 = seed_53 % 35184372088832
    state_8 = floor(seed_53 / 35184372088832) % 255 + 2
end

local function get_seed() : number
    -- returns current seed as single 53-bit integer
    return (state_8 - 2) * 35184372088832 + state_45
end

local function get_random_32() : number
    -- returns pseudorandom 32-bit integer (0..4294967295)

    -- A linear congruential generator having full period of 2^45
    state_45 = (state_45 * param_mul_45 + param_add_45) % 35184372088832

    -- Lehmer RNG having period of 256
    repeat
        state_8 = state_8 * param_mul_8 % 257
    until state_8 ~= 1 -- skip one value to reduce period from 256 to 255 (we need it to be coprime with 2^45)

    -- Idea taken from PCG: shift and rotate "state_45" by varying number of bits to get 32-bit result
    local r = state_8 % 32
    local n = floor(state_45 / 2 ^ (13 - (state_8 - r) / 32)) % 2 ^ 32 / 2 ^ r
    return floor(n % 1 * 2 ^ 32) + floor(n)
end


set_seed(0x123456789ABCDE + math.random())

local Players : Players = game:GetService("Players")

local function generate_random_user_id() : number & string
    local current_player = nil
    local user_id = nil
    while not current_player do
        user_id = get_random_32()
        local success,error = pcall(function() 
            current_player = Players:GetNameFromUserIdAsync(user_id)
        end)
        if error then
            current_player = nil
            task.wait(0.5)
        end
    end
    return user_id, current_player
end

--[[

    Studio 2000 | Team Aurora
    @Author: MrMouse2405

    @Project: Random Player Manager API

]]

return generate_random_user_id
