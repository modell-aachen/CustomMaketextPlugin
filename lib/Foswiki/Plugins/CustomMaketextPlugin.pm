# See bottom of file for default license and copyright information
package Foswiki::Plugins::CustomMaketextPlugin;

use strict;
use warnings;

use Encode;
use Locale::PO;
use Foswiki::Plugins::JQueryPlugin;

our $VERSION = '1.0';
our $RELEASE = '1.0';
our $SHORTDESCRIPTION = 'Customize ZZCustom in frontend';

# bin config does not validate the string correctly
our $DEFAULTHEADER = <<'END_HEADER';
Project-Id-Version: CustomMaketextPlugin $Id
Report-Msgid-Bugs-To: support@modell-aachen.de
POT-Creation-Date: CREATED
PO-Revision-Date: POREVISION
Last-Translator: Modell Aachen <access@modell-aachen.de>
Language-Team: LANG <http://translate.modell-aachen.de/projects/custommaketextplugin
/releaseriga/LANG/>
Language: LANG
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit
Plural-Forms: nplurals=2; plural=n != 1
X-Generator: custommaketextplugin
END_HEADER

sub initPlugin {
    my ( $topic, $web, $user, $installWeb ) = @_;
    # check for Plugins.pm versions
    if ( $Foswiki::Plugins::VERSION < 2.0 ) {
     Foswiki::Func::writeWarning( 'Version mismatch between ', 
        __PACKAGE__, ' and Plugins.pm' );
     return 0;
    }

    Foswiki::Func::registerTagHandler( 'CUSTOMIZEMAKETEXT', \&_customizeMaketext );
    
    my %restopts = (authenticate => 1, validate => 0, http_allow => 'POST');
    Foswiki::Func::registerRESTHandler( 'addlanguage', \&_restAddLanguage, %restopts );
    Foswiki::Func::registerRESTHandler( 'removelanguage', \&_restRemoveLanguage, %restopts );
    Foswiki::Func::registerRESTHandler( 'save', \&_restSave, %restopts );
    Foswiki::Func::registerRESTHandler( 'createweb', \&_restcreateWebDir, %restopts );
    # GET enabled handlers
    $restopts{http_allow} = 'POST,GET';
    Foswiki::Func::registerRESTHandler( 'reloadhttpd', \&_restReloadHttpd, %restopts );
    return 1;
}

# Helper functions

# Check if reload is allowed in current session.
sub _reloadAllowed {
    for my $group (split(/\s+,\s+/, ($Foswiki::cfg{CustomMaketextPlugin}{AllowReload} || 'AdminGroup'))) {
        if (Foswiki::Func::isGroupMember($group, Foswiki::Func::getWikiName())) {
            return 1;
        }
    }
    return 0;
}

# Text generators and REST handlers
sub _customizeMaketext {
    my( $session, $params, $topic, $web, $topicObject ) = @_;
    my $web = Foswiki::Func::getPreferencesValue("CUSTOMMAKETEXT_WEB") || 'ZZCustom';
    my $pluginURL = '%PUBURLPATH%/%SYSTEMWEB%/CustomMaketextPlugin';
    my $styles = "<link rel='stylesheet' type='text/css' media='all' href='%PUBURLPATH%/%SYSTEMWEB%/FontAwesomeContrib/css/font-awesome.min.css?version=$RELEASE' /><link rel='stylesheet' type='text/css' media='all' href='%PUBURLPATH%/%SYSTEMWEB%/CustomMaketextPlugin/css/ui.css' />";
    Foswiki::Func::addToZone( 'head', 'CustomMaketextPlugin::STYLES', $styles);

    Foswiki::Plugins::JQueryPlugin::createPlugin( 'jqp::sweetalert2' );
    Foswiki::Plugins::JQueryPlugin::createPlugin( 'jqp::blockui' );

    my $scripts = '<script type="text/javascript" src="'.$pluginURL.'/js/ui.js"></script>';
  Foswiki::Func::addToZone('script', 'CustomMaketextPlugin::SCRIPTS', $scripts, "JQUERYPLUGIN::FOSWIKI, JQUERYPLUGIN::FOSWIKI::PREFERENCES, JQUERYPLUGIN::UI::AUTOCOMPLETE, JQUERYPLUGIN::JQP::UNDERSCORE JQUERYPLUGIN::JQP::SWEETALERT2, JavascriptFiles/strikeone" );
    #check if web exist
    my $path = "$Foswiki::cfg{LocalesDir}/$web/";
    unless(-d $path){
        Foswiki::Func::writeWarning("$path does not exist");
        return '<div class="cmaketext"><form method="POST" action="%SCRIPTURL{rest}%/CustomMaketextPlugin/createweb" enctype="application/x-www-form-urlencoded"><p>'.$web.'-Web Does not exist.</p><input type="hidden" name="web" value="'.$web.'"><input type="submit" class="btn-primary saveall" value="%MAKETEXT{"Create Web"}%"></form></div>';
    }

    my ( $translations, $languages ) = _readPOs($web);
    my $html = '<div class="cmaketext">'._generateInfoText();
    $html .= _generateLanguageSelect($web,$languages);
    $html .= _generateInputs($translations,$languages).'</div>';


    return $html;
}
sub _readPOs{
    my ( $web ) = @_;
    my $res = '';
    my $translations = {};
    my $languages = {};

    # search po files
    my $path = "$Foswiki::cfg{LocalesDir}/$web/";
    opendir (DIR, $path) or die $!;
     while (my $file = readdir(DIR)) {
        next unless $file =~ m/\.po$/;
        my $href = Locale::PO->load_file_ashash("$path/$file");
        foreach my $f ( keys %$href ) {
            my $po = $href->{$f};
            next unless defined $po->{msgid};
            $translations->{ Encode::decode_utf8($po->{msgid}) } -> {$file}-> {str} = Encode::decode_utf8($po->{msgstr});
            $translations->{ Encode::decode_utf8($po->{msgid}) } -> {$file}-> {com} = Encode::decode_utf8($po->{comment});
            $languages->{$file} = 1;
        }
    }
    return ($translations, $languages);
}
sub _generateInfoText{
    return '<br/>%MAKETEXT{"On this page you can create custom translations for each language, which is activated."}%<br/><br/>';
}
sub _generateLanguageSelect{
    my ( $web, $languages ) = @_;
    # my $allLanguagesStr = $Foswiki::cfg{CustomMaketextPlugin}{Languages} || '';
    # Foswiki::Func::writeWarning($this->i18n->enabled_languages());
    my @allLanguages = Foswiki::I18N::available_languages();
    # my @allLanguages = split "," , $allLanguagesStr;

    return unless(scalar @allLanguages >0);

    my $res = '<form method="POST" action="%SCRIPTURL{rest}%/CustomMaketextPlugin/addlanguage" enctype="application/x-www-form-urlencoded">';
    $res .= '<input type="hidden" name="web" value="'.$web.'"><select name="language">';
    my $count = 0;
    foreach (@allLanguages){
        my $lang = $_.'.po';
        unless (exists %$languages->{$lang}){
            $count++;
            $res .= '<option value="'.$lang.'">'.$lang.'</option>';
        }
    }
    $res .= '</select><input type="Submit" class="btn-primary addlanguage" value="%MAKETEXT{"Add language"}%" /><br/></form>';
    if($count == 0){
        return "<span>%MAKETEXT{\"All languages are visible. To add new, activate language in bin/configure 'Internationalisation'\"}%</span>";
    }else{
        return $res;
    }
}
sub _generateInputs{
    my ( $translations, $languages ) = @_;
    my $res = '<form id="removeLangForm" method="POST" action="%SCRIPTURL{rest}%/CustomMaketextPlugin/removelanguage" enctype="application/x-www-form-urlencoded"><input type="hidden" id="removeLangField" name="language" value=""></form>';
    $res .= '<form method="POST" action="%SCRIPTURL{rest}%/CustomMaketextPlugin/save" enctype="application/x-www-form-urlencoded">';
    $res .= '<br/><br/><table class="tablesorter custom"><thead><tr><th>%MAKETEXT{"Comment"}%</th><th>en</th>';
    foreach my $lang ( sort {lc $a cmp lc $b} keys %$languages){
        $res .= '<th><span>' . $lang;
        $res .= '</span><i data-lang="'.$lang.'" class="fa fa-trash remove-lang" aria-hidden="true"></i>';
        $res .= '</th>';
    }
    $res .= '<th><span>%MAKETEXT{"Action"}%</span></th></tr></thead><tbody class="pobody">';
    my $count = 0;
    foreach my $msgid ( sort {lc $a cmp lc $b} keys %$translations ) {
        my $msgid_norm = $msgid;
        $msgid_norm =~ s/"//g;
        my $comment = '';
        my $inputs = '';
        foreach my $lang ( sort {lc $a cmp lc $b} keys %$languages){
            if ($comment eq '' && $translations->{$msgid}->{$lang}->{com} ne '') {
                $comment = $translations->{$msgid}->{$lang}->{com};
            }
            my $str = $translations->{$msgid}->{$lang}->{str};
            $str =~ s/"//g;
            $inputs .=  '<td style="display: table-cell;padding: 1em;"><literal><input type="text" name="'.$lang.'_'.$count.'" value="'.$str.'"/></literal></td>';
        }
        my $style = ($msgid_norm eq '')? 'display: none;' : '';
        $res .= '<tr data-count="'.$count.'" style="'.$style.'"><td><input type="text" name="'.$count.'_com" value="' . $comment . '"/></td>';
        $res .= '<td><input type="text" name="'.(($msgid_norm eq '')? $count.'_head' : $count).'_str" value="' . $msgid_norm . '"/></td>' . $inputs;
        $res .= '<td style="text-align: center;"><i class="fa fa-trash remove-msgid" aria-hidden="true"></i></td></tr>';
        $comment = '';
        $inputs = '';
        $count ++;
    }
    $res .= '</tbody></table>';
    $res .= '<br/><i style="color:green; cursor: pointer;" class="fa fa-plus addline" aria-hidden="true">%MAKETEXT{"Add line"}%</i><br/><br/>';
    $res .= '<input type="submit" value="%MAKETEXT{"Save"}%" class="btn-primary saveall"/></form>';
    # Add Reload button if allowed
    if (_reloadAllowed()) {
        $res .= '<input type="submit" value="%MAKETEXT{"Reload Webserver"}%" class="btn-primary reloadhttpd"/></form>';
    }
    return $res;
}
sub _restSave{
    my ($session, $subject, $verb, $response) = @_;
    my $q = $session->{request};
    my $web = Foswiki::Func::getPreferencesValue("CUSTOMMAKETEXT_WEB") || 'ZZCustom';

    my ($oldTranslations, $languages) = _readPOs($web);;
    foreach my $lang (sort {lc $a cmp lc $b} keys %$languages){
        my $file = "$Foswiki::cfg{LocalesDir}/$web/$lang";
        # loop all language-translations
        my $pos = {};
        my $count = 0;
        while($count > -1){
            my $msgid = $q->param($count.'_str');
            my $isHead = $q->param($count.'_head_str');
            unless(defined $isHead){
                unless(defined $msgid){
                    $count = -1;
                    last;
                }
            }
            my $msgstr = $q->param($lang.'_'.$count);
            my $msgcom = $q->param($count.'_com');
            unless(defined $msgid){
                # $msgstr = $defHeader;
                my $date = localtime;
                $msgstr =~ s/(PO-Revision-Date: )(.*?)(\\n)/$1$date$3/;
                $msgstr =~ s/\\n/\n/g;
                $msgid = "";
            }
            $pos->{$count} = new Locale::PO(-msgid=>Encode::encode_utf8($msgid), -msgstr=> Encode::encode_utf8($msgstr), -comment=> Encode::encode_utf8($msgcom));
            $count ++;
        }
        Locale::PO->save_file_fromhash($file, $pos);
        $pos = {};
    }
    $q->param( 'redirectto' => Foswiki::Func::getScriptUrl( 'System', 'CustomizeZZCustom', 'view' ) );
    return undef;
}
sub _restcreateWebDir{
    my ($session, $subject, $verb, $response) = @_;
    my ($session, $subject, $verb, $response) = @_;
    my $q = $session->{request};
    my $web = $q->param('web');
    my $file = "$Foswiki::cfg{LocalesDir}/$web";
    unless(mkdir $file) {
        die "Unable to create $file\n";
    }
    $q->param( 'redirectto' => Foswiki::Func::getScriptUrl( 'System', 'CustomizeZZCustom', 'view' ) );
    return undef;
}
sub _restAddLanguage{
    my ($session, $subject, $verb, $response) = @_;
    my $q = $session->{request};
    my $language = $q->param('language');
    return unless defined $language;
    my $web = Foswiki::Func::getPreferencesValue("CUSTOMMAKETEXT_WEB") || 'ZZCustom';
    my $defHeader = $Foswiki::cfg{CustomMaketextPlugin}{Header} || $DEFAULTHEADER;
    # $defHeader =~ s/\\n//g;
    my $date = localtime;
    $defHeader =~ s/(\"PO-Revision-Date:).*?(\")/$1$date$2/;
    my $langHeader = $language;
    $langHeader =~ s/\.po//;
    $defHeader =~ s/LANG/$langHeader/g;
    $defHeader =~ s/POREVISION/$date/;
    $defHeader =~ s/CREATED/$date/;

    my $file = "$Foswiki::cfg{LocalesDir}/$web/$language";
    my $po = new Locale::PO(-msgid=>'', -msgstr=> $defHeader, -comment=>'# CustomMaketextPlugin translation\n'.
        '# Translators:\n'.
        '# ModellAachen');
    Locale::PO->save_file_fromhash($file,{0=>$po});

    $q->param( 'redirectto' => Foswiki::Func::getScriptUrl( 'System', 'CustomizeZZCustom', 'view' ) );
    return undef;
}
sub _restReloadHttpd {
    my ($session, $subject, $verb, $response) = @_;
    my $q = $session->{request};
    if (_reloadAllowed()) {
        Foswiki::Sandbox->sysCommand(
            ($Foswiki::cfg{CustomMaketextPlugin}{ReloadCommand} || 'sudo service apache2 reload')
        );
        return 200;
    }
    return 403;
}
sub _restRemoveLanguage{
    my ($session, $subject, $verb, $response) = @_;
    my $q = $session->{request};
    my $language = $q->param('language');
    my $web = Foswiki::Func::getPreferencesValue("CUSTOMMAKETEXT_WEB") || 'ZZCustom';
    my $file = "$Foswiki::cfg{LocalesDir}/$web/$language";
    if(-f $file){
        unlink $file;
    }
    $q->param( 'redirectto' => Foswiki::Func::getScriptUrl( 'System', 'CustomizeZZCustom', 'view' ) );
    return undef;
}
1;

__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Author: IngoKruetzen

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
