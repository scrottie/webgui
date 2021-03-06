package WebGUI::ProgressBar;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2012 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use strict;

=head1 NAME

Package WebGUI::ProgressBar

=head1 DESCRIPTION

Render a progress bar for the user inside a nice style.

=head1 SYNOPSIS

 use WebGUI::ProgressBar;

 my $pb = WebGUI::ProgressBar->new($session);
 $pb->start($title, $iconUrl);
 $pb->update($message);
 $pb->finish($redirectUrl); 

=head1 METHODS

These methods are available from this class:

=cut

#-------------------------------------------------------------------

=head2 new ( session )

Constructor.

=head3 session

A reference to the current session.

=cut

sub new {
	my $class   = shift;
	my $session = shift;
    my $recordCount = shift;
    my $self    = {};
	$self->{_session}    = $session;
    $self->{_counter}    = 1;
	bless $self, $class;
	return $self;
}

#-------------------------------------------------------------------

=head2 finish ( $url|$helper )

Redirects the user out of the status page.

=head3 $url

The URL to send the user to.

=head3 $helper

A hashref response for an Asset Helper to be processed by the Admin Console

=cut

sub finish {
	my $self    = shift;
	my $arg     = shift;

        # We may have been passed a URL to go to, or an Asset Helper response hash
        my ( $url, $helper );
        if ( !ref $arg ) {
            $url    = $arg;
        }
        elsif ( ref $arg eq "HASH" ) {
            $helper = $arg;
        }

        local $| = 1;
        if ( $url ) {
            my $text = sprintf(<<EOJS, $url);
<script>
window.location.href='%s';
</script>
EOJS
            $self->session->output->print($text . $self->{_foot}, 1); # skipMacros
            return 'chunked';
        }
        else {
            # We're in admin mode, close the dialog
            my $text = '<script type="text/javascript">';

            if ( ref $helper eq 'HASH' ) {
                # Process the output as JSON
                $text .= sprintf 'parent.admin.processPlugin( %s );', JSON->new->encode( $helper );
            }

            # Close dialog last so that script above runs!
            $text .= 'parent.admin.closeModalDialog();'
                   . '</script>';

            $self->session->output->print( $text, 1); # skipMacros
            return 'chunked';
        }
}

#-------------------------------------------------------------------

=head2 session ( )

Returns a reference to the current session.

=cut

sub session {
	my $self = shift;
	return $self->{_session};
}

#-------------------------------------------------------------------

=head2 start ( title, icon )

Returns a templated progress bar implemented in CSS and JS.

=head3 title

A title to display above the progress bar.

=head3 icon

The url to the icon you want to display.

=cut

sub start {
    my ($self, $title, $icon) = @_;
    $self->session->response->setCacheControl("none");
    my %var      =  (
        title   => $title,
        icon    => $icon
        );
    my $template = WebGUI::Asset::Template->newById($self->session, 'YP9WaMPJHvCJl-YwrLVcPw');
    my $output = $self->session->style->process($template->process(\%var).'~~~', "PBtmpl0000000000000137");
    my ($head, $foot) = split '~~~', $output;
    local $| = 1; # Tell modperl not to buffer the output
    $self->session->response->sendHeader;
    $self->session->output->print($head, 1); #skipMacros
    $self->{_foot} = $foot;
    return '';
}

#-------------------------------------------------------------------

=head2 update ( $message )

Sends a message and increments the status bar.

=head3 $message

A message to be displayed in the status bar.

=cut

{

# Keep the sprintf string short and don't recompute buffer breaker every time
# update is called
my $prefix = '<script type="text/javascript">
/* ' . 'BUFFER BREAKER ' x 1000 . ' */
updateWgProgressBar(';
my $format = q"%d, '%s'";
my $suffix = '); 
</script>
';

sub update {
	my $self    = shift;
	my $message = shift;
    $message    =~ s/'/\\'/g; ##Encode single quotes for JSON;
    $self->session->log->preventDebugOutput;

    if ( $self->{_total} ) {
        $self->{_counter} += 1;
    }

    # Calculate percent progress. If we don't know our total yet, we haven't progressed any!
    my $progress    = $self->{_total} ? int( $self->{_counter} / $self->{_total} * 100 ) : 0;

    my $text = $prefix . sprintf($format, $progress, $message) . $suffix;

    local $| = 1; # Tell modperl not to buffer the output
    $self->session->output->print($text, 1); #skipMacros
    return '';
}

}

#-------------------------------------------------------------------

=head2 total ( newTotal )

Set the total number of tasks that need to be run. You should set this
before running any actual tasks. If this is not set, the progress bar
will not progress (though any update messages will still display to 
the user).

=cut

sub total {
    my ( $self, $newTotal ) = @_;
    if ( $newTotal ) {
        return $self->{_total} = $newTotal;
    }
    return $self->{_total};
}

#-------------------------------------------------------------------

=head2 run ( options )

starts and finishes a progress bar, running some code in the middle.  It
returns 'chunked' for convenience - if you don't use the return value, you
should return 'chunked' yourself.

The following keyword arguments are accepted (either as a bare hash or a
hashref).

=head3 total

Set the total number of tasks that need to be run. Every call to update() is
another task completed. The progressbar works with percentages, so this
must be set before any tasks are started.

If you need to calculate the number of tasks, be sure to set total() inside
the C<code> subref before doing any actual work.

=head3 code

A coderef to run in between starting and stopping the progress bar.  It is
passed the progress bar instance as its first and only argument.  It should
return the url to redirect to with finish(), or a false value.

=head3 arg

An argument (just one) to be passed to code when it is called.

=head3 title

See start().

=head3 icon

See start().

=head3 admin

If true, will send the correct JS to close the dialog box.

=head3 wrap

A hashref of subroutine names to code references.  While code is being called,
these subroutines will be wrapped with the provided code references, which
will be passed the progress bar instance, the original code reference, and any
arguments it would have received, similiar to a Moose 'around' method, e.g.

    wrap => {
        'WebGUI::Asset::update' => sub {
            my $bar      = shift;
            my $original = shift;
            $bar->update('some message');
            $original->(@_);
        }
    }

=cut

sub run {
    my $self = shift;
    my $args = $_[0];
    $args = { @_ } unless ref $args eq 'HASH';

    my %original;
    my $wrap = $args->{wrap};

    $self->start($args->{title}, $args->{icon});
    $self->{_total} = $args->{total};

    my $url = eval {
        for my $name (keys %$wrap) {
            my $original = $original{$name} = do { no strict 'refs'; \&$name };
            my $wrapper  = $wrap->{$name};
            no strict 'refs';
            *$name = sub {
                unshift(@_, $self, $original);
                goto &$wrapper;
            };
        }

        $args->{code}->($self, $args->{arg});
    };
    my $e = $@;

    # Always, always restore coderefs
    for my $name (keys %original) {
        my $c  = $original{$name};
        if (ref $c eq 'CODE') {
            no strict 'refs';
            *$name = $c;
        }
    }

    die $e if $e;

    return $self->finish( $url || ( !$args->{admin} && $self->session->url->page ) );
}

1;
