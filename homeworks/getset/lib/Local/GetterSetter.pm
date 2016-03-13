package Local::GetterSetter;

sub import {
	$namePack = (caller(0))[0];
	@vars = @_[1..@_];
	foreach my $i (@vars) {
		my $val = 0;
		*{"$namePack"."::"."$i"} = \$val;
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
