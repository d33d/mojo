package Mojolicious::Command::Get;

use Mojo::Base 'Mojo::Command';

use Mojo::Client;
use Mojo::IOLoop;
use Mojo::Transaction::HTTP;
use Mojo::Util 'decode';

use Getopt::Long 'GetOptions';

has description => <<'EOF';
Get file from URL.
EOF
has usage => <<"EOF";
usage: $0 get [OPTIONS] [URL]

These options are available:
  --redirect   Follow up to 5 redirects.
  --verbose    Print response start line and headers to STDERR.
EOF

# I hope this has taught you kids a lesson: kids never learn.
sub run {
    my $self = shift;

    # Options
    local @ARGV = @_ if @_;
    my ($redirect, $verbose) = 0;
    GetOptions(
        'redirect' => sub { $redirect = 1 },
        'verbose'  => sub { $verbose  = 1 }
    );

    # URL
    my $url = $ARGV[0];
    die $self->usage unless $url;
    decode 'UTF-8', $url;

    # Client
    my $client = Mojo::Client->new(ioloop => Mojo::IOLoop->singleton);

    # Silence
    $client->log->level('fatal');

    # Application
    $client->app($ENV{MOJO_APP} || 'Mojo::HelloWorld')
      unless $url =~ /^\w+:\/\//;

    # Follow redirects
    $client->max_redirects(5) if $redirect;

    # Start
    my $v;
    $client->on_start(
        sub {
            my $tx = pop;
            my $v  = $verbose;
            $tx->res->on_progress(
                sub {
                    return unless $v;
                    my $res     = shift;
                    my $version = $res->version;
                    my $code    = $res->code;
                    my $message = $res->message;
                    warn "HTTP/$version $code $message\n",
                      $res->headers->to_string, "\n\n";
                    $v = 0;
                }
            );
            $tx->res->body(sub { print pop });
            return unless $v;
            my $req = $tx->req;
            warn $req->build_start_line;
            warn $req->build_headers;
        }
    );

    # Request
    my $tx = $client->get($url);

    # Error
    my ($message, $code) = $tx->error;
    warn qq/Problem loading URL "$url". ($message)\n/ if $message && !$code;

    return $self;
}

1;
__END__

=head1 NAME

Mojolicious::Command::Get - Get Command

=head1 SYNOPSIS

    use Mojolicious::Command::Get;

    my $get = Mojolicious::Command::Get->new;
    $get->run(@ARGV);

=head1 DESCRIPTION

L<Mojolicious::Command::Get> is a command interface to L<Mojo::Client>.

=head1 ATTRIBUTES

L<Mojolicious::Command::Get> inherits all attributes from L<Mojo::Command>
and implements the following new ones.

=head2 C<description>

    my $description = $get->description;
    $get            = $get->description('Foo!');

Short description of this command, used for the command list.

=head2 C<usage>

    my $usage = $get->usage;
    $get      = $get->usage('Foo!');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::Get> inherits all methods from L<Mojo::Command> and
implements the following new ones.

=head2 C<run>

    $get = $get->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
