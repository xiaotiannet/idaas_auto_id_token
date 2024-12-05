-- api网关 处理模块 20230729 create by xiaotian
local _M = {}
-- 添加
function _M.add(args)
    local tag="[idToken_add]"
    ngx.log(ngx.INFO, tag.."begin")

    -- 不判断前缀是否存在,因为很可能过期了，导致无法继续
    --local token = ngx.var.arg_id_token
    --if not token then
        -- 获取入参
        if not args then 
            args=ngx.var
        end
        -- 入参取值
        local apiUrl = args.apiUrl
        local appKey = args.appKey
        local appSecret = args.appSecret
        local tokenKey =args.tokenKey   -- -token 前缀名称
        -- local tokenExpires = tonumber(args.tokenExpires) 
        local tokenExpires = args.tokenExpires  --过期时间 单位是秒数

        -- 参数校验
        if not apiUrl or not appKey or not appSecret then
            ngx.status = 400
            ngx.say(tag.."Missing required parameters")
            ngx.exit(ngx.HTTP_BAD_REQUEST)
            return
        end
        -- 默认值
        if not tokenKey then
            tokenKey=tag
        end
        if not tokenExpires then
            tokenExpires=60*30   --默认30分钟
        end
        
        -- ngx.log(ngx.INFO, tag.."begin get")
        local md5 = ngx.md5(apiUrl.."+"..appKey.."+"..appSecret)
        -- local md5 = _M.getSHA(apiUrl.."+"..appKey.."+"..appSecret)       
        -- 缓存
        tokenKey=tokenKey.."+"..md5
        
        -- 从缓存中获取
        local token_tmp = ngx.shared.token_cache:get(tokenKey)
        local token_tmp_expires = ngx.shared.token_cache:get(tokenKey.."_expires")
        
        if not token_tmp or not token_tmp_expires or token_tmp_expires < tonumber(ngx.time()) then
            -- 无缓存或已过期
            -- 重新请求
            local http = require("resty.http")
            local httpc = http.new()         
    
            ngx.log(ngx.INFO, tag.."apiUrl to get new ")
    
            local res, err = httpc:request_uri(apiUrl, {
                ssl_verify = false,
                method = "POST",
                body = '{"appKey":"'.. appKey ..'","appSecret":"'.. appSecret ..'"}',
                headers = {
                    ["Content-Type"] = "application/json",
                    -- ["Host"] = "api.xxx.com",
                }
            })
    
            if res and res.status == 200 then
                -- 请求成功
                --token_tmp = res.body
                ngx.log(ngx.INFO, tag.."res.body: ",res.body)
                local cjson = require("cjson")
                local data = cjson.decode(res.body)
                if data.success and data.data and data.data.id_token then
                    token_tmp = data.data.id_token
                    ---全局变量 会警报
                    --_id_token={token=token_tmp,time=ngx.time()}
                    ---存入缓存
                    ngx.shared.token_cache:set(tokenKey, token_tmp, tokenExpires) -- 
                    ngx.shared.token_cache:set(tokenKey.."_expires", tonumber(ngx.time()+ tokenExpires) , tokenExpires) -- 设置过期时间
                else
                    ngx.status = 500
                    ngx.say("Failed to fetch token,error response")
                    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
                    return
                end
            else
                -- 请求失败
                ngx.log(ngx.ERR, tag.."err ",err)
                ngx.status = res.status 
                ngx.say("Failed to fetch token，err:"..err)
                ngx.exit(ngx.status)
                return
            end                       
        end
        -- ngx.log(ngx.INFO, "token_tmp: ",token_tmp)
        -- -- 构建新的querystring
        local uri_args = ngx.req.get_uri_args()
        uri_args["id_token"] = token_tmp
        ngx.req.set_uri_args(uri_args)
	    ngx.log(ngx.INFO, tag.."url: ",ngx.var.uri .. "?" .. ngx.encode_args(uri_args))
    --end 
end

function _M.del()
    -- 移除请求参数中的 id_token
    local args = ngx.req.get_uri_args()
    local paramToRemove = args["id_token"]

    if paramToRemove then
        args["id_token"] = nil
        local new_args = ngx.encode_args(args)
        ngx.req.set_uri_args(new_args)
        -- ngx.log(ngx.INFO, "remove id_token")
    end   
end

function _M.getSHA(str)
    local resty_sha1 = require "resty.sha1"

    -- 创建 SHA1 对象
    local sha1 = resty_sha1:new()
    if not sha1 then
        ngx.log(ngx.ERR, "Failed to create SHA1 object")
        return
    end

    -- 更新数据
    sha1:update(str)

    -- 计算哈希值
    local digest = sha1:final()

    -- 将哈希值转换为十六进制字符串
    local hex = require "resty.string"
    local sha1_hex = hex.to_hex(digest)

    -- 打印 SHA1 哈希值
    --ngx.log(ngx.INFO, "SHA1 hash: ", sha1_hex)
    return sha1_hex
end

return _M