package Aion::Aya::Migration::Types;

use common::sense;

use Aion::Types qw/subtype as message StrMatch Str/;
use Exporter qw/import/;

our @EXPORT = our @EXPORT_OK = qw/MigNum MIGRATIONS_PATH/;

use Aion::Env::Etc MIGRATIONS_PATH => (isa => Str, default => 'migrations', key => 'aion.aya.migrations_path');

BEGIN {
	# Номер миграции (год, месяц, день, час, минута, секунда)
	subtype "MigNum", as StrMatch[qr/^\d{14}\z/a], message { "Number migration is 14 numbers: year, month, day, hour, minute, second. Time migration creaded" };
}

1;