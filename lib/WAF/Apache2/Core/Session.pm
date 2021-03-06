package WAF::Apache2::Core::Session;
use strict;
use warnings;
use Data::Dumper;

use Apache2::Const -compile => qw(DECLINED);
use Apache2::Request;
use Apache2::RequestUtil;
use Apache2::Connection;
use Apache2::Cookie;
use Session;

sub handler {
	my $r = shift;
	my $remoteIp = $r->connection->remote_ip();

	# non local only
	if ($remoteIp !~ /^127\.|^::1/) {
		my $CookieJar = Apache2::Cookie::Jar->new($r);
		my $sessionCookieName = "_session";
		my $sessionCookieFetched = $CookieJar->cookies($sessionCookieName);
		my $sessionId = undef;
		if ($sessionCookieFetched) {
			$sessionId = $sessionCookieFetched->value();
		}

		my %session_config = (
			Store		=> 'MySQL',
			Lock		=> 'Null',
			Generate	=> 'MD5',
			Serialize	=> 'Storable',
			# MySQL backend option
			Handle		=> $r->pnotes('DBI')->{MySQL_noutf8},
			LockHandle	=> $r->pnotes('DBI')->{MySQL_noutf8},
			TableName	=> 'gscp.session'
		);

		# make a fresh session for a first-time visitor
		my $Session = new Session $sessionId, %session_config;
		$Session = new Session undef, %session_config unless $Session;

		if ($Session->get('sessiontime') && $Session->get('sessiontime') < (time - (60*60*12))) {
			$Session->delete();
			$Session = new Session undef, %session_config;
		}

		if (!$Session->get('initializedSession')) {
			$Session->set('initializedSession', 1);
			$Session->set('SteamId', 0);

			my $sessionCookie = Apache2::Cookie->new($r,
				name		=> $sessionCookieName,
				value		=> $Session->session_id(),
				path		=> '/',
				expires		=> '+10Y',
				domain		=> 'gscp.waf.fankservercdn.com'
			);
			$sessionCookie->bake($r);
		}

		$r->pnotes(session => $Session);
	}

	return Apache2::Const::DECLINED;
}

1;