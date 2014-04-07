package WAF::Steam::Ban;
use strict;
use warnings;
use DBI;

sub new {
	my $class = shift;
	my $args = shift || {};
	
	my $self = { (), %{$args} };
	
	bless($self, $class);
	return $self;
}

sub addBan {
	my $self = shift;
	my $args = shift;
	my $return = {success => 0};
	
	if (
		(defined($args->{AccountId}) && $args->{AccountId} =~ /^(\d+)$/ && $1 > 0)
		&& (defined($args->{BanTypeId}) && $args->{BanTypeId} =~ /^(\d+)$/ && $1 > 0)
		&& (
			(defined($args->{Expire}) && $args->{Expire} =~ s/^(\d{2})\.(\d{2})\.(\d{4})$/$3-$2-$1/)
			|| (defined($args->{Permanent}) && $args->{Permanent} =~ /^1$/)
		)
		&& (defined($args->{Reason}) && $args->{Reason})
	) {
		my $sth = $self->{MySQL}->prepare(q~
			INSERT INTO steam.bans (
				i_account_id
				,i_type_id
				,dt_inserted
				,dt_expire
				,b_permanent
				,s_reason
			)
			VALUES (
				?
				,?
				,NOW()
				,?
				,~.($args->{Permanent} =~ /1/ ? 1 : 0).q~
				,?
			);
		~);
		$sth->execute(
			$args->{AccountId}
			,$args->{BanTypeId}
			,$args->{Expire}
			,$args->{Reason}
		);
		$sth->finish();
		$return->{success} = 1;
	}
	else {
		
	}
	
	return $return;
}

1;