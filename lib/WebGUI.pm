package WebGUI;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2007 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com			info@plainblack.com
#-------------------------------------------------------------------

use strict qw(vars subs);
use Tie::CPHash;
use Time::HiRes;
use WebGUI::Affiliate;
use WebGUI::Asset;
use WebGUI::Cache;
use WebGUI::Config;
use WebGUI::HTMLForm;
use WebGUI::International;
use WebGUI::Operation;
use WebGUI::Session;
use WebGUI::User;
use WebGUI::Utility;
use WebGUI::PassiveProfiling;
use Apache2::Upload;
use Apache2::Request;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(OK DECLINED NOT_FOUND DIR_MAGIC_TYPE);
use Apache2::ServerUtil ();
use LWP::MediaTypes qw(guess_media_type);

our $VERSION = "7.4.0";
our $STATUS = "beta";

#-------------------------------------------------------------------

=head2 handler ( requestObject )

Primary http init/response handler for WebGUI.  This method decides whether to hand off the request to contentHandler() or uploadsHandler()

=head3 requestObject

The Apache2::RequestRec object passed in by Apache's mod_perl.

=cut

sub handler {
	## Note: To Apache, the return values of OK, DECLINED, and DONE are all 'success' values.  Anything else is an error.  OK and DECLINED are pretty much the same thing as far as Apache is concerned.  Why use one or the other?  To make the code somewhat self-documenting.  In this case, DECLINED means 'We aren't going to do anything more with this'
	## OK means 'we handled it'

	my $r = shift;	#start with apache request object
	my $configFile = shift || $r->dir_config('WebguiConfig'); #either we got a config file, or we'll build it from the request object's settings
	my $s = Apache2::ServerUtil->server;	#instantiate the server api
	my $config = WebGUI::Config->new($s->dir_config('WebguiRoot'), $configFile); #instantiate the config object
	$r->push_handlers(PerlFixupHandler => \&fixupHandler) if (defined $config->get("passthruUrls")); #set up the fixup handler if we have passthruUrls
	foreach my $url ($config->get("extrasURL"), @{$config->get("passthruUrls")}) {	#get list of unhandled urls, return DECLINED if our url is on that list
		return Apache2::Const::DECLINED if ($r->uri =~ m/^$url/);
	}
	my $uploads = $config->get("uploadsURL");	#get uploads directory
	$uploads .= "/" unless ($uploads =~ m{/$});	#ad the trailing slash if it's not already present
	if ($r->uri =~ m!^$uploads/dictionaries!) {	# if the requested url is a personal dictionary, return not found
		# Do not allow web-access to personal dictionaries.
		$r->push_handlers(PerlAccessHandler => sub { return 401 } );
	} elsif($r->uri =~ m/^$uploads/) {									#if the request has uploads in it, return the appropriate handler
		$r->push_handlers(PerlAccessHandler => sub { return uploadsHandler($r, $configFile); } );
	} else {												#else go to content handler, and set the status to Ok
		$r->push_handlers(PerlResponseHandler => sub { return contentHandler($r, $configFile); } );
		$r->push_handlers(PerlTransHandler => sub { return Apache2::Const::OK });
	}
	return Apache2::Const::DECLINED; #decline further processing (keep in mind that OK and DECLINED are both success.  The difference is mostly for internal documentation.  As far as apache in concerned, the two are identical.
}


#-------------------------------------------------------------------	

=head2 contentHandler ( requestObject )

Creates the WebGUI session, handles exceptional request 
headers, handles special states, prints the response headers,
and (usually) prints the output of page().

=head3 requestObject

The Apache2::RequestRec object passed in by Apache's mod_perl.

=cut

sub contentHandler {
	### inherit Apache request.
	my $r = shift;
	my $configFile = shift || $r->dir_config('WebguiConfig');
	### instantiate the API for this httpd instance.
	my $s = Apache2::ServerUtil->server;
	### Open new or existing user session based on user-agent's cookie.
	my $request = Apache2::Request->new($r);
	my $session = WebGUI::Session->open($s->dir_config('WebguiRoot'),$configFile, $request, $s);
	my ($env, $http, $setting, $output, $errorHandler, $config) = $session->quick(qw(env http setting output errorHandler config));
	if ($session->env->get("HTTP_X_MOZ") eq "prefetch") { # browser prefetch is a bad thing
		$http->setStatus("403","We don't allow prefetch, because it increases bandwidth, hurts stats, and can break web sites.");
		$http->sendHeader;
	} elsif ($setting->get("specialState") eq "upgrading") {
		upgrading($session);
	} else {
		my $out = processOperations($session); #anything that has op=<whatever> will have it's thing done here
		if ($out ne "") {
			# do nothing because we have operation output to display
			$out = undef if ($out eq "chunked");	#'chunked' is WebGUI's way of saying 'I took care of it'  The output was sent to the browser in pieces as quickly as it could be produced. 
		} elsif ($setting->get("specialState") eq "init") { #if specialState is flagged and it's 'init' do initial setup
			$out = setup($session);
		} elsif ($errorHandler->canShowPerformanceIndicators) { #show performance indicators if required
			my $t = [Time::HiRes::gettimeofday()];
			$out = page($session);
			$t = Time::HiRes::tv_interval($t) ;
			if ($out =~ /<\/title>/) {
				$out =~ s/<\/title>/ : ${t} seconds<\/title>/i;
			} else {
				# Kludge.
				my $mimeType = $http->getMimeType();
				if ($mimeType eq 'text/css') {
					$output->print("\n/* Page generated in $t seconds. */\n");
				} elsif ($mimeType eq 'text/html') {
					$output->print("\nPage generated in $t seconds.\n");
				} else {
					# Don't apply to content when we don't know how
					# to modify it semi-safely.
				}
			}
		} else {
			if ($r->headers_in->{'If-Modified-Since'} ne "" && $session->var->get("userId") eq "1") { #display from cache if page hasn't been modified.
				$http->setStatus("304","Content Not Modified");
				$http->sendHeader;
				$session->close;
    				return Apache2::Const::OK();
			} else {					#return the page.
				$out = page($session);
			}
		}
		my $filename = $http->getStreamedFile();
		if ((defined $filename) && ($config->get("enableStreamingUploads") eq "1")) {
			my $ct = guess_media_type($filename);
            		my $oldContentType = $r->content_type($ct);
            		if ($r->sendfile($filename) ) {
				$session->close;
    				return Apache2::Const::OK();
			} else {
                		$r->content_type($oldContentType);
			}
		}
		$http->sendHeader();	#http object will only send the header once per request, so if the above sent a header as part of it's operation, this will do nothing.
		unless ($http->isRedirect()) {
			$output->print($out);
			if ($errorHandler->canShowDebug()) {
				$output->print($errorHandler->showDebug(),1);
			}
		}
		WebGUI::Affiliate::grabReferral($session);	# process affiliate tracking request
	}
	$session->close;
	return Apache2::Const::OK;
}

#-------------------------------------------------------------------

=head2 fixupHandler ( requestObject )

This method is here to allow proper handling of DirectoryIndexes
when someone is using the passthruUrls feature.

=head3 requestObject

The Apache2::RequestRec object passed in by Apache's mod_perl.

=cut

sub fixupHandler {
	my $r = shift;
	
	if ($r->handler eq 'perl-script' &&  # Handler is Perl
	    -d $r->filename              &&  # Filename requested is a directory
	    $r->is_initial_req)		     # and this is the initial request
	{
	    $r->handler(Apache2::Const::DIR_MAGIC_TYPE);  # Hand off to mod_dir
	    return Apache2::Const::OK;
	}
	return Apache2::Const::DECLINED;  # just pass it on
}

#-------------------------------------------------------------------

=head2 page ( session , [ assetUrl ] )

Processes operations (if any), then tries the requested method on the asset corresponding to the requested URL.  If that asset fails to be created, it tries the default page.

=head3 session

The current WebGUI::Session object.

=head3 assetUrl

Optionally pass in a URL to be loaded.

=cut

sub page {
	my $session = shift;
	my $assetUrl = shift || $session->url->getRequestedUrl;
	my $asset = eval{WebGUI::Asset->newByUrl($session,$assetUrl,$session->form->process("revision"))};
	if ($@) {
		$session->errorHandler->warn("Couldn't instantiate asset for url: ".$assetUrl." Root cause: ".$@);
	}
	my $output = undef;
	if (defined $asset) {
		my $method = "view";
		if ($session->form->param("func")) {
			$method = $session->form->param("func");
			unless ($method =~ /^[A-Za-z0-9]+$/) {
				$session->errorHandler->security("to call a non-existent method $method on $assetUrl");
				$method = "view";
			}
		}
		$output = tryAssetMethod($session,$asset,$method);
		$output = tryAssetMethod($session,$asset,"view") unless ($output || ($method eq "view"));
	}
	if ($output eq "") {
		if ($session->var->isAdminOn) { # they're expecting it to be there, so let's help them add it
			my $asset = WebGUI::Asset->newByUrl($session, $session->url->getRefererUrl) || WebGUI::Asset->getDefault($session);
			$output = $asset->addMissing($assetUrl);
		} else { # not in admin mode, so can't create it,  so display not found
			$session->http->setStatus("404","Page Not Found");
			my $notFound = WebGUI::Asset->getNotFound($session);
			if (defined $notFound) {
				$output = tryAssetMethod($session,$notFound,'view');
			} else {
				$session->errorHandler->error("The notFound page could not be instanciated!");
				$output = "An error was encountered while processing your request.";
			}
			$output = "An error was encountered while processing your request." if $output eq '';
		}
	}
	if ($output eq "chunked") {
		$output = undef;
	}
	return $output;
}


#-------------------------------------------------------------------

=head2 processOperations ( session )

Calls the operation dispatcher using the requested operation. 

=head3 session

The current WebGUI::Session object.

=cut

sub processOperations {
	my $session = shift;
	my $output = "";
	my $op = $session->form->process("op");
	if ($op) {
		$output = WebGUI::Operation::execute($session,$op);
	}
	return $output;
}


#-------------------------------------------------------------------

=head2 setup ( session )

Handles a specialState: "setup"

=head3 session

The current WebGUI::Session object.

=cut

sub setup {
	my $session = shift;
	my $i18n = WebGUI::International->new($session, "WebGUI");
	my $output = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<title>WebGUI Initial Configuration</title>
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
		<style type="text/css">
		a { color: black; }
		a:visited { color: black;}
		</style>
	</head>
	<body><div style="font-family: georgia, helvetica, arial, sans-serif; color: white; z-index: 10; width: 550px; height: 400px; top: 20%; left: 20%; position: absolute;"><h1>WebGUI Initial Configuration</h1><fieldset>';
	if ($session->form->process("step") eq "2") {
		$output .= '<legend align="left">Company Information</legend>';
		my $u = WebGUI::User->new($session,"3");
		$u->username($session->form->process("username","text","Admin"));
		$u->profileField("email",$session->form->email("email"));
		$u->identifier(Digest::MD5::md5_base64($session->form->process("identifier","password","123qwe")));
		my $f = WebGUI::HTMLForm->new($session,action=>$session->url->gateway());
		$f->hidden(
			-name=>"step",
			-value=>"3"
			);
		$f->text(
			-name=>"companyName",
			-value=>$session->setting->get("companyName"),
			-label=>$i18n->get(125),
			-hoverHelp=>$i18n->get('125 description'),
			);
		$f->email(
			-name=>"companyEmail",
			-value=>$session->setting->get("companyEmail"),
			-label=>$i18n->get(126),
			-hoverHelp=>$i18n->get('126 description'),
			);
		$f->url(
			-name=>"companyURL",
			-value=>$session->setting->get("companyURL"),
			-label=>$i18n->get(127),
			-hoverHelp=>$i18n->get('127 description'),
			);
		$f->submit;
		$output .= $f->print;
	} elsif ($session->form->process("step") eq "3") {
		$session->setting->remove('specialState');
		$session->setting->set('companyName',$session->form->text("companyName"));
		$session->setting->set('companyURL',$session->form->url("companyURL"));
		$session->setting->set('companyEmail',$session->form->email("companyEmail"));
		$session->http->setRedirect($session->url->gateway());
		return undef;
	} else {
		$output .= '<legend align="left">Admin Account</legend>';
		my $u = WebGUI::User->new($session,'3');
		my $f = WebGUI::HTMLForm->new($session,action=>$session->url->gateway());
		$f->hidden(
			-name=>"step",
			-value=>"2"
			);
		$f->text(
			-name=>"username",
			-value=>$u->username,
			-label=>$i18n->get(50),
			-hoverHelp=>$i18n->get('50 setup description'),
			);
		$f->text(
			-name=>"identifier",
			-value=>"123qwe",
			-label=>$i18n->get(51),
			-hoverHelp=>$i18n->get('51 description'),
			-subtext=>'<div style=\"font-size: 10px;\">('.$i18n->get("password clear text").')</div>'
			);
		$f->email(
			-name=>"email",
			-value=>$u->profileField("email"),
			-label=>$i18n->get(56),
			-hoverHelp=>$i18n->get('56 description'),
			);
		$f->submit;
		$output .= $f->print; 
	}
	$output .= '</fieldset></div>
		<img src="'.$session->url->extras('background.jpg').'" style="border-style:none;position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 5;" />
	</body>
</html>';
	$session->http->setCacheControl("none");
	$session->http->setMimeType("text/html");
	return $output;
}


#-------------------------------------------------------------------

=head2 tryAssetMethod ( session )

Tries an asset method on the requested asset.  Tries the "view" method if that method fails.

=head3 session

The current WebGUI::Session object.

=cut

sub tryAssetMethod {
	my $session = shift;
	my $asset = shift;
	my $method = shift;
	my $state = $asset->get("state");
	return undef if ($state ne "published" && $state ne "archived" && !$session->var->isAdminOn); # can't interact with an asset if it's not published
	$session->asset($asset);
	my $methodToTry = "www_".$method;
	my $output = eval{$asset->$methodToTry()};
	if ($@) {
		$session->errorHandler->warn("Couldn't call method ".$method." on asset for url: ".$session->url->getRequestedUrl." Root cause: ".$@);
		if ($method ne "view") {
			$output = tryAssetMethod($session,$asset,'view');
		} else {
			# fatals return chunked
			$output = 'chunked';
		}
	}
	return $output;
}

#-------------------------------------------------------------------

=head2 uploadsHandler ( requestObject )

Primary http init/response handler for WebGUI.  

=head3 requestObject

The Apache2::RequestRec object passed in by handler().

=cut

sub uploadsHandler {
	my $r = shift;
	my $configFile = shift || $r->dir_config('WebguiConfig');
	my $ok = Apache2::Const::OK;
	my $notfound = Apache2::Const::NOT_FOUND;
	if (-e $r->filename) {
		my $path = $r->filename;
		$path =~ s/^(\/.*\/).*$/$1/;
		if (-e $path.".wgaccess") {
			my $fileContents;
			open(my $FILE,"<",$path.".wgaccess");
			while (<$FILE>) {
				$fileContents .= $_;
			}
			close($FILE);
			my @privs = split("\n",$fileContents);
			unless ($privs[1] eq "7" || $privs[1] eq "1") {
				my $s = Apache2::ServerUtil->server;
				my $request = Apache2::Request->new($r);
				my $session = WebGUI::Session->open($s->dir_config('WebguiRoot'),$configFile, $request, $s);
				my $hasPrivs = ($session->var->get("userId") eq $privs[0] || $session->user->isInGroup($privs[1]) || $session->user->isInGroup($privs[2]));
				$session->close();
				if ($hasPrivs) {
					return $ok;
				} else {
					return 401;
				}
			}
		}
		return $ok;
	} else {
		return $notfound;
	}
}


#-------------------------------------------------------------------

=head2 upgrading ( session )

Handles a specialState: "upgrading"

=head3 session

The current WebGUI::Session object.

=cut

sub upgrading {
	my $session = shift;
	$session->http->sendHeader;
	open(my $FILE,"<",$session->config->getWebguiRoot."/docs/maintenance.html");
	while (<$FILE>) {
		$session->output->print($_);
	}
	close($FILE);
}

1;

