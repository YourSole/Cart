use utf8;
package Test::Schema::Result::Cart;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Test::Schema::Result::Cart

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<cart>

=cut

__PACKAGE__->table("cart");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 session

  data_type: 'text'
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "session",
  { data_type => "text", is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-09-15 08:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:S/8yJ3OjiOmyaEVH3y97XQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
