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
			INSERT INTO steam.ban (
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

sub removeBan {
	
}

sub getBans {
	my $self = shift;
	my $args = shift;
	my @bans;
	
	my $sth = $self->{MySQL}->prepare(q~
		SELECT
			SteamBan.id															AS BanId
			,SteamBan.dt_expire													AS BanExpire
			,(CASE WHEN SteamBan.b_permanent = 1 THEN 1 ELSE 0 END)				AS BanPermanent
			,SteamBanType.s_name												AS BanTypeName
			,SteamBanType.s_description											AS BanTypeDescription
			,SteamBan.s_reason													AS BanReason
			,SteamAcc.id														AS AccountId
			,SteamAcc.i_steamid													AS SteamId
			,SteamAcc.s_battleyeguid											AS BattlEyeGUID
			-- ,Player.`name`													AS PlayerName
		FROM
			steam.ban SteamBan
			LEFT OUTER JOIN steam.banType SteamBanType ON SteamBanType.id = SteamBan.i_type_id
			LEFT OUTER JOIN steam.account SteamAcc ON SteamAcc.id = SteamBan.i_account_id
			-- LEFT OUTER JOIN arma3life.players Player ON Player.playerid = SteamAcc.i_steamid
		WHERE
			SteamBan.dt_deleted IS NULL
			AND (
				(SteamBan.b_permanent = 0 AND SteamBan.dt_expire > NOW())
				OR SteamBan.b_permanent = 1
			)
	~);
	$sth->execute();
	while (my $row = $sth->fetchrow_hashref()) {
		$row->{BanExpire} =~ s/(\d{4})-(\d{2})-(\d{2}) (.*)/$3.$2.$1 $4/;
		push(@bans, $row);
	}
	$sth->finish();
	
	return @bans;
}

1;