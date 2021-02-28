package Twitch;

# Interact with the Twitch API in nice predictable ways.
# Copyright 2021 Michael Pirkola

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.


## Public subroutines
# Informative:
#   get_user_id($auth, $username) returns the numerical user ID from a provided
#     username.  Most other functions that target a user require an ID
#     rather than a username.
#   get_tags($auth, $id) returns an array of the tag IDs associated with a
#     given user ID.  Automatic tags, such as language, are not returned.
#   get_channel_info($auth, $id) returns a hash reference of the information
#     Twitch provides about a channel associated with a given user ID.
# Manipulative (requires a user OAuth token):
#   put_tags($auth, $id, @tags) takes a list of tag IDs and sets the stream
#     description on Twitch to use those tags.
#   put_channel_info($auth, $id, $hash) takes a hash reference containing stream
#     attributes and sets them on Twitch.
#
# Many of these functions share certain key arguments.
#   $auth is a hash reference that contains at a minimum a 'client_id' and
#     'client_secret' used for authenticating with Twitch, and a 'handle'
#     which is an object created by HTTP::Tiny with connection details.
#     An 'app_access_token' can be included if one already exists, but a
#     new one will be created by the functions if needed using the id and
#     secret.  If created, the token will be added to the auth hash, and
#     should be saved between sessions by the calling program.  To be able
#     to make requests on behalf of a user, a 'user_access_token' and
#     'user_refresh_token' should be included; these values will also be
#     updated in place as needed and should be saved.
#   $id is the numeric user ID of the user being acted upon.  It can be found
#     from the username with the function get_user_id.


use warnings;
use strict;

use v5.20;

use HTTP::Tiny;
use JSON::Parse 'parse_json';






##############
#            #
#  COMMANDS  #
#            #
##############



sub create_app_token  {
	my ($auth) = @_;
	my $res = $$auth{handle}->request( 'POST', 'https://id.twitch.tv/oauth2/token?'
	  . "client_id=$$auth{client_id}\&"
	  . "client_secret=$$auth{client_secret}\&"
	  . "grant_type=client_credentials"  );
	
	unless ($$res{success})  {
		warn 'Could not get app access token.  Full response:';
		warn "$_: $$res{$_}\n" foreach keys %$res;
		return;
		}
	
	# Get the token.
	($$auth{app_access_token}) = $$res{content} =~ /"access_token":"(.*?)"/;
	
	}


sub get_user_id  {
	my ( $auth, $username ) = @_;
	
	my $res = &twitch_app_request($auth, 'GET', "https://api.twitch.tv/helix/users?login=$username");
	
	return unless $$res{success};
	
	my ($id) = $$res{content} =~ /"id":"(\d+)"/;
	
	return $id;
	
	}


sub get_tags  {
	my ($auth, $id) = @_;
	my $res = &twitch_app_request($auth, 'GET', "https://api.twitch.tv/helix/streams/tags?broadcaster_id=$id");
	
	#print "$_: $$res{$_}\n" foreach keys %$res;
	
	unless ($$res{success})  {
		warn 'Tags request failed.';
		return;
		}
	
	my @tags = split /}},\{/, $$res{content};
	
	my @output;
	foreach (@tags)  {
		# Skip auto tags
		next if /"is_auto":true,/;
		s/.*"tag_id":"([0-9a-f\-]+)".*/$1/;
		push @output, $_;
		}
	
	
	return @output;
	}


sub put_tags  {
	my ($auth, $id, @tags) = @_;
	
	unless (@tags)  {
		warn "No tags given.";
		return;
		}
	
	# Build the content string.
	my $content = qq|{"tag_ids":[|;
	$content .= qq|"$_",| foreach @tags;
	# Remove trailing comma (guaranteed to be there).
	chop $content;
	$content .= ']}';
	
	my $res = &twitch_user_request(
	    $auth,
	    'PUT',
	    "https://api.twitch.tv/helix/streams/tags?broadcaster_id=$id",
	    {"Content-Type" => 'application/json'},
	    $content );
	
	
	}


sub get_channel_info  {
	my ($auth, $id) = @_;
	my $res = &twitch_app_request(
	    $auth,
	    'GET',
	    "https://api.twitch.tv/helix/channels?broadcaster_id=$id" );
	
	return unless $$res{success};
	
	my $info = $$res{content};
	$info =~ s/^\{"data":\[(\{.*\})\]\}$/$1/;
	
	my $hash = parse_json($info);
	
	
	return $hash;
	}


sub put_channel_info  {
	my ($auth, $id, $hash) = @_;
	
	# Build the content string.
	my $content = '{';
	foreach (keys %$hash)  {
		my ($key, $val) = ($_, $$hash{$_});
		
		# Properly escape the data (I hope).
		$val =~ s/\\/\\\\/g;
		$val =~ s/"/\\"/g;
		
		$content .= qq("$key":"$val",);
		}
	
	# Remove the last comma, if it exists.
	$content =~ s/,$//;
	$content .= '}';
	
	&twitch_user_request( 
	    $auth,
	    'PATCH',
	    "https://api.twitch.tv/helix/channels?broadcaster_id=$id",
	    '',
	    $content );
	
	
	
	}


sub twitch_app_request  {
	# This is the place to check if authentication works,
	# and to get or refresh tokens.
	
	my ($auth, $method, $url, $headers, $content) = @_;
	$headers = {} unless defined $headers;
	&create_app_token($auth) unless $$auth{app_access_token};
	
	$$headers{'Client-Id'} = $$auth{client_id};
	$$headers{'Authorization'} = "Bearer $$auth{app_access_token}";
	
	my $res = $$auth{handle}->request($method, $url,
	    {headers => $headers,
	     content => $content});
	#say "Full headers received from user info request:";
	#say " $_: $$res{headers}{$_}" foreach (keys %{$$res{headers}});
	
	
	if ($$res{status} eq '401')  {
		say "Refreshing token";
		&create_app_token($auth);
		$$headers{'Authorization'} = "Bearer $$auth{app_access_token}";
		$res = $$auth{handle}->request($method, $url,
		    {headers => $headers,
		     content => $content});
		}
	
	
	unless ($$res{success})  {
		my $msg;
		$msg .=  "  $_: $$res{$_}\n" foreach keys %$res;
		warn "Twitch request for $url failed.  Full response:\n$msg";
		}
	
	return $res;
	
	}


sub twitch_user_request  {
	# This is the place to check if authentication works,
	# and to get or refresh tokens.
	
	my ($auth, $method, $url, $headers, $content) = @_;
	$headers = {} unless defined $headers;
	
	# No process yet for creating a user token.
	#&create_app_token($auth) unless $$auth{app_access_token};
	
	# HTTP::Tiny cannot handle PATCH requests.
	my $res;
	if ($method eq 'PATCH')  {
		# "Escape" single quotes
		$content =~ s/'/'"'"'/g; #'# Fix syntax highlighting
		
		my $command = "curl --silent -X PATCH \"$url\" "
		    . "-H 'Client-Id: $$auth{client_id}' "
		    . "-H 'Authorization: Bearer $$auth{user_access_token}' "
		    . "-H 'Content-Type: application/json' "
		    . "--data-raw '$content'";
		say $command;
		$res = `$command`;
		if ($res =~ /Invalid OAuth/)  {
			&refresh_token($auth);
			$command = "curl --silent -X PATCH \"$url\" "
			    . "-H 'Client-Id: $$auth{client_id}' "
			    . "-H 'Authorization: Bearer $$auth{user_access_token}' "
			    . "-H 'Content-Type: application/json' "
			    . "--data-raw '$content'";
			$res = `$command`;
			}
		
		warn "Twitch request for $url failed.  Response: $res" if $res;
		
		}
	else  {
		
		
		$$headers{'Client-Id'} = $$auth{client_id};
		$$headers{'Authorization'} = "Bearer $$auth{user_access_token}";
		
		$res = $$auth{handle}->request($method, $url,
		    {headers => $headers,
		     content => $content});
		#say "Full response to user info request:";
		#say "$_: $$res{$_}" foreach (keys %$res);
		
		
		if ($$res{header}{'www-authenticate'} =~ /invalid_token/)  {
			&refresh_token($auth);
			$$headers{'Authorization'} = "Bearer $$auth{user_access_token}";
			$res = $$auth{handle}->request($method, $url,
			    {headers => $headers,
			     content => $content});
			}
		unless ($$res{success})  {
			warn "Twitch request for $url failed.  Full response:";
			warn "$_: $$res{$_}\n" foreach keys %$res;
			}
		}
	
	
	return $res;
	
	}


sub refresh_token  {
	my ($auth) = @_;
	
	print "Refreshing token...\n";
	my $res = `curl --silent -X POST "https://id.twitch.tv/oauth2/token" \\
	    --data-urlencode grant_type=refresh_token \\
	    --data-urlencode refresh_token=$$auth{user_refresh_token} \\
	    --data-urlencode client_id=$$auth{client_id} \\
	    --data-urlencode client_secret=$$auth{client_secret}`;
	my ($token, $ref_token) = $res =~ /"access_token":"(.*?)",.*"refresh_token":"(.*?)"/;
	
	# An empty return status means failure.
	unless ($token and $ref_token)  {
		warn 'Failed to refresh user access token.';
		return;
		}
	
	$$auth{user_access_token} = $token;
	$$auth{user_refresh_token} = $ref_token;
	
	
	return 1;
	}


1;
