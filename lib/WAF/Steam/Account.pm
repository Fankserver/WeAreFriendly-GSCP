package WAF::Steam::Account;
use strict;
use warnings;

sub new {
	my $class = shift;
	my $args = shift || {};

	my $self = { (), %{$args} };

	bless($self, $class);
	return $self;
}

sub getAccountsAutocomplete {
	my $self = shift;
	my $args = shift;
	my @accounts;

	if (
		(defined($args->{SteamId}) && $args->{SteamId} =~ /^(\d+)$/ && $1 > 0)
		|| (defined($args->{BattlEyeGUID}) && $args->{BattlEyeGUID} =~ /^(\w{32})$/)
		|| ($args->{PlayerName})
		|| ($args->{q})
	) {
		my @restrictions;
		if ($args->{SteamId} || $args->{BattlEyeGUID} || $args->{PlayerName}) {
			if ($args->{SteamId}) {
				push(@restrictions, "SteamAcc.i_steamid LIKE '%".$args->{SteamId}."%'");
			}
			if ($args->{BattlEyeGUID}) {
				push(@restrictions, "SteamAcc.s_battleyeguid = '".$args->{BattlEyeGUID}."'");
			}
			if ($args->{PlayerName}) {
				push(@restrictions, "Player.`name` LIKE '%".$args->{PlayerName}."%'");
			}
		}
		elsif ($args->{q}) {
			push(@restrictions, "SteamAcc.i_steamid LIKE '%".$args->{q}."%'");
			push(@restrictions, "SteamAcc.s_battleyeguid = '".$args->{q}."'");
			push(@restrictions, "Player.`name` LIKE '%".$args->{q}."%'");
		}

		if (scalar(@restrictions) > 0) {
			my $sth = $self->{MySQL}->prepare(q~
				SELECT
					SteamAcc.id															AS AccountId
					,SteamAcc.i_steamid													AS SteamId
					,SteamAcc.s_battleyeguid											AS BattlEyeGUID
					,Player.`name`														AS PlayerName
				FROM
					steam.account SteamAcc
					LEFT OUTER JOIN arma3life.players Player ON Player.playerid = SteamAcc.i_steamid
				WHERE
					~.join(' AND ',@restrictions).q~
			~);
			$sth->execute();
			while (my $row = $sth->fetchrow_hashref()) {
				push(@accounts, $row);
			}
			$sth->finish();
		}
	}

	return @accounts;
}

1;