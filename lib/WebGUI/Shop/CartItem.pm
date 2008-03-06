package WebGUI::Shop::CartItem;

use strict;
use Class::InsideOut qw{ :std };
use JSON;
use WebGUI::Asset;
use WebGUI::Exception::Shop;

=head1 NAME

Package WebGUI::Shop::CartItem

=head1 DESCRIPTION

A cart item is a manager of a WebGUI::Asset::Sku class that is put into a user's cart.

=head1 SYNOPSIS

 use WebGUI::Shop::CartItem;

 my $item = WebGUI::Shop::CartItem->new($session, $cartId, $assetId);

=head1 METHODS

These subroutines are available from this package:

=cut

readonly cart => my %cart;
private properties => my %properties;

#-------------------------------------------------------------------

=head2 cart ( )

Returns a reference to the cart.

=cut

#-------------------------------------------------------------------

=head2 create ( cart, item)

Constructor. Adds an item to the cart. Returns a reference to the item.

=head3 cart

A reference to WebGUI::Shop::Cart object.

=head3 item

A reference to a subclass of WebGUI::Asset::Sku.

=cut

sub create {
    my ($class, $cart, $sku) = @_;
    unless (defined $cart && $cart->isa("WebGUI::Shop::Cart")) {
        WebGUI::Error::InvalidObject->throw(expected=>"WebGUI::Shop::Cart", got=>(ref $cart), error=>"Need a cart.");
    }
    unless (defined $sku && $sku->isa("WebGUI::Asset::Sku")) {
        WebGUI::Error::InvalidObject->throw(expected=>"WebGUI::Asset::Sku", got=>(ref $sku), error=>"Need a SKU item.");
    }
    my $itemId = $cart->session->id->generate;
    $cart->session->db->write('insert into cartItems (quantity, cartId, assetId, itemId) values (1,?,?,?)', [$cart->getId, $sku->getId, $itemId]);
    my $self = $class->new($cart, $itemId);
    $self->update({asset=>$sku});
    return $self;
}

#-------------------------------------------------------------------

=head2 get ( [ property ] )

Returns a duplicated hash reference of this object’s data.

=head3 property

Any field − returns the value of a field rather than the hash reference.

=cut

sub get {
    my ($self, $name) = @_;
    if (defined $name) {
        if ($name eq "options") {
            my $options = $properties{id $self}{$name};
            if ($options eq "") {
                return {};
            }
            else {
                return JSON::from_json($properties{id $self}{$name});
            }
        }
        return $properties{id $self}{$name};
    }
    my %copyOfHashRef = %{$properties{id $self}};
    return \%copyOfHashRef;
}

#-------------------------------------------------------------------

=head2 getId () 

Returns the unique id of this item.

=cut

sub getId {
    my $self = shift;
    return $self->get("itemId");
}


#-------------------------------------------------------------------

=head2 getShippingAddress ()

Returns the WebGUI::Shop::Address object that is attached to this item for shipping.

=cut

sub getShippingAddress {
    my $self = shift;
    return $self->cart->getAddressBook->getAddress($self->get("shippingAddressId"));
}

#-------------------------------------------------------------------

=head2 getSku ( )

Returns an instanciated WebGUI::Asset::Sku object for this cart item.

=cut

sub getSku {
    my ($self) = @_;
    my $asset = WebGUI::Asset->newByDynamicClass($self->cart->session, $self->get("assetId"));
    $asset->applyOptions($self->get("options"));
    return $asset;
}


#-------------------------------------------------------------------

=head2 incrementQuantity ( [ quantity ] )

Increments quantity of item by one. Returns the quantity of this item in the cart.

=head3 quantity

If specified may increment quantity by more than one. Specify a negative number to decrement quantity. If the quantity ever reaches 0 or lower, the item will be removed from the cart.

=cut

sub incrementQuantity {
    my ($self, $quantity) = @_;
    $quantity ||= 1;
    $self->setQuantity($quantity + $self->get("quantity"));
    return $self->get("quantity");
}


#-------------------------------------------------------------------

=head2 new ( cart, itemId )

Constructor.  Instanciates a cart item based upon itemId.

=head3 cart

A reference to the current cart we're working with.

=head3 itemId

The unique id of the item to instanciate.

=cut

sub new {
    my ($class, $cart, $itemId) = @_;
    unless (defined $cart && $cart->isa("WebGUI::Shop::Cart")) {
        WebGUI::Error::InvalidObject->throw(expected=>"WebGUI::Shop::Cart", got=>(ref $cart), error=>"Need a cart.");
    }
    unless (defined $itemId) {
        WebGUI::Error::InvalidParam->throw(error=>"Need an itemId.");
    }
    my $item = $cart->session->db->quickHashRef('select * from cartItems where itemId=?', [$itemId]);
    if ($item->{itemId} eq "") {
        WebGUI::Error::ObjectNotFound->throw(error=>"Item not found.", id=>$itemId);
    }
    if ($item->{cartId} ne $cart->getId) {
        WebGUI::Error::ObjectNotFound->throw(error=>"Item not in this cart.", id=>$itemId);
    }
    my $self = register $class;
    my $id        = id $self;
    $cart{ $id }   = $cart;
    $properties{ $id } = $item;
    return $self;
}

#-------------------------------------------------------------------

=head2 remove ( )

Removes this item from the cart.

=cut

sub remove {
    my $self = shift;
    $self->cart->session->db->deleteRow("cartItems","itemId",$self->getId);
    undef $self;
    return undef;
}


#-------------------------------------------------------------------

=head2 setQuantity ( quantity )

Sets quantity of this item in the cart. 

=head3 quantity

The number to set the quantity to. Zero or less will remove the item from cart. 

=cut

sub setQuantity {
    my ($self, $quantity) = @_;
    my $id = id $self;
    if ($quantity > $self->getSku->getMaxAllowedInCart) {
        WebGUI::Error::Shop::MaxOfItemInCartReached->throw(error=>"Cannot have that many of this item in cart.");
    }
    if ($quantity <= 0) {
        return $self->remove;
    }
    $properties{$id}{quantity} = $quantity;
    $self->cart->session->db->setRow("cartItems","itemId", $properties{$id});
}

#-------------------------------------------------------------------

=head2 update ( properties )

Sets properties of the cart item.

=head3 properties

A hash reference that contains one of the following:

=head4 asset

This is a special meta property. It is a reference to a WebGUI::Asset::Sku subclass object. If you pass this reference it will acquire the assetId, configuredTitle, and options properties automatically.

=head4 assetId 

The assetId of the asset to add to the cart.

=head4 options

The configuration options for this asset.

=head4 configuredTitle

The title of this product as configured.

=head4 shippingAddressId

The unique id for a shipping address attached to this cart.

=cut

sub update {
    my ($self, $newProperties) = @_;
    my $id = id $self;
    if (exists $newProperties->{asset}) {
        $newProperties->{options} = $newProperties->{asset}->getOptions;
        $newProperties->{assetId} = $newProperties->{asset}->getId;       
        $newProperties->{configuredTitle} = $newProperties->{asset}->getConfiguredTitle;       
    }
    foreach my $field (qw(assetId configuredTitle shippingAddressId)) {
        $properties{$id}{$field} = (exists $newProperties->{$field}) ? $newProperties->{$field} : $properties{$id}{$field};
    }
    if (exists $newProperties->{options} && ref($newProperties->{options}) eq "HASH") {
        $properties{$id}{options} = JSON::to_json($newProperties->{options});
    }
    $self->cart->session->db->setRow("cartItems","itemId",$properties{$id});
}


1;
