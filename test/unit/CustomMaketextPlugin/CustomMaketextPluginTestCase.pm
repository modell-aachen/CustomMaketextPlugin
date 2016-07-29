# See bottom of file for license and copyright information
use strict;
use warnings;

package CustomMaketextPluginTestCase;

use FoswikiFnTestCase;
our @ISA = qw( FoswikiFnTestCase );

use Foswiki();
use Error qw ( :try );
use Foswiki::Plugins::CustomMaketextPlugin();


# Force reload of I18N in case it wasn't enabled
if ( delete $INC{'Foswiki/I18N.pm'} ) {
    # Clean the symbol table to remove loaded subs
    no strict 'refs';
    @Foswiki::I18N::ISA = ();
    my $symtab = "Foswiki::I18N::";
    foreach my $symbol ( keys %{$symtab} ) {
        next if $symbol =~ /\A[^:]+::\z/;
        delete $symtab->{$symbol};
    }
}

sub new {
    my ($class, @args) = @_;
    my $this = shift()->SUPER::new('CustomMaketextPluginTestCase', @args);
    return $this;
}
sub loadExtraConfig {
    my $this = shift;
    $this->SUPER::loadExtraConfig();
    $Foswiki::cfg{Plugins}{CustomMaketextPlugin}{Enabled} = 1;
    $Foswiki::cfg{UserInterfaceInternationalisation} = 1;
    $Foswiki::cfg{Languages}{de}{Enabled}= 1;
    $Foswiki::cfg{WebMasterEmail} = 'a.b@c.org';
}

# WE ARE NOT ABLE TO CHANGE LANGUAGE AT THE MOMENT
# Test if...
# ..create ZZCustom
# ..create de.po
# ..add translation
# ..expand makro MAKTEXT
sub _test_changeTranslation{
    my $this = shift;

    $this->createNewFoswikiSession( $Foswiki::cfg{AdminUserLogin} || 'AdminUser' );
    my $user = Foswiki::Func::getWikiName();
    $this->assert( Foswiki::Func::isAnAdmin($user), "Could not become AdminUser, tried as $user." );

    # create ZZCUstom unless exists
    my $query = Unit::Request->new( { action => ['rest'], web=>'ZZCustom' } );
    $query->path_info( '/CustomMaketextPlugin/createweb' );
    $query->method('post');

    $this->createNewFoswikiSession( $user, $query );
    # check response
    my $UI_FN = $this->getUIFn('rest');
    my ($response) = $this->capture( $UI_FN, $this->{session} );

    my $dir = "$Foswiki::cfg{LocalesDir}/ZZCustom";
    $this->assert(-d $dir);

    # create de.po unless exists
    $query = Unit::Request->new( { action => ['rest'], language=>'de.po' } );
    $query->path_info( '/CustomMaketextPlugin/addlanguage' );
    $query->method('post');

    $this->createNewFoswikiSession( $user, $query );
    # check response
    $UI_FN = $this->getUIFn('rest');
    ($response) = $this->capture( $UI_FN, $this->{session} );

    my $file = "$Foswiki::cfg{LocalesDir}/ZZCustom/de.po";
    $this->assert(-f $file);

    # change translation from comment de.po
    # params: 1_str 1_com de.po_1
    $query = Unit::Request->new( { action => ['rest'], "1_com"=>'Comment changed', "1_str"=>'Comment', "de.po_1"=>'Neues Kommentar' } );
    $query->path_info( '/CustomMaketextPlugin/save' );
    $query->method('post');

    $this->createNewFoswikiSession( $user, $query );
    # check response
    $UI_FN = $this->getUIFn('rest');
    ($response) = $this->capture( $UI_FN, $this->{session} );

    # does not need to reload server

    # Foswiki::Func::setPreferencesValue('LANGUAGE', 'de');
    $Foswiki::Plugins::SESSION->reset_i18n();

    # Expand Macro
    my $text = '%MAKETEXT{"Comment"}%';
    my ($topicObject) = Foswiki::Func::readTopic( $this->{test_web}, 'WebHome' );
    $text = $topicObject->expandMacros($text);
    # print $text;
    # $this->assert($text eq 'Neues Kommentar');

    return 1;
}

1;
__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Author: Modell Aachen GmbH

Copyright (C) 2008-2011 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
