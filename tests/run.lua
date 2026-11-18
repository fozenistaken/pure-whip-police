local root = (arg and arg[1]) or '.'
local failed, passed = 0, 0

function Test(name, fn)
    local ok, err = pcall(fn)
    if ok then passed = passed + 1 else failed = failed + 1; print('FAIL ' .. name .. ': ' .. tostring(err)) end
end

function Eq(a, b, what)
    if a ~= b then error(('%s: expected %s, got %s'):format(what or 'value', tostring(b), tostring(a)), 2) end
end

PWP = {}
Config = {}
local function load(rel) dofile(root .. '/' .. rel) end
local function test(rel) dofile(root .. '/tests/' .. rel) end

local SUITES = {
    { 'shared/catalogue.lua', 'catalogue_test.lua' },
    { 'shared/records_logic.lua', 'records_test.lua' },
    { 'shared/sentence.lua', 'sentence_test.lua' },
    { 'shared/evidence_logic.lua', 'evidence_test.lua' },
    { 'shared/traffic_logic.lua', 'traffic_test.lua' },
    { 'shared/academy.lua', 'academy_test.lua' },
}
for _, s in ipairs(SUITES) do load(s[1]); test(s[2]) end

print(failed == 0 and ('ALL PASS (' .. passed .. ')') or ('FAILED ' .. failed .. ' of ' .. (failed + passed)))
os.exit(failed == 0 and 0 or 1)
