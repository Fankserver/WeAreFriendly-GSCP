package WAF::Apache2::DBI::Connect;
use strict;
use warnings;

use Apache2::Const -compile => qw(DECLINED);
use WAF::DBI::MySQL;

sub handler {
	my $r = shift;

	my $MySQL = new WAF::DBI::MySQL();
	$MySQL->connect();

	$r->pnotes(DBI => {
		MySQL			=> $MySQL->dbh()
		,MySQL_noutf8	=> $MySQL->dbh_noutf8()
	});

	return Apache2::Const::DECLINED;
}

1;