package Hamakor::August::Penguin::RegistrationForm;

use strict;
use warnings;

use base 'File::Dir::Dumper::Base';

use CGI;

__PACKAGE__->mk_accessors(qw(
    _cgi
    ));

sub _init
{
    my $self = shift;
    my $args = shift;

    my $cgi = CGI->new();

    $self->_cgi($cgi);

    return;
}

sub run
{
    my $self = shift;

    print $self->_cgi()->header();
    print "<html><body>Hello</body></html>\n";

    return 0;
}

1;

