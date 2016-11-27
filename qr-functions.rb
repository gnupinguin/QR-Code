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
  content = contours.v_next;#NEED TO DO SMART SEARCH!!!!

  while content
    if depth(content) >= 1
      markers << content;
    end
    content = content.h_next;
  end
  # puts markers
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
  markers = getMarkers(bin);
  massCenters = getMassCenters(markers);

  median1, median2, outlier = getLocationMarkers(markers, massCenters)#median1 on the left then median2
  slopeDiag, perpDiag = lineSlope(massCenters[median1], massCenters[median2]);

  if perpDiag == 1
    angle = (massCenters[outlier].x < massCenters[median1].x)? -45 : 90;
    center = CvPoint.new image.width/2, image.height/2
    image = image.warp_affine(CvMat.rotation_matrix2D(center, angle, 1))

  elsif slopeDiag != -1 # why -1?
    currentAngle = Math.atan(slopeDiag) * 180 / Math::PI;
    angle = 45 - currentAngle;
    center = CvPoint.new image.width/2, image.height/2
    image = image.warp_affine(CvMat.rotation_matrix2D(center, angle, 1))
  end
  return image;
end

def rotateSide(image)
  gray  = image.BGR2GRAY
  bin = gray.threshold(0x44, 0xFF, :binary)
  markers = getMarkers(bin);
  massCenters = getMassCenters(markers);
  median1, median2, outlier = getLocationMarkers(markers, massCenters)

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
