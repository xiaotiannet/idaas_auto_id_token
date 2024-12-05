-- 移除请求参数中的 id_token create by xiaotian

-- local a = require("idaas.idToken_core")
-- a.del()
  -- 移除请求参数中的 id_token
  local args = ngx.req.get_uri_args()
  local paramToRemove = args["id_token"]

  if paramToRemove then
      args["id_token"] = nil
      local new_args = ngx.encode_args(args)
      ngx.req.set_uri_args(new_args)
      -- ngx.log(ngx.INFO, "remove id_token")
  end   