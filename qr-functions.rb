require 'opencv'
include OpenCV

def depth(contour_tree)
  count = 0;
  while contour_tree = contour_tree.v_next
    count += 1;
  end
  return count;
end

def distance(p1, p2)
  Math.sqrt( (p1.x - p2.x)**2 + (p1.y - p2.y)**2 )
end

def lineEquation(pL, pM, pJ)#pL, pM, pJ - points
  a = -((pM.y - pL.y) / (pM.x - pL.x));
	b = 1.0;
	c = (((pM.y - pL.y) /(pM.x - pL.x)) * pL.x) - pL.y;

  # Now that we have a, b, c from the equation ax + by + c, time to substitute (x,y) by values from the Point J

	pdist = (a * pJ.x + (b * pJ.y) + c) / sqrt((a * a) + (b * b));
	return pdist;
end

def lineSlope(pL, pM)#pL, pM - points
  dx = pM.x - pL.x;
  dy = pM.y - pL.y;

  if dy != 0
    alignement = 1;
    return [(dy / dx), alignement];
  else				# Make sure we are not dividing by zero; so use 'alignement' flag
    alignement = 0;
    return [0.0, alignement];
  end
end
