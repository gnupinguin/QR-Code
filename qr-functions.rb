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


def lineSlope(p1, p2)#pL, pM - points
  dx = p2.x - p1.x;
  dy = p2.y - p1.y;

  if dx != 0
    perpendicular = 0;
    return [(dy / dx), perpendicular];
  else
    perpendicular = 1;
    return [0.0, perpendicular];
  end
end

def getLine(p1, p2)
  k = (p1.y - p2.y) / (p1.x - p2.x);
  b = p1.y - k * p1.x;
  return [k, b];
end

#NEED TO DO SMART SEARCH!!!!
def getMarkers(binImage)
  contours = binImage.find_contours(:mode => OpenCV::CV_RETR_TREE, :method => OpenCV::CV_CHAIN_APPROX_SIMPLE);

  markers = [];
  content = contours;#NEED TO DO SMART SEARCH!!!!

  while content
    if depth(content) >= 5
      markers << content;
    end
    content = content.h_next;
  end
  markers.size.times{|i|
    markers[i] = markers[i].approx_poly
  }

  return markers;
end

def getMassCenter(marker)
  m = CvMoments.new(marker, false);
  return CvPoint.new(m.m10 / m.m00, m.m01 / m.m00);
end

def getMassCenters(markers)
  massCenters = [];

  markers.each { |e|
    massCenters << getMassCenter(e);
  }
  return massCenters;
end

def getLocationMarkers(markers, massCenters)
  a, b, c = 0, 1, 2;
  ab = distance(massCenters[a], massCenters[b]);
  bc = distance(massCenters[b], massCenters[c]);
  ca = distance(massCenters[c], massCenters[a]);

  outlier, median1, median2  = nil;

  if  ab > bc && ab > ca
    outlier = c; median1 = a; median2 = b;
  elsif ( ca > ab && ca > bc )
    outlier = b; median1 = a; median2 = c;
  elsif ( bc > ab && bc > ca )
    outlier = a;  median1 = b; median2 = c;
  end

  if massCenters[median1].x > massCenters[median2].x
    median1, median2 = median2, median1;
  end
  return [median1, median2, outlier];
end

def rotateDiag(image)
  gray  = image.BGR2GRAY
  bin = gray.threshold(0x44, 0xFF, :binary)
  canny = gray.canny(50, 150)
  markers = getMarkers(canny);

  massCenters = getMassCenters(markers);
  # circle_options = { :color => CvColor::Red, :line_type => :aa, :thickness => -1 }
  # massCenters.each{|e|
  #   image.circle! e, 1, circle_options
  # }
  #
  # markers.each { |e|
  #   image.draw_contours!(e, CvColor::Red, CvColor::Green, 2,
  #                            :thickness => 2, :line_type => :aa)
  # }

  median1, median2, outlier = getLocationMarkers(markers, massCenters)#median1 on the left then median2
  slopeDiag, perpDiag = lineSlope(massCenters[median1], massCenters[median2]);

  if perpDiag == 1
    angle = (massCenters[outlier].x < massCenters[median1].x)? -45 : 90;
    center = CvPoint.new image.width/2, image.height/2
    image = image.warp_affine(CvMat.rotation_matrix2D(center, angle, 1))

  elsif slopeDiag != -1 # why -1?
    currentAngle = Math.atan(slopeDiag) * 180 / Math::PI;
    currentAngle = currentAngle > 0 ? 180 - currentAngle : currentAngle;
    angle =  45 - currentAngle;
    center = CvPoint.new image.width/2, image.height/2
    image = image.warp_affine(CvMat.rotation_matrix2D(center, angle, 1))
  end
  # window1 = GUI::Window.new('Side Rotate window') # Create a window for display.
  # window1.show(image) # Show our image inside it.
  # GUI::wait_key
  return image;
end

def rotateSide(image)
  gray  = image.BGR2GRAY
  bin = gray.threshold(0x44, 0xFF, :binary)
  canny = gray.canny(50, 150)
  markers = getMarkers(canny);
  massCenters = getMassCenters(markers);
  median1, median2, outlier = getLocationMarkers(markers, massCenters)
  # image.draw_contours!(massCenters[outlier], CvColor::Red, CvColor::Green, 2,
  #                         :thickness => 2, :line_type => :aa)
  # circle_options = { :color => CvColor::Blue, :line_type => :aa, :thickness => -1 }
  # image.circle! massCenters[median1], 4, circle_options
  # window1 = GUI::Window.new('Side Rotate window') # Create a window for display.
  # window1.show(image) # Show our image inside it.
  # GUI::wait_key

  slopeSide1, perpSide1 = lineSlope(massCenters[outlier], massCenters[median1]);#slopeSide1 may be equal 0 and perpSide1 = 1
  slopeSide2, perpSide2 = lineSlope(massCenters[outlier], massCenters[median2]);#slopeSide2 may be equal 0

  angle = 0;
  if perpSide1 != 1
    currentAngle = Math.atan(slopeSide1) * 180 / Math::PI;
    sign = currentAngle / currentAngle.abs
    angle =  currentAngle  - 90 * sign
  elsif slopeSide2 != 0
    currentAngle = Math.atan(slopeSide2) * 180 / Math::PI;
    angle = 0 - currentAngle;
  else
    return image;
  end

  center = CvPoint.new image.width/2, image.height/2
  image = image.warp_affine(CvMat.rotation_matrix2D(center, angle, 1))
  return image;
end

def getBinarySquareColor(num, rows, columns, countPixelsBlock,  bin)
  row = num.div rows
  col = num % columns
  sum = 0;
  countPixelsBlock.times{|i|
    countPixelsBlock.times{|j|
      # printf "#{bin.at(row*10 + i, col*10 + j).to_a.inject(0, :+).ceil/(255)} "
      sum += bin.at(row*countPixelsBlock + i, col*countPixelsBlock + j).to_a.inject(0, :+).ceil/(255)
    }
  }

  return (sum / 100.0).round

end
