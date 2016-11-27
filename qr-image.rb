#!/usr/bin/env ruby
require 'opencv'
include OpenCV
require './qr-functions.rb'

image = nil
imageName = "s2.png"
dataOutName = "data.txt"
begin
  image = CvMat.load(imageName, CV_LOAD_IMAGE_COLOR) # Read the file.
rescue
  puts 'Could not open or find the image.'
  exit
end
QR_STANDARD = 21;
circle_options = { :color => CvColor::Red, :line_type => :aa, :thickness => -1 }

image = rotateDiag(image);
# window0 = GUI::Window.new('Diag Rotate window') # Create a window for display.
# window0.show(image) # Show our image inside it.
# GUI::wait_key
image = rotateSide(image);
# window1 = GUI::Window.new('Side Rotate window') # Create a window for display.
# window1.show(image) # Show our image inside it.
# GUI::wait_key

gray  = image.BGR2GRAY
bin = gray.threshold(0x44, 0xFF, :binary)

markers = getMarkers(bin);
markers.sort!{|a,b|
  getMassCenter(a).x <=> getMassCenter(b).x
}
if getMassCenter(markers[0]).y < getMassCenter(markers[1]).y#<   - because coord inverse
  markers[0], markers[1] = markers[1], markers[0];
end

O, L, M = markers;

k, b = getLine(O.bounding_rect.bottom_left, O.bounding_rect.bottom_right);#lower bound

#co-ordinates for fourth marker
x = M.bounding_rect.bottom_right.x;
y = k * x + b;

forthMarker = CvPoint.new x, y;


width = (O.bounding_rect.bottom_left.x - forthMarker.x).abs;
height = (forthMarker.y - L.bounding_rect.top_right.y).abs;

rect = CvRect.new(L.bounding_rect.top_left.x, L.bounding_rect.top_left.y, width, height);

bin = image.sub_rect(rect);
bin = bin.resize(CvSize.new(QR_STANDARD,QR_STANDARD))

#Extract data from image to file
file = File.open(dataOutName, "w")
bin.height.times{|i|
  bin.width.times{|j|
    file.write "#{bin.at(i,j).to_a.inject(0, :+).ceil/(255*3)} "
  }
  file.write "\n"
}


window = GUI::Window.new('Display window')
window.show(bin)
GUI::wait_key
