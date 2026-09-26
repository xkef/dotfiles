---@meta
-- Types of the public API (tether and tether.api). Internal types live
-- next to their modules.

---@class tether.PickItem
---@field text string
---@field file? string
---@field lnum? integer
---@field preview? {lines: string[], ft?: string}
---@field action? fun(item: tether.PickItem)

---A picker source, registered with tether.api.register.source.
---@class tether.Source
---@field name string
---@field desc string
---@field items fun(repo: tether.Repo): tether.PickItem[]?, string?
---@field enabled? fun(repo: tether.Repo): boolean

---@class tether.CockpitRow
---@field text string
---@field hl? string
---@field id? string key for expansion state
---@field children? tether.CockpitRow[]
---@field actions? table<string, fun()>

---A cockpit section, registered with tether.api.register.section.
---@class tether.Section
---@field name string
---@field order integer lower renders first; built-ins use 10, 20, 40
---@field rows fun(repo: tether.Repo): tether.CockpitRow[]
---@field summary? fun(repo: tether.Repo): string?

---A feature module under tether.features.
---@class tether.Feature
---@field attach fun(api: table)
---@field reset? fun()
