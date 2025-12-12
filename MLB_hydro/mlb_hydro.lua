function IfThenElse(condition,t,f) 
  if condition then
    return t
  else
    return f
  end 
end

function isinside(coordsX,coordsY, x0, y0, r0, value)
   r = math.sqrt((coordsX-x0)*(coordsX-x0) + (coordsY-y0)*(coordsY-y0))
   if (r < r0) then
      -- print (value)
      return value
   else
      return 0.0
   end
end

function initialcavity(coordsX,coordsY, x0, y0, r0)
   r = math.sqrt((coordsX-x0)*(coordsX-x0) + (coordsY-y0)*(coordsY-y0))
   if (r < r0) then
      return (1.0 - r/r0)
   else
      return 0.0
   end
end 
