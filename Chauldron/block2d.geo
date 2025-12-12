rescent=50.0;
rescorner=1000.0;
xmin=-4000.0;
xmax=40000.0;
ymin=-8000.0;
ymax=8000.0;
xoffset = 500000;
yoffset = 500000;
Point(1) = {xmin + xoffset, 0+ yoffset, 0, rescent};
Point(2) = {xmax + xoffset, 0+ yoffset, 0, rescent};
Point(3) = {xmin + xoffset, ymin + yoffset, 0, rescorner};
Point(4) = {xmin + xoffset, ymax+ yoffset, 0, rescorner};
Point(5) = {xmax + xoffset, ymin+ yoffset, 0, rescorner};
Point(6) = {xmax + xoffset, ymax+ yoffset, 0, rescorner};
//+
Line(1) = {1, 2};
//+
Line(2) = {4, 1};
//+
Line(3) = {3, 1};

//+
Line(4) = {6, 2};
//+
Line(5) = {5, 2};
//+
Line(6) = {4, 6};
//+
Line(7) = {3, 5};
//+
Curve Loop(1) = {3, 1, -5, -7};
//+
Plane Surface(1) = {1};
//+
Curve Loop(2) = {2, 1, -4, -6};
//+
Plane Surface(2) = {2};


//+
Physical Surface(8) = {1, 2};
//+
Physical Curve(9) = {3, 2};
//+
Physical Curve(10) = {6};
//+
Physical Curve(11) = {4, 5};
//+
Physical Curve(12) = {7};
