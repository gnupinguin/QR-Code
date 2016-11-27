#!/usr/bin/env ruby
require 'opencv'
include OpenCV
require './qr-functions.rb'

image = nil
dataOutName = "data.txt"
begin
  image = CvMat.load(ARGV[0], CV_LOAD_IMAGE_COLOR) # Read the file.
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
image.save('3_step.jpg');
image = rotateSide(image);
# window1 = GUI::Window.new('Side Rotate window') # Create a window for display.
# window1.show(image) # Show our image inside it.
# GUI::wait_key
image.save('4_step.jpg');

gray  = image.BGR2GRAY
bin = gray.threshold(127, 255, :binary)
canny = gray.canny(50, 150)

markers = getMarkers(canny);
markers.sort!{|a,b|
  getMassCenter(a).x <=> getMassCenter(b).x
}
if getMassCenter(markers[0]).y < getMassCenter(markers[1]).y#<   - because coord inverse
  markers[0], markers[1] = markers[1], markers[0];
end

O, L, M = markers;

# image.circle!(O.min_area_rect2.points[1], 3, circle_options);
window1 = GUI::Window.new('Side Rotate window') # Create a window for display.
window1.show(image) # Show our image inside it.
GUI::wait_key

k, b = getLine(O.bounding_rect.bottom_left, O.bounding_rect.bottom_right);#lower bound

#co-ordinates for fourth marker
x = M.bounding_rect.bottom_right.x;
y = k * x + b;

forthMarker = CvPoint.new x, y;


puts width = (O.bounding_rect.bottom_left.x - forthMarker.x).abs;
puts height = (forthMarker.y - L.bounding_rect.top_right.y).abs;

rect = CvRect.new(L.bounding_rect.top_left.x, L.bounding_rect.top_left.y, width, height);
bin = bin.sub_rect(rect);
# window = GUI::Window.new('Cut Binary Image');
# window.show(bin)
# GUI::wait_key

bin = bin.resize(CvSize.new(21,21))
bin = bin.threshold(127, 255, :binary)

bin.save('out.jpg');
#Extract data from image to file
# file = File.open(dataOutName, "w")

# 21.size.times{|i|
#   21.size.times{|j|
#     # file.write "#{getBinarySquareColor(i*21 + j, bin)} "
#     puts i*21 + j
#
#   }
#   file.write "\n"
# }
# (21**2).times{|i|
#   file.write "#{getBinarySquareColor(i, 21, 21, 10, bin)} "
#   if i % 21 == 0 && i != 0
#     file.write "\n"
#   end
# }

#Extract data from image to file
file = File.open(dataOutName, "w")
bin.height.times{|i|
  bin.width.times{|j|
    file.write "#{bin.at(i,j).to_a.inject(0, :+).ceil/(255)}"
  }
  file.write "\n"
}

# getBinarySquareColor(21**2 - 2, 21, 21, 10, bin)


window = GUI::Window.new('Display window')
window.show(bin)
GUI::wait_key
