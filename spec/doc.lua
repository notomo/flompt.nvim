local gen = function()
  require("genvdoc").generate("flompt.nvim", {
    chapters = {
      {
        name = "COMMANDS",
        group = function(node)
          if node.declaration == nil or node.declaration.type ~= "command" then
            return nil
          end
          return "COMMANDS"
        end,
      },
      {
        name = "EXAMPLES",
        body = function()
          local f = io.open("./spec/example.vim", "r")
          local lines = {}
          for line in f:lines() do
            if line == "" then
              table.insert(lines, line)
            else
              table.insert(lines, ("  %s"):format(line))
            end
          end
          f:close()
          return (">\n%s\n<"):format(table.concat(lines, "\n"))
        end,
      },
    },
  })
end

gen()
