#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2012 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

## Test that archiving a post works, and checking side effects like updating
## lastPost information in the Thread, and CS.

use strict;
use WebGUI::Test;
use WebGUI::Session;
use Test::More tests => 13; # increment this value for each test you create
use WebGUI::Asset::Wobject::Collaboration;
use WebGUI::Asset::Post;
use WebGUI::Asset::Post::Thread;

my $session = WebGUI::Test->session;

# Do our work in the import node
my $node = WebGUI::Asset->getImportNode($session);

# Grab a named version tag
my $versionTag = WebGUI::VersionTag->getWorking($session);
$versionTag->set({name=>"Collab setup"});

# Need to create a Collaboration system in which the post lives.
my $addArgs = { skipAutoCommitWorkflows => 1, skipNotification => 1 };

my $collab = $node->addChild({className => 'WebGUI::Asset::Wobject::Collaboration', });

# finally, add posts and threads to the collaboration system

my $first_thread = $collab->addChild(
    { className   => 'WebGUI::Asset::Post::Thread', },
    undef, 
    WebGUI::Test->webguiBirthday, 
    $addArgs,
);
$first_thread->setSkipNotification;

my $second_thread = $collab->addChild(
    { className   => 'WebGUI::Asset::Post::Thread', },
    undef, 
    WebGUI::Test->webguiBirthday, 
    $addArgs,
);
$second_thread->setSkipNotification;

##Thread 1, Post 1 => t1p1
my $t1p1 = $first_thread->addChild(
    { className   => 'WebGUI::Asset::Post', },
    undef, 
    WebGUI::Test->webguiBirthday, 
    $addArgs,
);
$t1p1->setSkipNotification;

my $t1p2 = $first_thread->addChild(
    { className   => 'WebGUI::Asset::Post', },
    undef, 
    WebGUI::Test->webguiBirthday + 1, 
    $addArgs
);
$t1p2->setSkipNotification;

my $past = time()-15;

my $t2p1 = $second_thread->addChild(
    { className   => 'WebGUI::Asset::Post', },
    undef, 
    $past, 
    $addArgs,
);
$t2p1->setSkipNotification;

my $t2p2 = $second_thread->addChild(
    { className   => 'WebGUI::Asset::Post', },
    undef, undef,
    $addArgs,
);
$t2p2->setSkipNotification;

$versionTag->commit();
WebGUI::Test->addToCleanup($versionTag);

foreach my $asset ($collab, $t1p1, $t1p2, $t2p1, $t2p2, $first_thread, $second_thread, ) {
    $asset = $asset->cloneFromDb;
}

is $collab->getChildCount, 2, 'collab has correct number of children';

is $collab->lastPostId,   $t2p2->getId, 'lastPostId set in collab';
is $collab->lastPostDate, $t2p2->creationDate, 'lastPostDate, too';

$t2p2->setStatusArchived;
is $t2p2->status, 'archived', 'setStatusArchived set the post to be archived';

$second_thread = $second_thread->cloneFromDb;
is $second_thread->lastPostId,   $t2p1->getId, '.. updated lastPostId in the thread';
is $second_thread->lastPostDate, $t2p1->creationDate, '... lastPostDate, too';

$collab = $collab->cloneFromDb;
is $collab->lastPostId,   $t2p1->getId, '.. updated lastPostId in the CS';
is $collab->lastPostDate, $t2p1->creationDate, '... lastPostDate, too';

$t2p2->setStatusUnarchived;
is $t2p2->status, 'approved', 'setStatusUnarchived sets the post back to approved';

$second_thread = $second_thread->cloneFromDb;
is $second_thread->lastPostId,   $t2p2->getId, '.. updated lastPostId in the thread';
is $second_thread->lastPostDate, $t2p2->creationDate, '... lastPostDate, too';

$collab = $collab->cloneFromDb;
is $collab->lastPostId,   $t2p2->getId, '.. updated lastPostId in the CS';
is $collab->lastPostDate, $t2p2->creationDate, '... lastPostDate, too';

#vim:ft=perl
