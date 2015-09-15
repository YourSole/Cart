use utf8;
package Test::Schema::Result::CartProduct;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Test::Schema::Result::CartProduct

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<cart_products>

=cut

__PACKAGE__->table("cart_products");

=head1 ACCESSORS

=head2 cart_id

  data_type: 'integer'
  is_nullable: 0

=head2 product_id

  data_type: 'integer'
  is_nullable: 0

=head2 price

  data_type: 'numeric'
  is_nullable: 0

=head2 quantity

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "cart_id",
  { data_type => "integer", is_nullable => 0 },
  "product_id",
  { data_type => "integer", is_nullable => 0 },
  "price",
  { data_type => "numeric", is_nullable => 0 },
  "quantity",
  { data_type => "integer", is_nullable => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-09-15 08:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:K+k00pcfWqa7w3bV0eRaow


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
