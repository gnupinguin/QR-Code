#!/usr/bin/env ruby
require 'opencv'
include OpenCV
require 'qr-functions.rb'

image = nil
begin
  image = CvMat.load("sample.jpg", CV_LOAD_IMAGE_COLOR) # Read the file.
rescue
  puts 'Could not open or find the image.'
  exit
end

gray  = image.BGR2GRAY
bin = gray.threshold(0x44, 0xFF, :binary)
canny = gray.canny(50, 150)

contours = bin.find_contours(:mode => OpenCV::CV_RETR_TREE, :method => OpenCV::CV_CHAIN_APPROX_SIMPLE);
accuracy = 1

markers = [];
content = contours.v_next;

while content
  if depth(content) > 1
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

circle_options = { :color => CvColor::Blue, :line_type => :aa, :thickness => -1 }
massCenters.each{|e|
  image.circle!(e, 3, circle_options);
}

A, B, C = 0, 1, 2;

AB = distance(massCenters[A], massCenters[B]);
AC = distance(massCenters[A], massCenters[C]);
BC = distance(massCenters[B], massCenters[C]);



window = GUI::Window.new('Display window') # Create a window for display.

markers.each{ |e|
  poly = e.approx(:accuracy => accuracy)
  image.draw_contours!(poly, CvColor::Red, CvColor::Blue, 2, :thickness => 2, :line_type => :aa);
}

window.show(image) # Show our image inside it.
GUI::wait_key # Wait for a keystroke in the window.
