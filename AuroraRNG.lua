--[[

    Studio 2000 | Team Aurora
    @Author: MrMouse2405


    @Project: Aurora RNG

    A PRNG (Procedural Random Number Generator)
    (No Duplicates) that generates random numbers
    based on two input values:
        1: Seed
        2: nth number

    This PRNG is statless, meaning, it does not save states.
    Instead of modifying states recursively, it uses XOR.

    Guaranteed to produce same value for same seed and nth number,
    but unique values for same seed, but different nth numbers.

    Modificiation of script.Parent

    Output: 32-bit integers 0..4294967295
    Internal state (seed): 53 bits, can be read or write at any time
    Good statistical properties of PRN sequence:
        uniformity,
        long period of 255 * 2^45 (approximately 2^53),
        unpredictability

        Compatible with Lua 5.1, 5.2, 5.3, LuaJIT

    For this script, we are reverse engineering to get the
    random number at a given index in a sequence.

    Any variables or functions starting with _
    just exist to show original code, they will be removed
    in production.
]]
-- all parameters in PRNG formula are derived from these 57 secret bits:
local secret_key_6 = 58 -- 6-bit  arbitrary integer (0..63)
local secret_key_7 = 110 -- 7-bit  arbitrary integer (0..127)
local secret_key_44 = 3580861008710 -- 44-bit arbitrary integer (0..17592186044415)

local FLOOR = math.floor
local XOR = bit32.bxor

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

local _a = 1 * 2 ^ 32
local _b = param_mul_45 + param_add_45

local function get_state45(seed_53 : number) : number
    return seed_53 % 35184372088832
end

local function get_random(seed : number,state_45 : number) : number

    state_45 = (state_45 * _b) % 35184372088832

    --[[

        local function get_seed() : number
            -- returns current seed as single 53-bit integer
             return (state_8 - 2) * 35184372088832 + state_45
        end
        
        So, 
        (state_8 - 2) * 35184372088832 + state_45 = seed

        we have seed, so

        state_8 = ((seed - state_45) / 35184372088832) + 2

    ]]
    local state_8 = ((seed - state_45) / 35184372088832) + 2

    local r = state_8 % 32
    local n = FLOOR(state_45 / 2 ^ (13 - (state_8 - r) / 32)) % 2 ^ 32 / 2 ^ r
    return FLOOR(n % _a) + FLOOR(n)
end

local AuroraRNG = {}

function AuroraRNG.from_seed(seed)
    seed = XOR(0x123456789ABCDE,seed)
    return {seed,get_state45(seed)}
end

function AuroraRNG.get_nth(self : table,nth : number)
    return get_random(self[1],XOR(self[2],nth))
end

return AuroraRNG
