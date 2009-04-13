#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;

use lib "./lib";

use Hamakor::August::Penguin::RegistrationForm;

exit(
    Hamakor::August::Penguin::RegistrationForm->new(
        {
            output_filename => File::Spec->rel2abs("./data/output/out.txt"),
            output_lock_filename => File::Spec->rel2abs("./data/output/lock"),
        }
    )->run()
);

