package Hamakor::August::Penguin::RegistrationForm;

use strict;
use warnings;

use base 'File::Dir::Dumper::Base';

use Fcntl ':flock';
use File::Spec;

use CGI;
use CGI::Session;

use File::Dir::Dumper::Stream::JSON::Writer;

__PACKAGE__->mk_accessors(qw(
    _captcha_bottom
    _captcha_top
    _cgi
    _session
    _output_file_fn
    _output_lock_fn
    _session_dir_fn
    ));

sub _init
{
    my $self = shift;
    my $args = shift;

    my $cgi = CGI->new();

    $self->_cgi($cgi);
    $self->_output_file_fn($args->{'output_filename'});
    $self->_output_lock_fn($args->{'output_lock_filename'});
    $self->_session_dir_fn($args->{'session_dir_path'});

    return;
}

sub _init_session
{
    my $self = shift;

    my $session = CGI::Session->new(
        "driver:File",
        $self->_cgi(),
        {
            Directory => $self->_session_dir_fn(),
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
        optional => 1,
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
.math { direction: ltr;}
EOF
}

sub _init_captcha
{
    my $self = shift;

    open my $rand_fh, "<", "/dev/urandom";
    my $buffer;
    read($rand_fh, $buffer, 8);
    close($rand_fh);

    my ($n1, $n2) = unpack("l2", $buffer);
    my $top = 50 + $n1 % 50;
    my $bottom = $n2 % 50;
    my $result = $top - $bottom;
    $self->_captcha_top($top);
    $self->_captcha_bottom($bottom);
    $self->_session->param("captcha_result", $result);
}

sub _out_html_header
{
    my $self = shift;

    print $self->_session->header(-charset => "utf-8");

    return;
}

sub _out_start_html
{
    my $self = shift;
    my $title = shift;

    $title .= " (טופס ההרשמה לאגוסט פינגווין 2009)";
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
EOF

    return;
}

sub _out_intro
{
    my $self = shift;

    $self->_out(<<'EOF');
<p>
<strong>רישום מוקדם זה אינו כרוך בכל תשלום.</strong>
מטרתו היא לסייע למארגנים לאמוד את כמות הבאים. תודה על העזרה!
</p>
<p>
הכנס יתקיים ביום FILL_IN, שעה FILL_IN בבית ציוני אמריקה בתל-אביב, רח' אבן גבירול 26, פינת דניאל פריש 1.
</p>
<p>
<a href="http://www.zoa.co.il/?CategoryID=167" title="arrival" target="blank">להסברי הגעה וקווי אוטובוס</a>
</p>
<p>
לצורך הרשמה לכנס אוגוסט פינגווין 2009, אתם מתבקשים להכניס
את הפרטים בטופס. לידיעתכם, הכניסה ביום הכנס תהיה בתשלום סימלי
בסך 30 ש"ח כאשר האנשים הבאים פטורים מתשלום:
</p>
<ul>
<li>
בעלי כרטיס חבר או ידיד בעמותת "המקור", בתוקף.
</li>
<li>
חבר איגוד האינטרנט הישראלי.
</li>
</ul>

EOF

}
sub _output_form
{
    my $self = shift;
    my $args = shift;

    my $title = $args->{'title'};
    my $notice_para = $args->{'notice_para'};
    my $is_intro = $args->{'intro'};

    $self->_init_session();
    $self->_init_captcha();

    $self->_out_html_header();

    $self->_out_start_html_and_para($title, $notice_para);

    if ($is_intro)
    {
        $self->_out_intro();
    }

    $self->_out(<<"EOF");
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
        my $val = $self->_cgi->param($id);
        if ($type eq "line")
        {
            if ($field->{captcha})
            {
                $form_elem = qq{<div class="math">}
                    . $self->_captcha_top() . " - "
                    . $self->_captcha_bottom() . " = "
                    . qq{<input name="$id" />}
                    . "</div>"
                    ;
            }
            else
            {
                $form_elem =
                    qq{<input name="$id" value="}
                    . CGI::escapeHTML($val)
                    . qq{"/>}
                    ;
            }
        }
        elsif ($type eq "bool")
        {
            my @options =
            (
                { val => "yes", he => "כן", },
                { val => "no", he => "לא", },
            );
            $form_elem = join("",
                map
                {
                    qq(<input type="radio" name="$id" value="$_->{val}")
                        . (($_->{val} eq $val) ? qq{ checked="1"} : "")
                        . " /> $_->{he}\n" 
                }
                @options
            );
        }
        elsif ($type eq "textarea")
        {
            $form_elem = qq{<textarea name="$id" cols="70">} 
                . CGI::escapeHTML($val)
                . qq{</textarea>}
                ;
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

sub _out_end
{
    my $self = shift;

    $self->_out("\n</body>\n</html>\n");

    return;
}

sub _out_start_html_and_para
{
    my $self = shift;
    my $title = shift;
    my $para = shift;

    $self->_out_start_html($title);

    if (defined($para))
    {
        $self->_out("<p>\n$para\n</p>\n");
    }

    return;
}

sub _handle_form_submission
{
    my $self = shift;

    my $cgi = $self->_cgi();

    $self->_init_session();

    my $data = +{};
    my $this_is_spam = 0;
    my $wrong_captcha = 0;
    my $missing_fields = 0;

    FIELDS_LOOP:
    foreach my $field (@fields)
    {
        my $id = $field->{'id'};
        my $val = $cgi->param($id);

        if ($field->{'trap'})
        {
            if (length($val))
            {
                $this_is_spam = 1;
                last FIELDS_LOOP;
            }
            else
            {
                next FIELDS_LOOP;
            }
        }
        elsif ($field->{'captcha'})
        {
            if ($val ne $self->_session->param("captcha_result"))
            {
                $wrong_captcha = 1;
                last FIELDS_LOOP;
            }
            else
            {
                next FIELDS_LOOP;
            }
        }
        elsif (!length($val))
        {
            if (! $field->{'optional'})
            {
                $missing_fields = 1;
                last FIELDS_LOOP;
            }
        }

        $data->{$id} = $val;
    }


    if ($missing_fields)
    {
        $self->_output_form(
            {
                title => "חסרים שדות",
                notice_para => "חסרים שדות בטופס. אנא שלח שוב.",
            }
        );
    }
    elsif ($this_is_spam)
    {
        $self->_out_html_header();
        print STDERR "This Is Spam --- output_file_fn = <<<" . $self->_output_file_fn() . ">>>\n";
        $self->_out_start_html_and_para("הטופס נשלח בהצלחה",
            "הטופס נשלח בהצלחה.",
        );
    }
    elsif ($wrong_captcha)
    {
        $self->_output_form(
            {
                title => "התשובה לשאלת האבטחה אינה נכונה",
                notice_para => "התשובה לשאלת האבטחה (של חיסור שני מספרים) אינה נכונה. אנא מלא את התשובה הנכונה ושלח שוב.",
            },
        );
    }
    else
    {
        # Handle the case where everything is OK.

        open my $lock_fh, "<", $self->_output_lock_fn()
            or die "Cannot open lock file handle";
        flock ($lock_fh, LOCK_EX());

        print STDERR "output_file_fn = <<<" . $self->_output_file_fn() . ">>>\n";
        open my $recording_fh, ">>", $self->_output_file_fn()
            or die "Cannot open recording file handle";

        my $stream = File::Dir::Dumper::Stream::JSON::Writer->new(
            {
                output => $recording_fh,
                append => (tell($recording_fh) > 0),
            }
        );

        $stream->put(
            +{ 
                type => "registration",
                details => $data,
                timestamp => time(),
             }
        );

        # Closes $recording_fh
        $stream->close();

        flock($lock_fh, LOCK_UN());

        close($lock_fh);

        $self->_out_html_header();
        $self->_out_start_html_and_para(
            "הטופס נשלח בהצלחה",
            "הטופס נשלח בהצלחה.",
        );
    }

    $self->_out_end();
}

sub run
{
    my $self = shift;

    my $path_info = $self->_cgi->path_info();

    if ($path_info eq "/style.css")
    {
        return $self->_output_stylesheet();
    }
    elsif ($path_info eq "/submit.cgi")
    {
        return $self->_handle_form_submission();
    }
    elsif ($path_info eq "/")
    {
        return $self->_output_form(
            {
                title => "עמוד ראשי",
                intro => 1,
            }
        );
    }
    else
    {
        die "Unknown path_info!";
    }
}

1;
