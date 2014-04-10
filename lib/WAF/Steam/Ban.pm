package WAF::Steam::Ban;
use strict;
use warnings;

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
			(defined($args->{Permanent}) && $args->{Permanent})
			|| (defined($args->{Expire}) && $args->{Expire} =~ s/^(\d{2})\.(\d{2})\.(\d{4})$/$3-$2-$1/)
		)
		&& (defined($args->{Reason}) && $args->{Reason})
		&& (defined($args->{OperatorId}) && $args->{OperatorId})
	) {
		my $sth = $self->{MySQL}->prepare(q~
			INSERT INTO steam.ban (
				i_account_id
				,i_type_id
				,b_permanent
				,s_reason
				,dt_expire
				,i_inserted_id
				,dt_inserted
			)
			VALUES (
				?
				,?
				,~.(defined($args->{Permanent}) && $args->{Permanent} ? 1 : 0).q~
				,?
				,~.(defined($args->{Permanent}) && $args->{Permanent} ? 'NULL' : "'".$args->{Expire}."'").q~
				,(SELECT id FROM steam.account WHERE i_steamid = ? LIMIT 1)
				,NOW()
			);
		~);
		$sth->execute(
			$args->{AccountId}
			,$args->{BanTypeId}
			,$args->{Reason}
			,$args->{OperatorId}
		);
		$sth->finish();
		$return->{success} = 1;
	}

	return $return;
}

sub deleteBan {
	my $self = shift;
	my $args = shift;
	my $return = {success => 0};

	if (
		(defined($args->{BanId}) && $args->{BanId} =~ /^(\d+)$/ && $1 > 0)
		&& (defined($args->{OperatorId}) && $args->{OperatorId})
	) {
		my $sth = $self->{MySQL}->prepare(q~
			UPDATE
				steam.ban
			SET
				i_deleted_id = (SELECT id FROM steam.account WHERE i_steamid = ? LIMIT 1)
				,dt_deleted = NOW()
			WHERE
				id = ?
		~);
		$sth->execute(
			$args->{OperatorId}
			,$args->{BanId}
		);
		$sth->finish();
		$return->{success} = 1;
	}

	return $return;
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
			,Player.`name`														AS PlayerName
			,PlayerOperator.`name`												As OperatorName
		FROM
			steam.ban SteamBan
			LEFT OUTER JOIN steam.banType SteamBanType ON SteamBanType.id = SteamBan.i_type_id
			LEFT OUTER JOIN steam.account SteamAcc ON SteamAcc.id = SteamBan.i_account_id
			LEFT OUTER JOIN arma3life.players Player ON Player.playerid = SteamAcc.i_steamid
			LEFT OUTER JOIN steam.account SteamAccOperator ON SteamAccOperator.id = SteamBan.i_inserted_id
			LEFT OUTER JOIN arma3life.players PlayerOperator ON PlayerOperator.playerid = SteamAccOperator.i_steamid
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