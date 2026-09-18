package Aion::Aya::Migration::Type;

use common::sense;

use Aion::Types qw/subtype as message StrMatch/;
use Exporter qw/import/;

our @EXPORT = our @EXPORT_OK = qw/MigNum/;

BEGIN {
	# Номер миграции (год, месяц, день, час, минута, секунда)
	subtype "MigNum", as StrMatch[qr/^\d{14}\z/a], message { "Number migration is 14 numbers: year, month, day, hour, minute, second. Time migration creaded" };
}

1;