local net = require("@lune/net")
local serde = require("@lune/serde")

local Future = require("../lib/future")
local Result = require("../lib/result")

local fut: Future.Future<Result<string, string>> = Future.try(function(url)
  local resp = net.request({
    url = url,
    method = "GET",
  })
  
  assert(resp.ok)
  return resp.body
end, { "https://jsonplaceholder.typicode.com/posts/1" })

local resp: Result.Result<string, string> = fut:await()
print(serde.decode("json", resp:unwrap()))

