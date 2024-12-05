# idaas_id_token
应对最近推广的 云盾IDAAS认证（服务器部署在内网隔离，公网对内的所有http请求都必须在url中增加id_token参数）的要求，在尽量不更改程序的前提下，利用 openresty （nginx + lua） 中间件实现自动获取id_token、自动添加url参数
