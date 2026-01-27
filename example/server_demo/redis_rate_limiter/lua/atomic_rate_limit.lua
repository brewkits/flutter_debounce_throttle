-- Atomic token bucket rate limiting with Redis Lua script
-- Eliminates race conditions by computing everything server-side
--
-- Usage from Dart:
--   final result = await redis.send_object([
--     'EVAL', luaScript, 1, key,
--     maxTokens, refillRate, refillIntervalMicros,
--     tokensToAcquire, nowMicros, ttlSeconds
--   ]);
--
-- Returns: [success (0/1), remaining_tokens]

local key = KEYS[1]
local max_tokens = tonumber(ARGV[1])
local refill_rate = tonumber(ARGV[2])
local refill_interval_micros = tonumber(ARGV[3])
local tokens_to_acquire = tonumber(ARGV[4])
local now_micros = tonumber(ARGV[5])
local ttl_seconds = tonumber(ARGV[6])

-- Fetch current state (format: "tokens,lastRefillMicros")
local state = redis.call('GET', key)
local tokens, last_refill

if state then
  local parts = {}
  for part in string.gmatch(state, '([^,]+)') do
    table.insert(parts, part)
  end
  tokens = tonumber(parts[1])
  last_refill = tonumber(parts[2])
else
  -- Initialize with full capacity
  tokens = max_tokens
  last_refill = now_micros
end

-- Calculate refill (token bucket algorithm)
if last_refill > 0 and now_micros > last_refill then
  local elapsed = now_micros - last_refill
  local intervals = elapsed / refill_interval_micros
  local tokens_to_add = intervals * refill_rate
  tokens = math.min(max_tokens, tokens + tokens_to_add)
  last_refill = now_micros
end

-- Try to acquire tokens
local success = 0
if tokens >= tokens_to_acquire then
  tokens = tokens - tokens_to_acquire
  success = 1
end

-- Save new state atomically
local new_state = tokens .. ',' .. last_refill
if ttl_seconds > 0 then
  redis.call('SETEX', key, ttl_seconds, new_state)
else
  redis.call('SET', key, new_state)
end

-- Return [success (0/1), remaining_tokens]
return {success, math.floor(tokens)}
