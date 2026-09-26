local H = require("helpers")

local function jj_op(dir)
  return (H.sh({ "jj", "--ignore-working-copy", "op", "log", "-n1", "--no-graph", "-T", "id" }, { cwd = dir }))
end

return {
  {
    "jj checkpoint",
    function()
      local dir = H.repo("jj", { ["a.txt"] = { "a" } })
      H.trail({ "turn", "claude" }, { cwd = dir })
      H.eq("jj:" .. jj_op(dir), H.records()[1][9])
    end,
  },
  {
    "Git checkpoint",
    function()
      local dir = H.repo("git", { ["a.txt"] = { "a" } })
      H.write(dir .. "/a.txt", { "changed" })
      H.trail({ "stop", "claude" }, { cwd = dir })
      local ref = H.records()[1][9]
      local sha = ref:match("^git:(%x+)$")
      H.ok(sha, "git ref: " .. ref)
      H.eq("changed\n", (H.sh({ "git", "show", sha .. ":a.txt" }, { cwd = dir })))
    end,
  },
  {
    "Running and finished turns",
    function()
      local dir = H.repo("jj", { ["a.txt"] = { "a" } })
      H.trail({ "turn", "pi", "one" }, { cwd = dir })
      H.trail({ "edit", "pi", "a.txt" }, { cwd = dir })
      H.trail({ "stop", "pi" }, { cwd = dir })
      H.trail({ "turn", "pi", "two" }, { cwd = dir })
      H.trail({ "edit", "pi", "b.txt" }, { cwd = dir })
      H.setup()
      local turns = require("tether.turns")
      local list = turns.list(dir)
      H.eq(2, #list)
      H.eq("two", list[1].summary)
      H.eq(true, turns.running(list[1]))
      H.eq(false, turns.running(list[2]))
      H.ok(list[2].files[dir .. "/a.txt"])
      H.ok(list[1].files[dir .. "/b.txt"])
    end,
  },
  {
    "Other repositories are ignored",
    function()
      local dir = H.repo("jj", {})
      local other = H.tmpdir("other")
      H.trail({ "turn", "pi" }, { cwd = other })
      H.setup()
      H.eq(0, #require("tether.turns").list(dir))
    end,
  },
  {
    "Diff of a finished jj turn",
    function()
      local dir = H.repo("jj", { ["a.txt"] = { "a", "b", "c" } })
      H.trail({ "turn", "claude" }, { cwd = dir })
      H.write(dir .. "/a.txt", { "a", "B", "c" })
      H.trail({ "stop", "claude" }, { cwd = dir })
      H.write(dir .. "/a.txt", { "a", "B", "C" })
      H.setup()
      local repo = require("tether").repo()
      local turns = require("tether.turns")
      local scope = assert(turns.scope(repo, "turn", { snapshot = true }))
      local files = assert(turns.files(repo, scope))
      H.eq(1, #files)
      H.eq(1, #files[1].hunks)
      H.eq({ " a", "-b", "+B", " c" }, files[1].hunks[1].lines)
    end,
  },
  {
    "Review since checkpoint",
    function()
      local dir = H.repo("jj", { ["a.txt"] = { "a" }, ["b.txt"] = { "b" } })
      H.write(dir .. "/a.txt", { "before" })
      H.setup()
      require("tether").checkpoint()
      H.write(dir .. "/b.txt", { "after" })
      local buf = require("tether").review("checkpoint")
      local lines = H.buf_lines(buf)
      H.contains(lines, "b/b.txt")
      H.eq(nil, table.concat(lines, "\n"):find("a.txt", 1, true), "a.txt changed before the checkpoint")
    end,
  },
  {
    "Undo restores touched files only",
    function()
      local dir = H.repo("jj", { ["a.txt"] = { "a" }, ["b.txt"] = { "b" } })
      H.trail({ "turn", "claude" }, { cwd = dir })
      H.write(dir .. "/a.txt", { "agent" })
      H.trail({ "stop", "claude" }, { cwd = dir })
      H.write(dir .. "/b.txt", { "user" })
      H.setup()
      local restored = require("tether").undo()
      H.eq({ "a.txt" }, restored)
      H.eq({ "a" }, H.read(dir .. "/a.txt"))
      H.eq({ "user" }, H.read(dir .. "/b.txt"))
    end,
  },
  {
    "Undo on Git",
    function()
      local dir = H.repo("git", { ["a.txt"] = { "a" } })
      H.trail({ "turn", "claude" }, { cwd = dir })
      H.write(dir .. "/a.txt", { "agent" })
      H.write(dir .. "/new.txt", { "new" })
      H.sh({ "git", "add", "new.txt" }, { cwd = dir })
      H.trail({ "stop", "claude" }, { cwd = dir })
      H.setup()
      H.eq({ "a.txt", "new.txt" }, require("tether").undo())
      H.eq({ "a" }, H.read(dir .. "/a.txt"))
      H.eq(0, vim.fn.filereadable(dir .. "/new.txt"))
    end,
  },
}
