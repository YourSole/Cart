# NAME

Dancer2::Plugin::Cart - Ecommerce Cart Plugin for Dancer2

# VERSION 

Version 0.000001

# DESCRIPTION

This plugin provides a easy way to manage a shopping cart in dancer2.  All the information and data structure of the plugin will be manage by the session, so a good idea is to use a plugin in order to store the session data in the database.  

It was designed to be used on new or existing database, providing a lot of hooks in order to fit customizable solutions.

The plugin is going to search default templates on the views directory, if the view doesn't exists, the plugin will render and inline template provided by the plugin.

The plugin become with a script file in order to generate basic views of each stage of a checkout, and you will be able to adapt it as your need.



# SYNOPSIS

1.  Crate a table as:
    CREATE TABLE ec_cart (
      id serial,
      name  TEXT NOT NULL,
      session TEXT NOT NULL,
      status INTEGER NOT NULL default 0,
      log TEXT,
      PRIMARY KEY(id)
    );

    CREATE TABLE ec_cart_product (
      cart_id INTEGER NOT NULL,
      sku  TEXT NOT NULL,
      price NUMERIC NOT NULL,
      quantity  INTEGER NOT NULL,
      place INTEGER NOT NULL,
      PRIMARY KEY(cart_id, sku)
    );


2. Generate the DBIC clases:

    A good way to do it is with dbicdump as an example:

    dbicdump -o overwrite_modifications=1 -o db_schema=public App::Schema -o constraint='qr/ec_cart/' "dbi:Pg:dbname=$dbname;host=$host;port=$port; options=$options; tty=$tty", "$username", "$password"


3. Configure the plugin in order to set up the tables and main fields.  The mandatory fields are in teh example, and the configuration options are listed below.

plugins:
  Cart:
    product_name: 'Product'
    product_pk: 'sku'
    product_price: 'price'

4. use the library

    On your app.pm add:

    use Dancer2::Plugin2::Cart;



##Configuration Options: 

* cart_name:  
* cart_product_name
* product_name
* product_pk
* product_price
* product_filter
* product_order
* products_view_template
* cart_vidw_template
* cart_receipt_template
* cart_checkout_template
* shipping_view_template
* billing_view_template
* review_view_template
* receipt_view_template
* default_routes
* excluded_routes 


##Keywords:

* products
* cart
* cart_add
* cart_add_item
* cart_items
* clear_cart
* subtotal
* billing
* shipping
* checkout
* close_cart
* adjustments



##Hooks:

* before_cart
* after_cart
* validate_cart_add_params
* before_cart_add
* after_cart_add
* before_cart_add_item
* after_cart_add_item
* validate_shipping_params
* before_shipping
* after_shipping
* validate_billing_params
* before_billing
* after_billing
* validate_checkout_params
* before_checkout
* checkout
* after_checkout
* before_close_cart
* after_close_cart
* before_clear_cart
* after_clear_cart
* before_item_subtotal
* after_item_subtotal
* before_subtotal
* after_subtotal
* adjustments




# BUGS
Please use GitHub issue tracker 
[here](https://github.com/YourSole/Cart).

# AUTHORS

YourSole Core Developers

## DEVELOPERS
    Ruben Amortegui

# AUTHOR

Ruben Amortegui `<ruben.amortegui@gmail.com>`


# COPYRIGHT AND LICENSE

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

