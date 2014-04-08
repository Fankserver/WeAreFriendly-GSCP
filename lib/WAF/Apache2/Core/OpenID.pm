package WAF::Apache2::Core::OpenID;
use strict;
use warnings;

use Apache2::Const -compile => qw(DECLINED REDIRECT OK);
use Apache2::Request;
use Apache2::RequestRec;
use APR::Table;
use Cache::File;
use LWP::UserAgent;

sub handler {
	my $r = shift;

	my $OpenID = new Net::OpenID::Consumer(
		ua					=> LWP::UserAgent->new()
		,cache				=> Cache::File->new(cache_root => '/tmp/openid')
		,required_root		=> 'http://gscp.waf.fankservercdn.com/'
		,consumer_secret	=> 'ASDASDADSASADSADSAD'
		#,assoc_options		=> [
		#	max_encrypt					=> 1
		#	,session_no_encrypt_https	=> 1
		#]
		,args				=> Apache2::Request->new($r)
	);

	if ($r->uri() =~ m~/steam/login~) {
		my $claimed_identity = $OpenID->claimed_identity('http://steamcommunity.com/openid');
		unless ($claimed_identity) {
			die "not actually an openid? ".$OpenID->err;
		}

		my $check_url = $claimed_identity->check_url(
			return_to		=> "http://gscp.waf.fankservercdn.com/steam/verify",
			trust_root		=> "http://gscp.waf.fankservercdn.com/",
			delayed_return	=> 1
		);

		$r->headers_out->set(Location => $check_url);

		return Apache2::Const::REDIRECT;
	}
	elsif ($r->uri() =~ m~/steam/verify~) {
		$OpenID->handle_server_response(
			not_openid => sub {
				die "Not an OpenID message";
			},
			setup_needed => sub {
				if ($OpenID->message->protocol_version >= 2) {
					# (OpenID 2) retry request in checkid_setup mode (above)
				}
				else {
					# (OpenID 1) redirect user to $OpenID->user_setup_url
				}
			},
			cancelled => sub {
				# User hit cancel; restore application state prior to check_url
			},
			verified => sub {
				my ($vident) = @_;
				my $verified_url = $vident->url;
				print STDERR "You are $verified_url !";

				if ($verified_url =~ m~http://steamcommunity\.com/openid/id/(\d+)~) {
					$r->pnotes('session')->set('SteamId', $1);
					$r->headers_out->set(Location => 'http://gscp.waf.fankservercdn.com/');
					return Apache2::Const::REDIRECT;
				}
			},
			error => sub {
				my ($errcode,$errtext) = @_;
				die("Error validating identity: $errcode: $errcode");
			},
		);

		return Apache2::Const::OK;
	}

	#$r->pnotes(OpenID => $OpenID);
	return Apache2::Const::DECLINED;
}

1;