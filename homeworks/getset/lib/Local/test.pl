package mypac;
use GetterSetter qw(x y z name_of_var);
set_x(50);
our $y = 42;
print get_y(); # 42
set_y(11);
print get_y(); # 11
set_z(4);
print get_z();
our $name_of_var = 5;
print get_name_of_var();
