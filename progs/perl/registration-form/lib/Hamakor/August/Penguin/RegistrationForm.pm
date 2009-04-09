package Hamakor::August::Penguin::RegistrationForm;

use strict;
use warnings;

use base 'File::Dir::Dumper::Base';

use File::Spec;

use CGI;
use CGI::Session;

__PACKAGE__->mk_accessors(qw(
    _cgi
    _session
    ));

sub _init
{
    my $self = shift;
    my $args = shift;

    my $cgi = CGI->new();

    $self->_cgi($cgi);

    return;
}

sub _init_session
{
    my $self = shift;

    # TODO : change to a parameter.
    my $dir = File::Spec->rel2abs("./data/session");

    my $session = CGI::Session->new(
        "driver:File",
        $self->_cgi(),
        {
            Directory => $dir,
        },
    );

    $self->_session($session);

    return;
}

my @fields =
(
    {
        id => "name",
        type => "line",
        caption =>
        {
            en => "Name",
            he => "שמך:",
        },
    },
    {
        id => "email",
        type => "line",
        caption =>
        {
            he => "כתובת דואר אלקטרוני:"
        },
    },
    {
        id => "register",
        type => "bool",
        caption =>
        {
            he => "האם תרצו להירשם כחברים או ידידים בעמותת המקור?",
        },
    },
    {
        id => "comments",
        type => "textarea",
        caption =>
        {
            he => "הערות:",
        },
    },
    {
        id => "address",
        type => "line",
        caption =>
        {
            he => "כתובת (לא למלא)",
        },
        trap => 1,
    },
    {
        id => "security_question",
        type => "line",
        caption =>
        {
            he => "אנא חסרו את שני המספרים:",
        },
        captcha => 1,
    },
);

sub _out
{
    my $self = shift;
    
    print @_;
}

sub _output_stylesheet
{
    my $self = shift;

    print $self->_cgi->header(-charset => "utf-8", -type => 'text/css');

    $self->_out(<<"EOF")
body { direction: rtl; text-align: right;}
.f2 { display: none }
.reg_form { border: black thin solid; }
.reg_form td { border: black thin solid; padding: 0.3em; }
EOF
}

sub run
{
    my $self = shift;

    my $cgi = $self->_cgi();
    my $title = "טופס הרשמה לאוגוסט פינגווין 2009";

    my $path_info = $cgi->path_info();

    if ($path_info eq "/style.css")
    {
        return $self->_output_stylesheet();
    }

    $self->_init_session();

    print $self->_session->header(-charset => "utf-8");
    # TODO : add the year fo the conference
    $self->_out(<<"EOF");
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE
    html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
    "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="he-IL">
<head>
<title>$title</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<link rel="stylesheet" href="./style.css" type="text/css" />
</head>
<body>
<h1>$title</h1>

<form method="post" action="./submit.cgi">
<table class="reg_form">
EOF

    my $idx = 0;
    foreach my $field (@fields)
    {
        my $id = $field->{id}
            or die "Could not find id in the field No. $idx";
        my $type = $field->{type};
        my $caption = $field->{caption}->{he}
            or die "Caption not specified in field No. $idx";
        my $tr_class = $field->{trap} ? "f2" : "f1";
        my $caption_esc = CGI::escapeHTML($caption);
        my $form_elem;
        if ($type eq "line")
        {
            $form_elem = qq{<input name="$id" />};
        }
        elsif ($type eq "bool")
        {
            $form_elem = <<"EOF";
<input type="radio" name="$id" value="yes" /> כן
<input type="radio" name="$id" value="no" /> לא
EOF
        }
        elsif ($type eq "textarea")
        {
            $form_elem = qq{<textarea name="$id" cols="70"></textarea>};
        }
        else
        {
            die "Unknown type '$type' in Field No. $idx;"
        }

        $self->_out(qq{<tr class="$tr_class"><td class="desc">$caption</td>}
            . qq{<td class="elem">$form_elem</td></tr>}
        );
    }
    continue
    {
        $idx++;
    }
    $self->_out(qq{</table>\n<p><input type="submit" value="שלח" /></p>\n</form>\n});
    $self->_out("</body>\n</html>\n");

    return 0;
}

1;
