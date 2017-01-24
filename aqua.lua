local aqua = {}
modbus = require( "modbus_native" )


local SERIAL, SERIALoIP = 0, 1
local Sconosciuto, Work, Boost, Miscelazione, Startup, Controlavaggio, Off = 0, 1, 2, 3, 4, 5, 6
StatusOnOff, StatusBoost, StatusWinter, StatusControlavaggio, StatusMiscelazione, StatusStartup, StatusStandBy = 4, 6, 7, 8, 9, 10, 11
InternalTimer, ExternalTimer, Proportional = 0, 1, 2
ResetAvgSalinity, AlarmCellMan, AlarmCellChange  = 17, 18, 19

aqua.device = nil
aqua.modbus = nil
aqua.status = 0
aqua.status_timer = 0
aqua.phase = 0
aqua.phase_timer = 0
aqua.temperature = 0
aqua.chlorine = 0
aqua.chlorine_point = 0
aqua.ph = 0
aqua.ph_setpoint = 0
aqua.salinity = 0
aqua.salinity_average = 0
aqua.salinity_setpoint = 0
aqua.voltage = 0
aqua.amperage = 0

aquadevice = {}
aquadevice.connection_type = SERIALoIP
aquadevice.slave_id = 1
aquadevice.device_speed = 9600
aquadevice.device_bits = 8
aquadevice.device_parity = NOPARITY
aquadevice.device_stopbit = 1
aquadevice.device_host = nil
aquadevice.device_port = nil
aquadevice.read_delay = 0

function aquadevice:new ( connection_type )
  _ad =  {}
  setmetatable(_ad, self)
  self.__index = self
  if ( connection_type ~= nil ) then
    _ad.connection_type = connection_type
  end
  

  return _ad
end



function aqua.new ( aquadevice )
  _a = {}
  if ( aquadevice == nil ) then
    debug ( 1, "No device parameter sent" )
    return nil
  end
  
  _a.device = aquadevice
  
  setmetatable(_a, self)
  _a.__index = _a
  return _a
end

function aqua:new ( aquadevice )
  _a = {}
  
  if ( aquadevice == nil ) then
    debug ( 1, "No device parameter sent" )
    return nil
  end
  
  setmetatable(_a, self)
  self.__index = self
  _a.device = aquadevice
  _a.modbus = modbus:new()
  
  return _a
end


function aqua:getAllRegisters()
  debug ( 1, string.format ( "aqua:getAllRegister(): getting all registers from device" ) )
  
--  local frame = self.modbus:readHoldingRegister(0x01, 0, 2)
--  device_type = frame.values[1]:byte(1)*256+frame.values[1]:byte(2)
--  device_version = frame.values[2]:byte(1)*256+frame.values[2]:byte(2)
--  debug ( 1, string.format ( "Type 0x%04x version 0x%04x", device_type, device_version ) )
  
--  frame = self.modbus:readHoldingRegister(0x01, 3, 11)
--  partial_frame = frame
--  partial_frame.size = 6
--  table.remove ( partial_frame.values, 1 )
--  table.remove ( partial_frame.values, 7, 14 )
--  self:getTime( partial_frame )
  
  
  
--  local frame = self.modbus:readHoldingRegister(0x01, 0, 14)
--  if ( frame == nil ) then
--    debug ( 1, "aqua:getAllRegister(): nil frame received")
--    return nil
--  end
--  partial_frame = frame:copy() 
--  partial_frame:crop_values ( nil, 3 )
--  
  local frame = self.modbus:readHoldingRegister(0x01, 15, 50)
  
  if ( frame == nil ) then
    debug ( 1, "aqua:getAllRegister(): nil frame received")
    return nil
  end

 
--  debug ( 5, "Full: " .. tostring ( frame.values) .. " " .. modbus.packetdump ( frame.values ) )
--  debug ( 5, "Partial: " .. tostring ( power_frame.values) .. " " .. modbus.packetdump ( power_frame.values ) )
  
  self:getStatus( frame )
  

  
  power_frame = frame:copy()
  power_frame:crop_values (13)
 
--  debug ( 5, "Full: " .. tostring ( frame.values) .. " " .. modbus.packetdump ( frame.values ) )
--  debug ( 5, "Partial: " .. tostring ( power_frame.values) .. " " .. modbus.packetdump ( power_frame.values ) )
  
  self:getPowerStatus( power_frame )
  
  
  chem_frame = frame:copy()
  chem_frame:crop_values (25)
 
  debug ( 5, "Full: " .. tostring ( frame.values) .. " " .. modbus.packetdump ( frame.values ) )
  debug ( 5, "Partial: " .. tostring ( chem_frame.values) .. " " .. modbus.packetdump ( chem_frame.values ) )
  
  self:getChemStatus( chem_frame )
  
  
--  local frame = self.modbus:readHoldingRegister(0x01, 65, 13)
--  local frame = self.modbus:readHoldingRegister(0x01, 80, 50)
--  local frame = self.modbus:readHoldingRegister(0x01, 131, 31)
  
  if ( frame == nil ) then
    debug ( 1, "Error reading from device" )
    return nil
  end
  
  if ( frame.exception > 0 ) then
    debug ( 1, "Device returned exception: " .. frame.exception_string )
    return nil
  end
end


function aqua:getAlarms()
  debug ( 1, string.format ( "aqua:getPumpStatus(): getting pump status" ) )
  
  local frame = self.modbus:readInputStatus(0x01, 0, 24)
  
  if ( frame == nil ) then
    debug ( 1, "Error reading from device" )
    return nil
  end
  
  if ( frame.exception > 0 ) then
    debug ( 1, "Device returned exception: " .. frame.exception_string )
  end
  self.enough_ph = bit32.band( frame.values[1]:byte(1), 1 )       
  self.flow = bit32.band( frame.values[1]:byte(1), 2 )
  self.closure = bit32.band( frame.values[1]:byte(1), 4 )
  self.enough_salinity = bit32.band( frame.values[1]:byte(1), 8 )
  self.alarm_flow = bit32.band( frame.values[1]:byte(1), 16 )
  self.alarm_high_temperature = bit32.band( frame.values[1]:byte(1), 32 )
  self.alarm_low_temperature = bit32.band( frame.values[1]:byte(1), 64 )
  self.alarm_low_salinity = bit32.band( frame.values[1]:byte(1), 128 )
  self.alarm_not_enough_salinity = bit32.band( frame.values[2]:byte(1), 1 )
  self.alarm_high_salinity = bit32.band( frame.values[2]:byte(1), 2 )
  self.alarm_ice = bit32.band( frame.values[2]:byte(1), 4 )
  self.alarm_ofa_chlorine = bit32.band( frame.values[2]:byte(1), 8 )
  self.alarm_ofa_ph = bit32.band( frame.values[2]:byte(1), 16 )
  self.alarm_ph_level = bit32.band( frame.values[2]:byte(1), 32 )
  self.alarm_temperature_probe = bit32.band( frame.values[2]:byte(1), 64 )
  self.alarm_current = bit32.band( frame.values[2]:byte(1), 128 )
  self.alarm_cell_maintainance = bit32.band( frame.values[3]:byte(1), 1 )
  self.alarm_pre_cell_change = bit32.band( frame.values[3]:byte(1), 2 )
  self.alarm_cell_change = bit32.band( frame.values[3]:byte(1), 4 )
  self.alarm_ofa_salinity = bit32.band( frame.values[3]:byte(1), 8 )
  self.pump_request = bit32.band( frame.values[3]:byte(1), 16 )
  self.pump_status = bit32.band( frame.values[3]:byte(1), 32 )
  self.alarm_salinity = bit32.band( frame.values[3]:byte(1), 64 )
  self.alarm_pump = bit32.band( frame.values[3]:byte(1), 128 )

  self.alarm = bit32.band ( frame.values[1]:byte(1) + frame.values[2]:byte(1)*256 + frame.values[3]:byte(1)*256^2, 13631440 )  
  debug ( 1, string.format ( "Alarm: General %s PH %d flow %d Hi T %d Low T %d Low salt %d Pump status %d relay status %d", self.alarm, self.alarm_ph_level, self.alarm_flow, self.alarm_high_temperature, self.alarm_low_temperature, self.alarm_low_salinity, self.pump_request, self.pump_status ) )
  return
end

function aqua:resetParam( param )
  debug ( 1, string.format ( "aqua:resetParam( %s ): resetting param %s", tostring(param), tostring(param) ) )

  if ( param == nil or param < 17 or param > 19 ) then
    debug ( 1, string.format ( "aqua:resetParam( %s ): wrong parameter %s", tostring(param), tostring(param) ) )
    return nil
  end

  address = param
  
  frame = self.modbus:writeSingleCoil(self.slave_id, address, true )
  
  --  frame:print()
end

function aqua:getPhaseTimer()
  debug ( 1, string.format ( "aqua:getPhase(): getting phase from device" ) )
  
  local frame = self.modbus:readHoldingRegister(0x01, 21, 0x02)
  
  if ( frame == nil ) then
    debug ( 1, "Error reading from device" )
    return nil
  end
  
  if ( frame.exception > 0 ) then
    debug ( 1, "Device returned exception: " .. frame.exception_string )
  end

  device_phase_timer_low = frame.values[1]:byte(1)*256+frame.values[1]:byte(2)
  device_phase_timer_high = frame.values[2]:byte(1)*256+frame.values[2]:byte(2)
  debug ( 1, string.format ( "Phase timer low %d high %d", device_phase_timer_low, device_phase_timer_high ) )
  return device_phase

end


function aqua:getPhase()
  debug ( 1, string.format ( "aqua:getPhase(): getting phase from device" ) )
  
  local frame = self.modbus:readHoldingRegister(0x01, 20, 0x01)
  
  if ( frame == nil ) then
    debug ( 1, "Error reading from device" )
    return nil
  end
  
  if ( frame.exception > 0 ) then
    debug ( 1, "Device returned exception: " .. frame.exception_string )
  end

  device_phase = frame.values[1]:byte(1)*256+frame.values[1]:byte(2)
  debug ( 1, string.format ( "Phase %d", device_phase ) )
  return device_phase

end

function aqua:getStatus( frame )
  debug ( 1, string.format ( "aqua:getStatus(): getting status from device" ) )
  
  if ( frame == nil ) then
    frame = self.modbus:readHoldingRegister(0x01, 15, 8)
  else
        debug ( 5, "aqua:getStatus(): getting frame from function args " .. modbus.packetdump ( frame.values ) )
  end
  
  if ( frame == nil ) then
    debug ( 1, "Error reading from device" )
    return nil
  end
  
  
  if ( frame.exception > 0 ) then
    debug ( 1, "Device returned exception: " .. frame.exception_string )
    return nil
  end
  
  device_type = frame.values[1]:byte(1)*256+frame.values[1]:byte(2)
  device_status = frame.values[2]:byte(1)*256+frame.values[2]:byte(2)
  device_status_timer = frame.values[4]:byte(1)*256^3+frame.values[4]:byte(2)*256^2+frame.values[3]:byte(1)*256+frame.values[3]:byte(2)
  if ( device_status_timer == 0xffffffff) then
    device_status_timer = 0
  
  end
  device_phase = frame.values[6]:byte(1)*256+frame.values[6]:byte(2)
  device_phase_timer = frame.values[8]:byte(1)*256^3+frame.values[8]:byte(2)*256^2+frame.values[7]:byte(1)*256+frame.values[7]:byte(2)
  self.status = device_status
  self.status_timer = device_status_timer
  self.phase = device_phase
  self.phase_timer = device_phase_timer
  self.working_mode = frame.values[16]:byte(1)*256+frame.values[16]:byte(2)
  debug ( 1, string.format ( "Type %s Status %d Timer %d Phase %d Timer %d Working mode %s", device_type, device_status, device_status_timer, device_phase, self.phase_timer, tostring( self.working_mode ) ) )
end

function aqua:getTime( frame )
  debug ( 1, string.format ( "aqua:getTime(): getting time from device" ) )
  
  if ( frame == nil ) then
    frame = self.modbus:readHoldingRegister(0x01, 4, 0x06)
  else
    debug ( 5, "Getting frame from function args" )
  end
  
  if ( frame == nil ) then
    print ( "Error reading from device" )
    return nil
  end
  
  if ( frame.exception > 0 ) then
    print ( "Device returned exception: " .. frame.exception_string )
  end
  
  device_minutes = frame.values[1]:byte(1)*256+frame.values[1]:byte(2)
  device_hours = frame.values[2]:byte(1)*256+frame.values[2]:byte(2)
  device_week_day = frame.values[3]:byte(1)*256+frame.values[3]:byte(2)
  device_month_day = frame.values[4]:byte(1)*256+frame.values[4]:byte(2)
  device_month = frame.values[5]:byte(1)*256+frame.values[5]:byte(2)
  device_year = frame.values[6]:byte(1)*256+frame.values[6]:byte(2)
  
  device_time = os.time({year = device_year+2000, month = device_month, 
        day = device_month_day, hour = device_hour, min = device_minute, sec = 0})
  local_time = os.time()
  debug ( 1, string.format ( "Ore %d:%d del %d/%d/%d (%d) Timestamp %d (local %d)", device_hours, device_minutes, device_month_day, device_month, device_year, device_week_day, device_time, local_time ) )
end

function aqua:getChemStatus( frame )
  debug ( 1, string.format ( "aqua:getChemStatus(): getting chemical status from device" ) )
  
  if ( frame == nil ) then
    frame = self.modbus:readHoldingRegister(0x01, 40, 8)
  else
    debug ( 5, "Getting frame from function args " .. modbus.packetdump ( frame.values ) )
    
  end
  
  if ( frame == nil ) then
    print ( "Error reading from device" )
    return nil
  end
  
  if ( frame.exception > 0 ) then
    print ( "Device returned exception: " .. frame.exception_string )
  end
  
  chlorine_status = (frame.values[1]:byte(1)*256+frame.values[1]:byte(2))/100
  chlorine_setpoint = (frame.values[2]:byte(1)*256+frame.values[2]:byte(2))/100
  ph_status = (frame.values[3]:byte(1)*256+frame.values[3]:byte(2))/100
  ph_setpoint = (frame.values[4]:byte(1)*256+frame.values[4]:byte(2))/10
  temperature = (frame.values[5]:byte(1)*256+frame.values[5]:byte(2))/10
 
  salt_status = (frame.values[6]:byte(1)*256+frame.values[6]:byte(2))/1000
  if ( salt_status == 65.535 ) then
    salt_status = 0
  end
  salt_status_average = (frame.values[7]:byte(1)*256+frame.values[7]:byte(2))/1000
  salt_setpoint = frame.values[8]:byte(1)*256+frame.values[8]:byte(2)/10
  polarization_time = frame.values[8]:byte(1)+frame.values[8]:byte(2)*256
  
  self.chlorine = chlorine_status
  self.chlorine_setpoint = chlorine_setpoint
  self.ph = ph_status
  self.ph_setpoint = ph_setpoint
  self.temperature = temperature
  self.salinity = salt_status
  self.salinity_average = salt_status_average
  self.salinity_setpoint = salt_status_point

  debug ( 1, string.format ( "Cloro PPM %.02f setpoint %.02f PPM. PH %.02f setpoint %.02f. Temperatura %.02f. Salinità istantanea %.02f media %.02f setpoint %.02f g/l. Tempo di polarizzazione %d sec", chlorine_status, chlorine_setpoint, ph_status, ph_setpoint, temperature, salt_status, salt_status_average, salt_setpoint, polarization_time ) )


end

function aqua:getPowerStatus( frame )
  debug ( 1, string.format ( "aqua:getPowerStatus(): getting power status from device" ) )
  
  if ( frame == nil ) then
    frame = self.modbus:readHoldingRegister(0x01, 28, 2)
  else
    debug ( 5, "aqua:getPowerStatus(): Getting frame from function args " .. modbus.packetdump ( frame.values ) )
    
  end
  
  if ( frame == nil ) then
    debug ( 1, "aqua:getPowerStatus(): Error reading from device" )
    return nil
  end
  
  if ( frame.exception > 0 ) then
    debug ( 1, "aqua:getPowerStatus(): Device returned exception: " .. frame.exception_string )
  end

  volt_status = frame.values[1]:byte(1)*256+frame.values[1]:byte(2)
  
  if ( bit32.band(volt_status, 32768 ) == 32768 ) then
    v = 0xffff - volt_status
    debug ( 5, "aqua:getPowerStatus(): volt_status negative value")
    volt_status = - ( 65535 - volt_status )/100
  else
    volt_status = volt_status/100
  end
  
  ampere_status = (frame.values[2]:byte(1)*256+frame.values[2]:byte(2))
  if ( bit32.band(ampere_status, 32768 ) == 32768 ) then
    debug ( 5, "aqua:getPowerStatus(): ampere_status negative value")
    ampere_status = - ( 65535 - ampere_status )/100
  else
    ampere_status = ampere_status/100
  end
  
  self.voltage = volt_status
  self.amperage = ampere_status
  
  debug ( 1, string.format ( "Tensione %.02f V assorbimento %.02f A", volt_status, ampere_status ) )


end


function aqua:getContainerType()
  debug ( 1, string.format ( "aqua:getContainerType(): getting container type from device" ) )
  
  frame = self.modbus:readHoldingRegister(0x01, 39, 1)
  
  if ( frame == nil ) then
    debug ( 1, "Error reading from device" )
    return nil
  end
  
  if ( frame.exception > 0 ) then
    debug ( 1, "Device returned exception: " .. frame.exception_string )
  end
  
  container_type = frame.values[1]:byte(1)*256+frame.values[1]:byte(2)
  debug ( 1, string.format ( "Container %d", container_type ) )


end

function aqua:setTimer( timer )
  debug ( 1, string.format ( "aqua:setTimer( %s ): setting time to %s", tostring(timer) ) )
  
  if ( timer == nil or timer < 0 or timer > 2 ) then
    debug ( 1, string.format ( "aqua:setTimer( %s ): wrong timer %s", tostring(timer) ) )
    return nil
  end

  address = 30
  
  frame = self.modbus:writeSingleRegister(self.slave_id, address, timer )
  frame:print()
end

function aqua:setStatus( status, switch )
  debug ( 1, string.format ( "aqua:setStatus( %s ): setting status of %s to %s", tostring(status), tostring(switch), tostring(status) ) )
  
  if ( status == nil or status < 4 or status > 11 ) then
    debug ( 1, string.format ( "aqua:setStatus( %s ): wrong status %s", tostring(status), tostring(status) ) )
    return nil
  end

  address = status
  
  frame = self.modbus:writeSingleCoil(self.slave_id, address, switch )
  
  
  frame:print()
end

function aqua:setBoost( status )
  debug ( 1, string.format ( "aqua:setStatus( %s ): setting boost to %s", tostring(status), tostring(status) ) )
  
  frame = self.modbus:writeSingleCoil(self.slave_id, 6, status)
  
  
  frame:print()
end

function aqua:setWorkingMode( mode )
  debug ( 1, string.format ( "aqua:setWorkingMode( %d ): setting workging mode to %d", mode, mode ) )
  frame = self.modbus:writeSingleRegister(self.slave_id, 30, mode)
    
  frame:print()
end



function aqua:setContainerType( type )
  debug ( 1, string.format ( "aqua:setContainerType( %d ): setting container type", type ) )
  
  frame = self.modbus:writeSingleRegister(self.slave_id, 39, type)
  
  
  frame:print()
--  chlorine_status = frame.values[1]:byte(1)*256+frame.values[1]:byte(2)
--  chlorine_setpoint = frame.values[2]:byte(1)*256+frame.values[2]:byte(2)
--  ph_status = (frame.values[3]:byte(1)*256+frame.values[3]:byte(2))/100
--  ph_setpoint = (frame.values[4]:byte(1)*256+frame.values[4]:byte(2))/10
--  temperature = (frame.values[5]:byte(1)*256+frame.values[5]:byte(2))/10
--  salt_status = (frame.values[6]:byte(1)*256+frame.values[6]:byte(2))
--  salt_status_average = (frame.values[7]:byte(1)*256+frame.values[7]:byte(2))
--  salt_setpoint = frame.values[8]:byte(1)*256+frame.values[8]:byte(2)/1

end

function aqua:setChlorineSetpoint( setpoint )
  debug ( 1, string.format ( "aqua:setChlorineSetpoint( %d ): setting container type", setpoint ) )
  
  frame = self.modbus:writeSingleRegister(self.slave_id, 41, setpoint*100)
  
  
  frame:print()
--  chlorine_status = frame.values[1]:byte(1)*256+frame.values[1]:byte(2)
--  chlorine_setpoint = frame.values[2]:byte(1)*256+frame.values[2]:byte(2)
--  ph_status = (frame.values[3]:byte(1)*256+frame.values[3]:byte(2))/100
--  ph_setpoint = (frame.values[4]:byte(1)*256+frame.values[4]:byte(2))/10
--  temperature = (frame.values[5]:byte(1)*256+frame.values[5]:byte(2))/10
--  salt_status = (frame.values[6]:byte(1)*256+frame.values[6]:byte(2))
--  salt_status_average = (frame.values[7]:byte(1)*256+frame.values[7]:byte(2))
--  salt_setpoint = frame.values[8]:byte(1)*256+frame.values[8]:byte(2)/1

end

function aqua:openDevice()
  debug ( 1, string.format ( "aqua:openDevice(): opening device" ) )
  if ( self.device.connection_type == SERIAL ) then
    debug ( 1, string.format ( "Connecting to serial interface %s", tostring(self.device) ) )
    self.modbus.device = self.device
  else
      debug ( 1, "Connection " .. self.device.device_host )

    if ( self.device.device_host == nil or self.device.device_host == nil ) then
        debug ( 1, "Aqua Remote host and port not set" )
        return false
      
    end
    self.modbus.host = self.device.device_host
    self.modbus.port = self.device.device_port
    
    self.modbus.read_delay = self.device.read_delay
    self.modbus:openDevice()
    return self.modbus.device
  end
  
  return nil
end

function aqua:closeDevice()
  debug ( 5, string.format ( "aqua:closeDevice(): opening device" ) )
  if ( self.device.connection_type == SERIAL ) then
    debug ( 5, string.format ( "aqua:closeDevice(): cconnecting to serial interface %s", tostring(self.device) ) )
    self.modbus.device = self.device
  else
      debug ( 5, "aqua:closeDevice(): connection " .. self.device.device_host )

    
    return self.modbus:closeDevice()
  end
  
  return nil
end

function hex2float (c)
    if c == 0 then return 0.0 end
    local c = string.gsub(string.format("%X", c),"(..)",function (x) return string.char(tonumber(x, 16)) end)
    local b1,b2,b3,b4 = string.byte(c, 1, 4)
    local sign = b1 > 0x7F
    local expo = (b1 % 0x80) * 0x2 + math.floor(b2 / 0x80)
    local mant = ((b2 % 0x80) * 0x100 + b3) * 0x100 + b4

    if sign then
        sign = -1
    else
        sign = 1
    end

    local n

    if mant == 0 and expo == 0 then
        n = sign * 0.0
    elseif expo == 0xFF then
        if mant == 0 then
            n = sign * math.huge
        else
            n = 0.0/0.0
        end
    else
        n = sign * math.ldexp(1.0 + mant / 0x800000, expo - 0x7F)
    end

    return n
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

return aqua
