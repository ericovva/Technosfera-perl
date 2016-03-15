package GetterSetter;
use strict;
no strict 'refs';
sub import {
	my ($namePack) = caller();
	my ($class, @vars) = @_;
	foreach my $i (@vars) {
		*{"$namePack"."::"."set_"."$i"} = 
		sub { 
			my $newVal = shift();
			*{"$namePack"."::"."$i"} = \$newVal;
		};
		*{"$namePack"."::"."get_"."$i"} = 
		sub {
			return ${"$namePack"."::"."$i"}."\n";
		}
	}
}
1;
