Whip.configPage({
    label = 'Police',
    groups = {
        {
            label = 'Departments',
            settings = {
                { key = 'Departments', type = 'map', label = 'Departments', keyPattern = '^[%a_][%w_]*$', maxItems = 12,
                  apply = 'restart', why = 'A department becomes a WHIP job when the resource starts',
                  help = 'One per police force. The key is its job key in /whip -> Jobs.',
                  fields = {
                      { key = 'label', type = 'string', label = 'Name', maxLen = 60 },
                      { key = 'short', type = 'string', label = 'Tag', maxLen = 8 },
                      { key = 'color', type = 'int', label = 'Blip colour', min = 0, max = 85 },
                  } },
            },
        },
        {
            label = 'Stations and points',
            settings = {
                { key = 'Stations', type = 'records', label = 'Stations', maxItems = 40, widget = 'mapPoints',
                  marker = { sprite = 60, colour = 38, name = 'Police station' },
                  apply = 'restart', why = 'Blips are placed when the resource starts',
                  fields = {
                      { key = 'dept', type = 'string', label = 'Department key', maxLen = 50 },
                      { key = 'label', type = 'string', label = 'Name', maxLen = 40 },
                      { key = 'coords', type = 'vec3', label = 'Blip', here = true, place = true },
                  } },
                { key = 'StationSprite', type = 'int', label = 'Station blip sprite', min = 1, max = 900,
                  apply = 'restart', why = 'Blips are placed when the resource starts' },
                { key = 'Points', type = 'records', label = 'Points', maxItems = 200, widget = 'mapPoints',
                  marker = { sprite = 280, colour = 3, name = 'Police point' },
                  apply = 'restart', why = 'Prompts are placed when the resource starts',
                  fields = {
                      { key = 'dept', type = 'string', label = 'Department key', maxLen = 50 },
                      { key = 'kind', type = 'enum', label = 'Kind', options = {
                          { value = 'duty', label = 'Duty desk' }, { value = 'locker', label = 'Own locker' },
                          { value = 'stash', label = 'Station stash' }, { value = 'armory', label = 'Armory' },
                          { value = 'wardrobe', label = 'Wardrobe' }, { value = 'garage', label = 'Fleet garage' },
                          { value = 'kiosk', label = 'Fine kiosk (public)' },
                      } },
                      { key = 'label', type = 'string', label = 'Name', maxLen = 40 },
                      { key = 'coords', type = 'vec3', label = 'Where', here = true, place = true },
                      { key = 'spawn', type = 'vec4', label = 'Car spawn (garage)', here = true, place = true, nullable = true, emptyLabel = 'not a garage' },
                  } },
                { key = 'Fines.account', type = 'string', label = 'Fines go to account', maxLen = 20, nullable = true, emptyLabel = 'nowhere',
                  help = "A bank account number, e.g. WB-123456. Empty: the money goes nowhere." },
                { key = 'PointReach', type = 'number', label = 'Prompt reach', min = 0.5, max = 25, step = 0.5,
                  unit = 'm', apply = 'restart', why = 'Prompts are placed when the resource starts' },
            },
        },
    },
})
