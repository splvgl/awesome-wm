local awful = require("awful")
local util = require("awful.util")
local lfs = require("lfs")
local runorraise = require("runorraise")
local capi = {
  tag = tag,
  client = client,
  keygrabber = keygrabber,
  mouse = mouse,
  screen = screen
}
local io = io
local naughty = require("naughty")
local cmus = require("cmus")

global_prompt = {}


function generic_completion_wrapper(kw, list, str, cur_pos, ncomp)
    out_str, out_pos = awful.completion.generic(str, cur_pos, ncomp, list)
    out_str = kw .. " " .. out_str
    out_pos = out_pos + kw:len() + 1
    return out_str, out_pos
 end
 
 function table.val_to_str ( v )
   if "string" == type( v ) then
     v = string.gsub( v, "\n", "\\n" )
     if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
       return "'" .. v .. "'"
     end
     return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
   else
     return "table" == type( v ) and table.tostring( v ) or
       tostring( v )
   end
 end
 
 function table.key_to_str ( k )
   if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
     return k
   else
     return "[" .. table.val_to_str( k ) .. "]"
   end
 end
 
 function table.tostring( tbl )
   local result, done = {}, {}
   for k, v in ipairs( tbl ) do
     table.insert( result, table.val_to_str( v ) )
     done[ k ] = true
   end
   for k, v in pairs( tbl ) do
     if not done[ k ] then
       table.insert( result,
         table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
     end
   end
   return "{" .. table.concat( result, "," ) .. "}"
 end


global_prompt.search_url = "https://duckduckgo.com/?q=%s"
global_prompt.prompt_web = {
   keyword={"w"}, help="Web search",
   run_function = function(kw, expr)
      is_url = string.find(expr, "[.][0-9a-zA-Z]+$")
      naughty.notify({text=is_url})
      if is_url == nil then
         expr_search = string.gsub(expr, "%s+", "+")
         expr_url = string.format(global_prompt.search_url, expr_search)
      else
         expr_url = expr
      end
      awful.spawn.with_shell(internet_browser .. " " .. expr_url)
   end,
   comp_function = nil
}

global_prompt.prompt_list = { global_prompt.prompt_web }

function global_prompt.run(str)
   str_stripped = str:match("^%s*(.-)%s*$")
   if not str_stripped:match("%s") then
      kw = str_stripped
      args = ""
   else
      kw = str:match("^%s*([^ ]+) .*$")
      args = str:match("^%s*[^ ]+ (.*)$"):match("^%s*(.-)%s*$")
   end
   for _, p in ipairs(global_prompt.prompt_list) do
      for _, key in ipairs(p["keyword"]) do
         if key == kw then
            return p["run_function"](kw, args)
         end
      end
   end
end

function global_prompt.comp(str, cur_pos, ncomp)
   str_stripped = str:match("^%s*(.-)%s*$")
   if not str_stripped:match("%s") then
      kw = str_stripped
      args = ""
   else
      kw = str:match("^%s*([^ ]+) .*$")
      args = str:match("^%s*[^ ]+ (.*)$")
      if args then
         args = args:match("^%s*(.-)%s*$")
      else
         args = ""
      end
   end
   for _, p in ipairs(global_prompt.prompt_list) do
      for _, key in ipairs(p["keyword"]) do
         if key == kw and p["comp_function"] then
            return p["comp_function"](kw, args, cur_pos, ncomp)
         end
      end
   end
   return generic_completion_wrapper("", {},
                                     str, cur_pos, ncomp)
end

return global_prompt