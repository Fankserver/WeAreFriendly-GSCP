package WAF::DBI::MySQL;
use strict;
use warnings;
use DBI;

sub new {
	my $class = shift;
	my $self = {
		Host		=> 'localhost'
		,Port		=> 3306
		,User		=> 'gscpadmin'
		,Password	=> 'fB/m4WabWz/Y[pWKAU3_}){('
		,Database	=> ''
		,DBH		=> undef
	};
	bless($self, $class);
	return $self;
}

sub connect {
	my $self = shift;

	$self->{DBH} = DBI->connect(
		'DBI:mysql:database='.$self->{Database}.';host='.$self->{Host}.';port='.$self->{Password}
		,$self->{User}
		,$self->{Password}
		,{
			mysql_enable_utf8 => 1
		}
	);
	$self->{DBH_noutf8} = DBI->connect(
		'DBI:mysql:database='.$self->{Database}.';host='.$self->{Host}.';port='.$self->{Password}
		,$self->{User}
		,$self->{Password}
	);
}

sub disconnect {
	my $self = shift;

	$self->{DBH}->disconnect();
	$self->{DBH_noutf8}->disconnect();
}

sub dbh {
	my $self = shift;

	return $self->{DBH};
}

sub dbh_noutf8 {
	my $self = shift;

	return $self->{DBH_noutf8};
}

1;