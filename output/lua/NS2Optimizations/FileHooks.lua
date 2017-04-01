(not Predict and Shared.Message or function() end) [=[
------------------------------
NS2 Optimizations - FastMixin:
You will see warnings of the type:
WARNING: Improperly initialized!
These just mean that an entity creation took longer than normal.
They indicate badly written code, and help debugging.
------------------------------
]=]

Script.Load("lua/NS2Optimizations/Closure.lua")

local default_config = Server and {
	TraceCacheSize = {
		Ray     = 16,
		Box     = 16,
		Capsule = 32
	},
	InfinitePlayerRelevancy = false,
	UnsafeTableOptimizations = false,
	FastMixin = true
} or {
	TraceCacheSize = {
		Ray     = 4,
		Box     = 4,
		Capsule = 16
	},
	UnsafeTableOptimizations = false,
	FastMixin = true
}

kNS2OptiConfig = LoadConfigFile(Server and "NS2OptiServer.json" or "NS2OptiClient.json", default_config)

kRelevantToAll = 0x8000000

Script.Load "lua/NS2Optimizations/Table.lua"
Script.Load "lua/NS2Optimizations/Utility.lua"
Script.Load "lua/NS2Optimizations/FastMixin.lua"

if Shared then
	Script.Load "lua/NS2Optimizations/TraceRayCache.lua"
	Script.Load "lua/NS2Optimizations/TraceCapsuleCache.lua"
	Script.Load "lua/NS2Optimizations/TraceBoxCache.lua"
end

ModLoader.SetupFileHook("lua/Mixins/BaseModelMixin.lua", "lua/NS2Optimizations/BaseModelMixin.lua", "post")
ModLoader.SetupFileHook("lua/ScoringMixin.lua", "lua/NS2Optimizations/ScoringMixin.lua", "post")
ModLoader.SetupFileHook("lua/Entity.lua", "lua/NS2Optimizations/Entity.lua", "post")

ModLoader.SetupFileHook("lua/Observatory.lua",              "lua/NS2Optimizations/Observatory.lua", "post")
ModLoader.SetupFileHook("lua/BalanceMisc.lua",              "lua/NS2Optimizations/BalanceMisc.lua", "post")

if Server then
	ModLoader.SetupFileHook("lua/LOSMixin.lua",              "lua/NS2Optimizations/LOSMixin_Server.lua", "post")
	ModLoader.SetupFileHook("lua/Gamerules.lua",             "lua/NS2Optimizations/Gamerules_Server.lua", "post")
	ModLoader.SetupFileHook("lua/Player.lua",                "lua/NS2Optimizations/Player_Server.lua", "post")
end

ModLoader.SetupFileHook("lua/MixinUtility.lua", "lua/NS2Optimizations/MixinUtility.lua", "replace")
ModLoader.SetupFileHook("lua/MixinDispatcherBuilder.lua", "", "halt")

local ray_hit, ray_miss, box_hit, box_miss, capsule_hit, capsule_miss = 0, 0, 0, 0, 0, 0
local function cacheStats()
	local ray_hit_curr, ray_miss_curr = TraceRayCacheStats()
	local box_hit_curr, box_miss_curr = TraceBoxCacheStats()
	local capsule_hit_curr, capsule_miss_curr = TraceCapsuleCacheStats()
	local ray_hit_diff  = ray_hit_curr  - ray_hit
	local ray_miss_diff = ray_miss_curr - ray_miss
	local box_hit_diff  = box_hit_curr  - box_hit
	local box_miss_diff = box_miss_curr - box_miss
	local capsule_hit_diff  = capsule_hit_curr  - capsule_hit
	local capsule_miss_diff = capsule_miss_curr - capsule_miss
	ray_hit,      ray_miss,      box_hit,      box_miss,      capsule_hit,      capsule_miss =
	ray_hit_curr, ray_miss_curr, box_hit_curr, box_miss_curr, capsule_hit_curr, capsule_miss_curr
	local small_delim = "--------"
	local big_delim = small_delim .. small_delim
	Log(big_delim)
	Log("Box Cache hits:   %s", box_hit_diff)
	Log("Box Cache misses: %s", box_miss_diff)
	Log("Box Cache hit percentage: %s", box_hit_diff / (box_hit_diff + box_miss_diff))
	Log(small_delim)
	Log("Capsule Cache hits:   %s", capsule_hit_diff)
	Log("Capsule Cache misses: %s", capsule_miss_diff)
	Log("Capsule Cache hit percentage: %s", capsule_hit_diff / (capsule_hit_diff + capsule_miss_diff))
	Log(small_delim)
	Log("Ray Cache hits:   %s", ray_hit_diff)
	Log("Ray Cache misses: %s", ray_miss_diff)
	Log("Ray Cache hit percentage: %s", ray_hit_diff / (ray_hit_diff + ray_miss_diff))
	Log(big_delim)
end

if Server then
	Event.Hook("Console_sv_trace_cache_diff", cacheStats)
else
	Event.Hook("Console_trace_cache_diff", cacheStats)
end
