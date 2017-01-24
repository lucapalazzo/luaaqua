aqua = require("aqua")
debug_level = 0

ad = aquadevice:new()
ad.read_delay = 0.3
ad.device_host = "192.168.168.40"
ad.device_port = 23
a = aqua:new ( ad )
a:openDevice()
--a:setOnOff ( true )
--a:setBoost ( true )
--a:getTime()
--a:getStatus()
--a:getPhase()
--a:setStatus ( StatusOnOff, true )
-- a:setStatus ( StatusBoost, false )
--a:setWorkingMode(ExternalTimer)
a:getAlarms()
a:getAllRegisters()
--a:resetParam(AlarmCellMan)
--a:setChlorineSetpoint( 50 )
--a:getChemStatus()
--a:setContainerType(0)
--a:getContainerType()
-- a:getPumpStatus()
a:closeDevice()
print ( string.format ( "Cloro PPM %.02f. PH %.02f. Temperatura %.02f. Salinità istantanea %.02f media %.02f.", a.chlorine, a.ph, a.temperature, a.salinity, a.salinity_average ) )
print ( string.format ( "Type %s Working mode %d Status %d Timer %d Phase %d Timer %d", a.type, a.working_mode, a.status, a.status_timer, a.phase, a.phase_timer ) )
print ( string.format ( "Alarm %s working mode %d", tostring ( a.alarm ), a.working_mode ) )
print ( string.format ( "Pump request %d status %d", a.pump_request, tostring ( a.pump_status ) ) )
print ( string.format ( "Alarm: General %s PH %d flow %d Hi T %d Low T %d Low salt %d Pump status %d relay status %d", a.alarm, a.alarm_ph_level, a.alarm_flow, a.alarm_high_temperature, a.alarm_low_temperature, a.alarm_low_salinity, a.pump_request, a.pump_status ) )
print ( string.format ( "Status: Enough PH %d Salinity %d flow %d", a.enough_ph,  a.enough_salinity, a.flow ) )

print ( string.format ( "Alarm: Cell maintainance %d pre change %d change %d", a.alarm_cell_maintainance, a.alarm_pre_cell_change, a.alarm_cell_change ) )


--

--mb:readInputStatus(0x01, 0x00, 28 )
--mb:getFrame()
----mb:readHoldingRegister(0x01, 4, 0x06)
----frame = mb:getFrame()
--if ( frame == nil or frame.values == nil or frame.exception ~= 0) then
--  print ( "Error getting frame" );
--  mb:closeDevice()
--  return
--end

--print ( "Tipo: " .. type ( frame.values ) )
--values_string = "Numero valori " .. #frame.values
--for key, value in ipairs(frame.values) do
--  values_string = values_string .. mb.packetdump ( frame.values[key] )
--end
--print ( values_string )
-- minutes = tonumber (string.sub (frame.values[1],1,1), 16 )-- + tonumber(string.sub (frame.values[1],2,2))
--print ( mb.packetdump ( string.sub (frame.values[1],1,2 ) ) )

----print ( values_string )
--print ( string.format ( "Ore %d:%d del %d/%d/%d (%d)", hours, minutes, month_day, month, year, week_day ) )
-- mb:writeSingleCoil(0x01, 14, 0xff00)
-- mb:getFrame()
-- mb:readInputStatus(0x01, 01, 1 )

--mb:readCoils(0x01, 0x0040, 0x0001)
--mb:print()
--mb:prepareFrame(17, 3, 0x006b, 0x0003 )
--mb:parseFrame ( ":1101056b00037e" )
-- :0105000EFF00ED
--mb:parseFrame ( ":1f0105CD6BB20E1B45E6" )
