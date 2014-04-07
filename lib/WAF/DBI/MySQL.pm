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
	);
}

sub disconnect {
	my $self = shift;
	
	$self->{DBH}->disconnect();
}

sub dbh {
	my $self = shift;
	
	return $self->{DBH};
}

1;