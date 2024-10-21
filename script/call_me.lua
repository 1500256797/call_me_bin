require "cc"
require "audio"
require "common"
require "sys"
local http = require "http"
local util_http = require "util_http"
module(..., package.seeall)

-- GET请求函数
local function httpGet(url, callback)
    http.request("GET", url, nil, nil, nil, 30000, function(result, statusCode, head, body)
        if result then
            log.info("HTTP GET 成功:", statusCode)
            if callback then
                callback(true, body)
            end
        else
            log.error("HTTP GET 失败:", statusCode)
            if callback then
                callback(false, statusCode)
            end
        end
    end)
end

-- 新增：发送完成任务的请求
local function sendFinishTaskRequest(taskId)
    if not taskId then
        log.error("sendFinishTaskRequest: taskId is nil")
        return
    end
    log.info("向服务器发送完成任务请求", taskId)
    local url = "http://127.0.0.1/finishPhoneTask"
    local header = { ["content-type"] = "application/json" }
    local body = { ["task_id"] = taskId }
    local json_data = json.encode(body)
    return util_http.fetch(nil, "POST", url, header, json_data)
end

-- 全局变量来存储当前任务
local currentTask = nil

-- 修改处理电话任务的函数
local function processPhoneTask(task)
    log.info("开始处理电话任务", task.phone_number, task.notification_content)
    currentTask = task
    local number = task.phone_number
    cc.dial(number)
end

-- "通话已建立"消息处理函数
local function connected(num)
    log.info("通话已建立", num)
    if currentTask then
        -- 通话中向对方播放TTS内容
        audio.play(7, "TTS", currentTask.notification_content, 7, nil, true, 2000)
        -- 11秒之后主动结束通话
        sys.timerStart(cc.hangUp, 11000, num)

    else
        log.error("Connected but no current task")
    end
end

-- "通话已结束"消息处理函数
local function disconnected(discReason)
    log.info("通话已结束", discReason)
    sys.timerStopAll(cc.hangUp)
    audio.stop()
    -- 发送完成任务的请求
    if currentTask then
        sendFinishTaskRequest(currentTask.id)
        currentTask = nil
    end
end

-- 修改定时任务函数
local function timedHttpGet()
    local url = "http://127.0.0.1/getPhoneTask"
    httpGet(url, function(success, response)
        if success then
            local result = json.decode(response)
            if result then
                log.info("定时GET请求成功，解析后的结果:", "success:", result.success, "msg:", result.msg)

                if result.success == true then
                    if type(result.task) == "table" then
                        log.info("任务详情:")
                        for key, value in pairs(result.task) do
                            log.info("  ", key, ":", value)
                        end
                        -- 处理电话任务
                        processPhoneTask(result.task)
                    else
                        log.info("任务为空或不是表格类型")
                    end
                else
                    log.info("没有可用的任务")
                end
            else
                log.error("JSON解析失败")
            end
        else
            log.error("定时GET请求失败:", response)
        end
    end)
end

-- 启动定时任务
sys.timerLoopStart(timedHttpGet, 60000) -- 每60000毫秒(1分钟)执行一次
-- 订阅消息的用户回调函数
sys.subscribe("CALL_CONNECTED", connected)
sys.subscribe("CALL_DISCONNECTED", disconnected)
