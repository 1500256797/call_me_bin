module(..., package.seeall)

require "netLed"
require "net"
require "cc"
require "pins"
require "sim"

--------------------------------------------------
-- 系统启动工作任务列表
--------------------------------------------------

-- 每1分钟查询一次GSM信号强度
net.startQueryAll(60000, 60000)

-- 此处关闭RNDIS网卡功能
-- 否则，模块通过USB连接电脑后，会在电脑的网络适配器中枚举一个RNDIS网卡，电脑默认使用此网卡上网，导致模块使用的sim卡流量流失
-- 如果项目中需要打开此功能，把ril.request("AT+RNDISCALL=0,1")修改为ril.request("AT+RNDISCALL=1,1")即可
-- 注意：core固件：V0030以及之后的版本、V3028以及之后的版本，才以稳定地支持此功能
ril.request("AT+RNDISCALL=0,1")

-- 加载网络指示灯和LTE指示灯功能模块
-- 根据自己的项目需求和硬件配置决定：1、是否加载此功能模块；2、配置指示灯引脚
-- 合宙官方出售的Air720U开发板上的网络指示灯引脚为pio.P0_1，LTE指示灯引脚为pio.P0_4

pmd.ldoset(2, pmd.LDO_VLCD)
netLed.setup(true, pio.P0_1, pio.P0_4)
-- 网络指示灯功能模块中，默认配置了各种工作状态下指示灯的闪烁规律，参考netLed.lua中ledBlinkTime配置的默认值
-- 如果默认值满足不了需求，此处调用netLed.updateBlinkTime去配置闪烁时长

-- SIM 自动切换开关
ril.request("AT*SIMAUTO=1")

-- @author openLuat
-- @module call.testCall
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.20

module(..., package.seeall)

