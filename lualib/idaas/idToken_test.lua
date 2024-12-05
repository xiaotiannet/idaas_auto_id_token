-- 测试配置 20231017 create by xiaotian
-- 引用core
local a = require("idaas.idToken_core")
 --测试
 local args={
  apiUrl="",--获取api的地址
  appKey="",-- 分配的appKey
  appSecret="",--分配的appSecret
  tokenExpires=60*30,--缓存过期时间，单位秒
  tokenKey="idToken_test",--缓存key的前缀
 }
a.add(args)

--代理
-- --实测 proxy_pass 不支持带路径的变量。会直接403。所以暂不启用
-- --local  proxy_url="http://127.0.0.1:702" 
-- ngx.var.dynamic_upstream  = proxy_url