package WAF::Apache2::DBI::Disconnect;
use strict;
use warnings;

use Apache2::Const -compile => qw(OK);

sub handler {
	my $r = shift;
	my $DBI = $r->pnotes('DBI');
	
	foreach (keys %{$DBI}) {
		if ($DBI->{$_}) {
			$DBI->{$_}->disconnect();
		}
	}
	
	return Apache2::Const::OK;
}

1;