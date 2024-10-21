module(..., package.seeall)

--- 对 LuatOS-Air http.request 的封装
-- @param timeout (number) 超时时间
-- @param method (string) 请求方法
-- @param url (string) 请求地址
-- @param headers (table) 请求头
-- @param body (string) 请求体
-- @return (number, table, string) 状态码, 响应头, 响应体
function fetch(timeout, method, url, headers, body)
    timeout = timeout or 1000 * 30

    local function callback(res_result, res_prompt, res_headers, res_body)
        log.info("请求结果", res_result, res_prompt, res_headers, res_body)
    end

    log.info("util_http.fetch", "开始请求", "id:", id)
    http.request(method, url, nil, headers, body, timeout, callback)
end
