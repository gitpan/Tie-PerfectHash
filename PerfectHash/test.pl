# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
use Test;
BEGIN { plan tests => 6 }

END {print "not ok 1\n" unless $loaded;}
use Tie::PerfectHash;

$loaded = 1;

######################### End of black magic.
# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

@k = qw(foo bar baaz bug);

# ----------------------------------------------------------------------
# OO TEST
# ----------------------------------------------------------------------

$ph = Tie::PerfectHash->new({    KEYSET         => \@k, 
				 MAX_KEYLEN     => 16,
				 MAX_CHARWEIGHT => 64,
				 MAPSIZE        => 23,
			     });

$ph->store('foo', 3);
ok($ph->fetch('foo'), 3);

ok('0123', join q//,map{$ph->getidx($_)}$ph->getkeys());
undef $ph;



# ----------------------------------------------------------------------
# TIE TEST
# ----------------------------------------------------------------------

tie %PH, 'Tie::PerfectHash',{    KEYSET         => \@k, 
				 MAX_KEYLEN     => 16,
				 MAX_CHARWEIGHT => 64,
				 MAPSIZE        => 23,
			     };

$PH{heaven} = 'sign';
ok($PH{heaven}, 'sign');

ok(exists $PH{lake}, 1);

%PH = ();

ok(scalar(%PH), 0);

untie %PH;
