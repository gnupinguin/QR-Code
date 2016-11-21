require 'opencv'
include OpenCV

module qr-functions
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
end
