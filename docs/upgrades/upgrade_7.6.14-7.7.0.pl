#!/usr/bin/env perl

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2009 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

our ($webguiRoot);

BEGIN {
    $webguiRoot = "../..";
    unshift (@INC, $webguiRoot."/lib");
}

use strict;
use Getopt::Long;
use WebGUI::Session;
use WebGUI::Storage;
use WebGUI::Asset;


my $toVersion = '7.7.0';
my $quiet; # this line required


my $session = start(); # this line required

# upgrade functions go here
installStoryManagerTables($session);
upgradeConfigFiles($session);

finish($session); # this line required


#----------------------------------------------------------------------------
# Describe what our function does
#sub exampleFunction {
#    my $session = shift;
#    print "\tWe're doing some stuff here that you should know about... " unless $quiet;
#    # and here's our code
#    print "DONE!\n" unless $quiet;
#}

sub installStoryManagerTables {
    my ($session) = @_;
    print "\tAdding Story Manager tables... " unless $quiet;
    my $db = $session->db;
    $db->write(<<EOSTORY);
CREATE TABLE Story (
    assetId      CHAR(22) BINARY NOT NULL,
    revisionDate BIGINT          NOT NULL,
    headline     CHAR(255),
    subtitle     CHAR(255),
    byline       CHAR(255),
    location     CHAR(255),
    highlights   TEXT,
    story        MEDIUMTEXT,
    storageId    CHAR(255),
    photo        LONGTEXT,
    PRIMARY KEY ( assetId, revisionDate )
)
EOSTORY

    $db->write(<<EOARCHIVE);
CREATE TABLE StoryArchive (
    assetId             CHAR(22) BINARY NOT NULL,
    revisionDate        BIGINT          NOT NULL,
    storiesPerFeed      INTEGER,
    storiesPerPage      INTEGER,
    groupToPost         CHAR(22) BINARY,
    templateId          CHAR(22) BINARY,
    storyTemplateId     CHAR(22) BINARY,
    editStoryTemplateId CHAR(22) BINARY,
    archiveAfter        INT(11),
    richEditorId        CHAR(22) BINARY,
    approvalWorkflowId  CHAR(22) BINARY DEFAULT 'pbworkflow000000000003',
    PRIMARY KEY ( assetId, revisionDate )
)
EOARCHIVE

    $db->write(<<EOTOPIC);
CREATE TABLE StoryTopic (
    assetId         CHAR(22) BINARY NOT NULL,
    revisionDate    BIGINT          NOT NULL,
    storiesPer      INTEGER,
    storiesShort    INTEGER,
    storyTemplateId CHAR(22) BINARY,
    PRIMARY KEY ( assetId, revisionDate )
)
EOTOPIC

    print "DONE!\n" unless $quiet;
}

sub upgradeConfigFiles {
    my ($session) = @_;
    print "\tAdding Story Manager assets to config file... " unless $quiet;
    my $config = $session->config;
    $config->addToHash(
        'assets',
        'WebGUI::Asset::Wobject::StoryTopic' => {
            'category' => 'community'
        },
    );
    $config->addToHash(
        'assets',
        "WebGUI::Asset::Wobject::StoryArchive" => {
            "isContainer" => 1,
            "category" => "community"
        },
    );
    print "DONE!\n" unless $quiet;
}



# -------------- DO NOT EDIT BELOW THIS LINE --------------------------------

#----------------------------------------------------------------------------
# Add a package to the import node
sub addPackage {
    my $session     = shift;
    my $file        = shift;

    # Make a storage location for the package
    my $storage     = WebGUI::Storage->createTemp( $session );
    $storage->addFileFromFilesystem( $file );

    # Import the package into the import node
    my $package = WebGUI::Asset->getImportNode($session)->importPackage( $storage );

    # Make the package not a package anymore
    $package->update({ isPackage => 0 });
    
    # Set the default flag for templates added
    my $assetIds
        = $package->getLineage( ['self','descendants'], {
            includeOnlyClasses  => [ 'WebGUI::Asset::Template' ],
        } );
    for my $assetId ( @{ $assetIds } ) {
        my $asset   = WebGUI::Asset->newByDynamicClass( $session, $assetId );
        if ( !$asset ) {
            print "Couldn't instantiate asset with ID '$assetId'. Please check package '$file' for corruption.\n";
            next;
        }
        $asset->update( { isDefault => 1 } );
    }

    return;
}

#-------------------------------------------------
sub start {
    my $configFile;
    $|=1; #disable output buffering
    GetOptions(
        'configFile=s'=>\$configFile,
        'quiet'=>\$quiet
    );
    my $session = WebGUI::Session->open($webguiRoot,$configFile);
    $session->user({userId=>3});
    my $versionTag = WebGUI::VersionTag->getWorking($session);
    $versionTag->set({name=>"Upgrade to ".$toVersion});
    return $session;
}

#-------------------------------------------------
sub finish {
    my $session = shift;
    updateTemplates($session);
    my $versionTag = WebGUI::VersionTag->getWorking($session);
    $versionTag->commit;
    $session->db->write("insert into webguiVersion values (".$session->db->quote($toVersion).",'upgrade',".$session->datetime->time().")");
    $session->close();
}

#-------------------------------------------------
sub updateTemplates {
    my $session = shift;
    return undef unless (-d "packages-".$toVersion);
    print "\tUpdating packages.\n" unless ($quiet);
    opendir(DIR,"packages-".$toVersion);
    my @files = readdir(DIR);
    closedir(DIR);
    my $newFolder = undef;
    foreach my $file (@files) {
        next unless ($file =~ /\.wgpkg$/);
        # Fix the filename to include a path
        $file       = "packages-" . $toVersion . "/" . $file;
        addPackage( $session, $file );
    }
}

#vim:ft=perl
