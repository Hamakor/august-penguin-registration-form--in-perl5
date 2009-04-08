#!/usr/bin/perl

use strict;
use warnings;

use lib "./lib";

use Hamakor::August::Penguin::RegistrationForm;

exit(
    Hamakor::August::Penguin::RegistrationForm->new({
        }
    )->run()
);

