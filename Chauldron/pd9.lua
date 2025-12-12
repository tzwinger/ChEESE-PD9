xoffset = 500000.0                                                              
yoffset = 500000.0
vertoffset = 120.0
relxpress = 35000.0
xmax=40000.0                                                                    
xradius = 500.0
yradius = 500.0
channelx = 4000.0
--cavamplitude = 50.0
champlitude = 1.0
channellength = 2000.0
channelwidth = 100.0
-- ampltd=0.5
wvlngth=300.0
flat=20000.0
-- surf=1000
-- Pext = 2.0E05
href = 550.0
--initialwaterlevel = (Pext/gravity + rhoi*href)/rhow


initialwaterlevel=541.23319
-- initialwaterlevel =  1.01*rhoi*href/rhow
calderaarea=math.pi*xradius*yradius

function pressureinlet1(x,d)
   currentx = xoffset + relxpress
   distx = x - currentx
   -- print ("x:",distx/xradius)
   return (rhoi*d*gravity + Pext)*distx/xradius
end

function pressureinlet2(y,d)
   currenty = 0.0 + yoffset
   disty = y - currenty
   -- print ("y:",disty/yradius)
   return (rhoi*d*gravity + Pext)*disty/yradius
end


function initbedrocklowering(x,y)
  currentx = xoffset + relxpress - xradius/2
  currenty = 0.0 + yoffset
  distx = x - currentx
  disty = y - currenty
  amplitude = 0.5
  
  return amplitude*math.max(1.0 - math.sqrt(distx*distx/(xradius*xradius) + disty*disty/(yradius*yradius)), 0.0)
end

function initialcavity(x,y)
  currentx = xoffset + relxpress
  currenty = 0.0 + yoffset
  distx = (x - currentx)/xradius
  disty = (y - currenty)/yradius
  deformation = 0.0
  deformation =  (champlitude + cavamplitude)*math.max(1.0 - math.sqrt(distx^2.0 + disty^2.0), 0.0) 
  if ((x <= currentx) and (x > currentx - channellength)) then
     -- realamplitude =  champlitude*(1.0 - ((currentx -x)/channellength)^(0.5))
     effchannelwidth = yradius - (yradius - channelwidth)*(currentx -x)/channellength
     disty = (y - currenty)/effchannelwidth
     deformation = math.max(deformation,champlitude*math.max(1.0 - disty^2, 0.0))
  end
  return deformation
end

function initialpressure(x,y,depth,pressurescale)
   pressure = pressurescale*rhoi*gravity*depth
   if (initialcavity(x,y) > 0.0) then
      refmaxelev = bedrock(xoffset + relxpress + xradius, 0.0 + yoffset)
      -- refpressure = initialcavity(xoffset + relxpress, 0.0)*rhoi*gravity
      pressure = pressure + (refmaxelev -  bedrock(x,y))*rhow*gravity
      print(bedrock(xoffset + relxpress, 0.0 + yoffset),cavamplitude,bedrock(x,y),(refmaxelev -  bedrock(x, y))*rhow*gravity)      
   end
   return pressure
end
   

function initchannel(x,y)
  currentx = xoffset + relxpress - channelx + xradius/2
  currenty = 0.0 + yoffset
  distx = (x - currentx)/channelx
  disty = (y - currenty)/yradius
  -- print(x,y,math.max(1.0 - distx^8, 0.0),math.max(1.0 - disty^2, 0.0))
  amplitude = 0.8
  return amplitude * math.max(1.0 - distx^8, 0.0) * math.max(1.0 - disty^2 , 0.0)
end

function pressuresignal(x,y,d)
  currentx = xoffset + relxpress
  currenty = 0.0 + yoffset
  distx = x - currentx
  disty = y - currenty
  dist = math.sqrt(distx*distx/(xradius*xradius) + disty*disty/(yradius*yradius))
  if (dist <= 1) then
    -- force = Pext*(1.0 - dist)*(1.0 - dist) + rhoi*d*gravity
       force = Pext + rhoi*d*gravity 
    -- print(force, currentx, Pext)
  else
    force = 0.0
  end
  return force
end

function transmitivity(x,y,d,t)
  currentx = xoffset + relxpress
  currenty = 0.0 + yoffset
  distx = x - currentx
  disty = math.abs(y - currenty)
  dist = math.sqrt(distx*distx/xradius/xradius + disty*disty/yradius/yradius)
  if (d <= h0) then
    return t
  elseif (dist <= 1) then
    return t
  else
    return 0.0
  end
end

function bedrock(x,y)
    if (x>xoffset + flat) then
       bpfr = vertoffset + 500*(x-(xoffset + flat))/20000
    else
	bpfr = vertoffset 
    end
    if (math.abs(y-yoffset)>4000) then
	vvprf = 0
    else
	vvprf = -50.0*(1.0 + math.cos((y-yoffset)*math.pi/4000))
    end
    attenuation = (math.tanh((x - xoffset - 5000.0)/5000.0) + 1.0)/2.0 
    return bpfr + vvprf*attenuation
end

function undulations(x,y)
    if (x > xoffset + flat) then
        glbb = ampltd*math.cos(2*math.pi*(x-xoffset)/wvlngth)*math.cos(2*math.pi*(y-yoffset)/wvlngth)
    elseif (x > xoffset) then
       glbb =  ampltd*math.cos(2*math.pi*(x-xoffset)/wvlngth)*math.cos(2*math.pi*(y-yoffset)/wvlngth) * (x - xoffset)/flat
    else
	glbb = 0.0
    end
    -- bad idea, as the random generator might give different values for shared points on both sides of partitions
    -- return math.random()*glbb
    return glbb
end
    
function surface(x)
    if (x<510000.0) then
	srfc = vertoffset + (x-xoffset)*(25000-(x-xoffset))*0.075/25000
    else
	srfc = vertoffset + 300 + 600*(x-xoffset)/40000
    end
    return srfc
end

function waterlevel(sheetvolume)
  return initialwaterlevel - sheetvolume/calderaarea
end

function IfThenElse(condition,t,f) 
   if condition then
     return t
   else
     return f
   end 
end
