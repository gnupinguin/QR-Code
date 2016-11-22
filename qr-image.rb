#!/usr/bin/env ruby
require 'opencv'
include OpenCV
require './qr-functions.rb'

image = nil
begin
  image = CvMat.load("s1.jpeg", CV_LOAD_IMAGE_COLOR) # Read the file.
rescue
  puts 'Could not open or find the image.'
  exit
end

QR_NORTH = 0;
QR_EAST = 1;
QR_SOUTH = 2;
QR_WEST = 3;

gray  = image.BGR2GRAY
bin = gray.threshold(0x44, 0xFF, :binary)
canny = gray.canny(50, 150)

contours = bin.find_contours(:mode => OpenCV::CV_RETR_TREE, :method => OpenCV::CV_CHAIN_APPROX_SIMPLE);
accuracy = 1

markers = [];
content = contours.v_next;

while content
  if depth(content) >= 1
    markers.push content;
  end
  content = content.h_next;
end
puts markers

massCenters = [];
moments = [];

markers.each { |e|
  moments << CvMoments.new(e, false);
  massCenters << CvPoint.new(moments[-1].m10 / moments[-1].m00, moments[-1].m01 / moments[-1].m00)
}

circle_options = { :color => CvColor::Red, :line_type => :aa, :thickness => -1 }
massCenters.each{|e|
  image.circle!(e, 3, circle_options);
}

A, B, C = 0, 1, 2;

AB = distance(massCenters[A], massCenters[B]);
BC = distance(massCenters[B], massCenters[C]);
CA = distance(massCenters[C], massCenters[A]);

outlier, median1, median2  = nil;

if  AB > BC && AB > CA
  outlier = C; median1=A; median2=B;
elsif ( CA > AB && CA > BC )
  outlier = B; median1=A; median2=C;
elsif ( BC > AB && BC > CA )
  outlier = A;  median1=B; median2=C;
end

top = outlier; # The obvious choice

dist = lineEquation(massCenters[median1], massCenters[median2], massCenters[outlier]);	# Get the Perpendicular distance of the outlier from the longest side
slope, align = lineSlope(massCenters[median1], massCenters[median2]); # Also calculate the slope of the longest side
#
# # Now that we have the orientation of the line formed median1 & median2 and we also have the position of the outlier w.r.t. the line
# # Determine the 'right' and 'bottom' markers
right, bottom, orientation = nil;
if align == 0
  bottom = median1;
  right = median2;
elsif slope < 0 && dist < 0
  bottom = median1;
  right = median2;
  orientation = QR_NORTH;
elsif slope > 0 && dist < 0
  right = median1;
  bottom = median2;
  orientation = QR_EAST;
elsif slope < 0 && dist > 0
  right = median1;
  bottom = median2;
  orientation = QR_SOUTH;
elsif slope > 0 && dist > 0
  bottom = median1;
  right = median2;
  orientation = QR_WEST;
end

# To ensure any unintended values do not sneak up when QR code is not present

window = GUI::Window.new('Display window') # Create a window for display.
# image = image.resize(CvSize.new 21, 21);
window.show(image) # Show our image inside it.
GUI::wait_key # Wait for a keystroke in the window.
