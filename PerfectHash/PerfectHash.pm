package Tie::PerfectHash;

require 5.005_62;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our $VERSION = '0.01';

bootstrap Tie::PerfectHash $VERSION;

sub genw($){
    my($pkg) = shift;
    @{$pkg->{WEIGHTS}->[$_]} =
	map{ int rand($pkg->{MAX_CHARWEIGHT}) } 0..$pkg->{MAX_KEYLEN}-1 for 0..1 
}

sub hval($$){
    my ($pkg) = shift;
    my (@p)   = split //,shift;
    my ($l)   = @p-1;
    my (@v);

    for my$c(0..$l){$v[$_] += ord($p[$c])*$pkg->{WEIGHTS}->[$_]->[$c] for 0..1}
    map{$_%$pkg->{MAPSIZE}}@v;
}

sub genmap($){
    my($pkg) = shift;
  ISVALID:
    while(1){
	my @g = ();
	my $c = 0;
	$pkg->genw();

	print "==>\nh1  h2  h  key\n" if $pkg->{DEBUG};
	for(map { [ $pkg->hval($_), $_ ] } @{$pkg->{KEYSET}}){
	    print STDERR "$_->[0]  $_->[1]  $c  $_->[2]\n" if $pkg->{DEBUG};
	    next ISVALID if $_->[0] == $_->[1];
	    if(!defined $g[$_->[0]] && !defined $g[$_->[1]]){
		($g[$_->[0]], $g[$_->[1]]) = (0, $c++);
		next;
	    }
	    if(!defined $g[$_->[0]]){
		next ISVALID unless($g[$_->[0]] = $c - $g[$_->[1]]);
		$g[$_->[0]] = ($c - $g[$_->[1]]);
	    }    
	    elsif(!defined $g[$_->[1]]){
		next ISVALID unless($g[$_->[1]] = $c - $g[$_->[0]]);
		$g[$_->[1]] = ($c - $g[$_->[0]]);
	    }    
	    $c++;
	}
	$pkg->{PERFMAP} = \@g;
	last;
    }
}
sub new($$){ TIEHASH(@_) };

sub getkeys($)  { @{shift()->{KEYSET}}  }

sub getvalues($){ @{shift()->{VALUESET}}}

# ----------------------------------------------------------------------
# getidx($self, $key)
# ----------------------------------------------------------------------
sub getidx($$){
    my ($pkg) = shift;
    my ($k)   = shift;
    my (@p)   = split //,$k;
    my ($l)   = @p-1;
    my ($v)   = undef;
    my (@v);
    for my $c(0..$l){
	$v[$_] += ord($p[$c])*$pkg->{WEIGHTS}->[$_]->[$c] for 0..1;
    }
    $v+=$_?$_:0 for(map{ $pkg->{PERFMAP}->[ $_%$pkg->{MAPSIZE} ] }@v);
    $v%=$pkg->{KEYSETSIZE};
}

# ----------------------------------------------------------------------
# fetch($self, $key)
# ----------------------------------------------------------------------
sub fetch($$) { my $pkg=shift; $pkg->{VALUESET}->[$pkg->getidx(shift)] }

# ----------------------------------------------------------------------
# store($self, $key, $value)
# ----------------------------------------------------------------------
sub store($$$){ my $pkg=shift; $pkg->{VALUESET}->[$pkg->getidx(pop)] = pop }

# ----------------------------------------------------------------------
# $Perf = tie %PH, 'Tie::PerfectHash',{ KEYSET => \@k, ... };
# ----------------------------------------------------------------------
sub TIEHASH($$){
    my($pkg) = shift;
    my($arg) = shift;

    my($obj) = {
	MAX_KEYLEN     => $arg->{MAX_KEYLEN} || 128,
	MAX_CHARWEIGHT => $arg->{MAX_CHARWEIGHT}       || 64,
	WEIGHTS        => undef,
	PERFMAP        => undef,
	VALUESET       => undef,
	DEBUG          => $arg->{DEBUG},
    };
    my %DUP;
    @DUP{ @{$arg->{KEYSET}} } = ();
    @{$obj->{KEYSET}}  = keys %DUP;
    $obj->{KEYSETSIZE} = scalar @{$obj->{KEYSET}};
    $obj->{MAPSIZE}     = 
	$arg->{MAPSIZE} && $arg->{MAPSIZE} > $obj->{KEYSETSIZE} ? 
	    $arg->{MAPSIZE} : $obj->{KEYSETSIZE}*1.9;
    bless $obj, $pkg;
    $obj->genmap;
$obj
}

sub FETCH { my($pkg) = shift; $pkg->{VALUESET}->[$pkg->getidx(shift)]          }

sub STORE { my($pkg) = shift; $pkg->{VALUESET}->[$pkg->getidx($_[0])] = $_[1]  }

sub DELETE{ my($pkg) = shift; $pkg->{VALUESET}->[$pkg->getidx($_[0])] = undef  }

sub EXISTS{ my($pkg) = shift; return 1 if defined $pkg->getidx($_[0])          }

sub CLEAR { my($pkg) = shift; @{$pkg->{$_}}=() for qw/VALUESET KEYSET PERFMAP/ }

sub FIRSTKEY{
    my($pkg) = shift;
    for( @{$pkg->{KEYSET}}){
	$pkg->{PREFHASH}->{$_}=	$pkg->{VALUESET}->[$pkg->getidx($_)];
    }
    each %{$pkg->{PREFHASH}};
}
sub NEXTKEY{ my($pkg) = shift; each %{$pkg->{PREFHASH}} }


1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Tie::PerfectHash - Minimal Perfect Hash

=head1 SYNOPSIS

  use Tie::PerfectHash;

  == OO Interface ==

    @k = qw/heaven earth wind lake thunder mountain fire water/;

    $ph = Tie::PerfectHash->new({ KEYSET => \@k,
			    MAX_KEYLEN => 16,
			    MAPSIZE => 23});
    $ph->store('heaven', 'sign');
    $ph->fetch('earth');


  == Tie Interface ==

    tie %PH, 'Tie::PerfectHash',{ KEYSET => \@k,
      			    MAX_KEYLEN => 16,
			    MAPSIZE => 23
			  };
    $PH{heaven} = 'sign';
    print $PH{earth};

=head1 DESCRIPTION

    * Tie::PerfectHash implements "Minimal Perfect Hashing Algorithm".

    * It improves hash performance under some conditions.
      E.g. Accessing a full-text search dictionary

    * OO and tie interface are available

    * Options for initialization

        KEYSET         := Reference to an array of keys

        MAX_KEYLEN     := Maximal length of keys. Default is 128

        MAPSIZE        := Mapping table size for creating minimal
                          perfect hash
                          Default is 1.9 times the size of KEYSET

        MAX_CHARWEIGHT := Maximal weight of a character in a key.
                          It is for generating random hash function.
                          Default is 64.

    * Usage and Public Methods

      == OO Interface ==

       @k = qw/heaven earth wind lake thunder mountain fire water/;

       # Tie::PerfectHash allocates space for the keyset,
       # and make it perfect.

       $ph = Tie::PerfectHash->new({	   KEYSET         => \@k, 
					   MAX_KEYLEN     => 16,
					   MAX_CHARWEIGHT => 64,
					   MAPSIZE        => 23,
				       });

       $ph->store('heaven', 'sign');  # assign value to a key

       print $ph->fetch('earth');     # get a key's value

       print $ph->getkeys();          # returns an array of keyset, 
                                      # without duplications

       print $ph->getidx('wind');     # get a key's internal serial


      == Tie Interface ==

       tie %PH, 'Tie::PerfectHash',{
	         KEYSET         => \@k, 
		 MAX_KEYLEN     => 16,
 		 MAX_CHARWEIGHT => 64,
		 MAPSIZE        => 23,
		 };

        # then you can treat it like an ordinary hash,
          except its limited vocabulary

        $PH{heaven} = 'sign';

        print $PH{earth};

	print "$_ => $PH{$_}\n" for keys %PH;

        %PH = ();

        untie %PH;


=head1 AUTHOR

    xern <xern@cpan.org>

=head1 REFERENCE

    Ian H. Witten, Alistair Moffat, Timothy C. Bell.
     Managing Gigabytes 2nd. ed. : Morgan Kaufman

=head1 COPYRIGHT

    Copyright 2002 by xern <xern@cpan.org>

    This program is free software; you can redistribute it
    and/or modify it under the same terms as Perl itself.


=cut


