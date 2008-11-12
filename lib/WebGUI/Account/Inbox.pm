package WebGUI::Account::Inbox;

use strict;

use WebGUI::Form;
use WebGUI::Exception;
use WebGUI::International;
use WebGUI::Pluggable;
use WebGUI::Utility;
use base qw/WebGUI::Account/;

=head1 NAME

Package WebGUI::Account::Inbox

=head1 DESCRIPTION

This is the class which is used to display a users's inbox

=head1 SYNOPSIS

 use WebGUI::Account::Inbox;

=head1 METHODS

These subroutines are available from this package:

=cut


#-------------------------------------------------------------------

=head2 appendCommonVars ( var, inbox )

    Appends common template variables that all inbox templates use
    
=head3 var

    The hash reference to append template variables to

=head3 inbox

    The instance of the inbox currently being worked with.

=cut

sub appendCommonVars {
    my $self    = shift;
    my $var     = shift;
    my $inbox   = shift;
    my $session = $self->session;
    my $user    = $session->user;

    $var->{'user_full_name'      } = $user->getWholeName;
    $var->{'user_member_since'   } = $user->dateCreated;
    $var->{'view_profile_url'    } = $user->getProfileUrl;
    $var->{'view_inbox_url'      } = $self->getUrl("module=inbox;do=view");
    $var->{'view_invitations_url'} = $self->getUrl("module=inbox;do=manageInvitations");
    $var->{'unread_message_count'} = $inbox->getUnreadMessageCount;
    
}

#-------------------------------------------------------------------

=head2 canView ( )

    Returns whether or not the user can view the inbox tab

=cut

sub canView {
    my $self    = shift;
    return ($self->session->form->get("uid") eq ""); 
}

#-------------------------------------------------------------------

=head2 editSettingsForm ( )

  Creates form elements for user settings page custom to this account module

=cut

sub editSettingsForm {
    my $self    = shift;
    my $session = $self->session;
    my $setting = $session->setting;
    my $i18n    = WebGUI::International->new($session,'Account_Inbox');
    my $f       = WebGUI::HTMLForm->new($session);

    $f->template(
		name      => "inboxStyleTemplateId",
		value     => $self->getStyleTemplateId,
		namespace => "style",
		label     => $i18n->get("inbox style template label"),
        hoverHelp => $i18n->get("inbox style template hoverHelp")
	);
	$f->template(
		name      => "inboxLayoutTempalteId",
		value     => $self->getLayoutTemplateId,
		namespace => "Account/Layout",
		label     => $i18n->get("inbox layout template label"),
        hoverHelp => $i18n->get("inbox layout template hoverHelp")
	);
	$f->template(
        name      => "inboxViewTemplateId",
        value     => $self->getViewTemplateId,
        namespace => "Account/Inbox/View",
        label     => $i18n->get("inbox view template label"),
        hoverHelp => $i18n->get("inbox view template hoverHelp")
	);
    $f->template(
        name      => "inboxViewMessageTemplateId",
        value     => $self->getViewMessageTemplateId,
        namespace => "Account/Inbox/ViewMessage",
        label     => $i18n->get("inbox view message template label"),
        hoverHelp => $i18n->get("inbox view message template hoverHelp")
	);
    $f->template(
        name      => "inboxSendMessageTemplateId",
        value     => $self->getSendMessageTemplateId,
        namespace => "Account/Inbox/SendMessage",
        label     => $i18n->get("inbox send message template label"),
        hoverHelp => $i18n->get("inbox send message template hoverHelp")
	);
    $f->template(
        name      => "inboxMessageConfirmationTemplateId",
        value     => $self->getMessageConfirmTemplateId,
        namespace => "Account/Inbox/Confirm",
        label     => $i18n->get("inbox message confirm template label"),
        hoverHelp => $i18n->get("inbox message confirm template hoverHelp")
	);
    $f->template(
        name      => "inboxErrorTemplateId",
        value     => $self->getInboxErrorTemplateId,
        namespace => "Account/Inbox/Error",
        label     => $i18n->get("inbox error message template label"),
        hoverHelp => $i18n->get("inbox error message template hoverHelp")
	);
    $f->template(
        name      => "inboxManageInvitationsTemplateId",
        value     => $self->getManageInvitationsTemplateId,
        namespace => "Account/Inbox/ManageInvitations",
        label     => $i18n->get("inbox manage invitations template label"),
        hoverHelp => $i18n->get("inbox manage invitations template hoverHelp")
	);
    $f->template(
        name      => "inboxInvitationErrorTemplateId",
        value     => $self->getInvitationErrorTemplateId,
        namespace => "Account/Inbox/Error",
        label     => $i18n->get("invitation error message template label"),
        hoverHelp => $i18n->get("invitation error message template hoverHelp")
	); 

    return $f->printRowsOnly;
}

#-------------------------------------------------------------------

=head2 editSettingsFormSave ( )

  Creates form elements for user settings page custom to this account module

=cut

sub editSettingsFormSave {
    my $self    = shift;
    my $session = $self->session;
    my $setting = $session->setting;
    my $form    = $session->form;

    #Messages Settings
    $setting->set("inboxStyleTemplateId", $form->process("inboxStyleTemplateId","template"));
    $setting->set("inboxLayoutTempalteId", $form->process("inboxLayoutTempalteId","template"));
    $setting->set("inboxViewTemplateId", $form->process("inboxViewTemplateId","template"));
    $session->set("inboxViewMessageTemplateId",$form->process("inboxViewMessageTemplateId","template"));
    $session->set("inboxSendMessageTemplateId",$form->process("inboxSendMessageTemplateId","template"));
    $session->set("inboxMessageConfirmationTemplateId",$form->process("inboxMessageConfirmationTemplateId","template"));
    $session->set("inboxErrorTemplateId",$form->process("inboxErrorTemplateId","template"));
    #Invitations Settings
    $session->set("inboxManageInvitationsTemplateId",$form->process("inboxManageInvitationsTemplateId","template"));
    $session->set("inboxInvitationErrorTemplateId",$form->process("inboxInvitationErrorTemplateId","template"));
}

#-------------------------------------------------------------------

=head2 getInboxErrorTemplateId ( )

This method returns the template ID for inbox errors.

=cut

sub getInboxErrorTemplateId {
    my $self = shift;
    return $self->session->setting->get("inboxErrorTemplateId") || "ErEzulFiEKDkaCDVmxUavw";
}


#-------------------------------------------------------------------

=head2 getInvitationErrorTemplateId ( )

This method returns the template ID for invitation errors.

=cut

sub getInvitationErrorTemplateId {
    my $self = shift;
    return $self->session->setting->get("inboxInvitationErrorTemplateId") || "5A8Hd9zXvByTDy4x-H28qw";
}

#-------------------------------------------------------------------

=head2 getLayoutTemplateId ( )

This method returns the template ID for the account layout.

=cut

sub getLayoutTemplateId {
    my $self = shift;
    return $self->session->setting->get("inboxLayoutTempalteId") || $self->SUPER::getLayoutTemplateId;
}

#-------------------------------------------------------------------

=head2 getManageInvitationsTemplateId ( )

This method returns the template ID for the invitations manage screen.

=cut

sub getManageInvitationsTemplateId {
    my $self = shift;
    return $self->session->setting->get("inboxManageInvitationsTemplateId") || "1Q4Je3hKCJzeo0ZBB5YB8g";
}

#-------------------------------------------------------------------

=head2 getMessageConfirmTemplateId ( )

This method returns the template ID for message confirmations.

=cut

sub getMessageConfirmTemplateId {
    my $self = shift;
    return $self->session->setting->get("inboxMessageConfirmationTemplateId") || "DUoxlTBXhVS-Zl3CFDpt9g";
}


#-------------------------------------------------------------------

=head2 getSendMessageTemplateId ( )

This method returns the template ID for the send message view.

=cut

sub getSendMessageTemplateId {
    my $self = shift;
    return $self->session->setting->get("inboxSendMessageTemplateId") || "6uQEULvXFgCYlRWnYzZsuA";
}

#-------------------------------------------------------------------

=head2 getStyleTemplateId ( )

This method returns the template ID for the main style.

=cut

sub getStyleTemplateId {
    my $self = shift;
    return $self->session->setting->get("inboxStyleTemplateId") || $self->SUPER::getStyleTemplateId;
}

#-------------------------------------------------------------------

=head2 getUserProfileUrl ( userId )

This method stores a reference of user profile URLs to prevent us from having to instantiate
the same users over and over as the nature of an inbox is to have multiple messages from the same user.

=cut

sub getUserProfileUrl {
    my $self   = shift;
    my $userId = shift;


    unless ($self->store->{$userId}) {
        $self->store->{$userId} = WebGUI::User->new($self->session,$userId)->getProfileUrl;
    }
    return $self->store->{$userId};
}

#-------------------------------------------------------------------

=head2 getViewMessageTemplateId ( )

This method returns the id for the view message template.

=cut

sub getViewMessageTemplateId {
    my $self = shift;
    return $self->session->setting->get("inboxViewMessageTemplateId") || "0n4HtbXaWa_XJHkFjetnLQs";
}

#-------------------------------------------------------------------

=head2 getViewTemplateId ( )

This method returns the template ID for the main view.

=cut

sub getViewTemplateId {
    my $self = shift;
    return $self->session->setting->get("inboxViewTemplateId") || "c8xrwVuu5QE0XtF9DiVzLw";
}

#-------------------------------------------------------------------

=head2 www_deleteMessage ( )

Deletes a single messages passed in

=cut

sub www_deleteMessage {
    my $self    = shift;
    my $session = $self->session;

    my $messageId = $session->form->get("messageId");
    my $inbox     = WebGUI::Inbox->new($session);
    my $message   = $inbox->getMessage($messageId);
    
    if (!(defined $message) || !$inbox->canRead($message)) {
        #View will handle displaying these errors
        return $self->www_viewMessage;
    }

    #Get the next message to display
    my $displayMessage = $inbox->getNextMessage($message);
    unless (defined $displayMessage) {
        #No more messages - try to get the previous message
        $displayMessage = $inbox->getPreviousMessage($message);
        unless (defined $displayMessage) {
            #This is the last message in the inbox - delete it and return to inbox
            $message->delete;
            return $self->www_view();
        }
    }
    $message->delete;
    
    return $self->www_viewMessage($displayMessage->getId);
}

#-------------------------------------------------------------------

=head2 www_deleteMessages ( )

Deletes a list of messages selected for the current user

=cut

sub www_deleteMessages {
    my $self    = shift;
    my $session = $self->session;

    my @messages = $session->form->process("message","checkList");

    foreach my $messageId (@messages) {
        my $message = WebGUI::Inbox::Message->new($session, $messageId);
        $message->delete;
    }

    return $self->www_view();
}

#-------------------------------------------------------------------

=head2 www_manageInvitations ( )

The page on which users can manage their friends requests

=cut

sub www_manageInvitations {
    my $self      = shift;
    my $session   = $self->session;
    my $user      = $session->user;

    my $var       = {};

    #Add common template variable for displaying the inbox
    my $inbox     = WebGUI::Inbox->new($session); 
    $self->appendCommonVars($var,$inbox);

    return $self->processTemplate($var,$self->getManageInvitationsTemplateId);
}

#-------------------------------------------------------------------

=head2 www_sendMessage ( )

The page on which users send or reply to messages

=cut

sub www_sendMessage {
    my $self         = shift;
    my $session      = $self->session;
    my $form         = $session->form;
    my $fromUser     = $session->user;
    my $displayError = shift;
    my $toUser       = undef;
    my $var          = {};

    #Add any error passed in to be displayed if the form reloads
    $var->{'message_display_error'}  = $displayError;

    #Add common template variable for displaying the inbox
    my $inbox     = WebGUI::Inbox->new($session); 
    $self->appendCommonVars($var,$inbox);
    
    my $messageId = $form->get("messageId");
    my $userId    = $form->get("userId");
    my $pageUrl   = $session->url->page;
    my $backUrl   = $session->env->get("HTTP_REFERER") || $var->{'view_inbox_url'};
    my $errorMsg  = "";

    if($messageId) {
        #This is a reply to a message - automate who the user is
        my $message = $inbox->getMessage($messageId);
        
        #Handle Errors
        if (!(defined $message)) {
            #Message doesn't exist
            my $i18n  = WebGUI::International->new($session,'Account_Inbox');
            $errorMsg = $i18n->get("message does not exist");        
        }
        elsif (!$inbox->canRead($message)) {
            #User trying to reply to message that they have not been sent.
            my $i18n  = WebGUI::International->new($session,'Account_Inbox');
            $errorMsg = $i18n->get("no reply error");
        }
        elsif($message->get("status") eq "completed" || $message->get("status") eq "pending") {
            #User trying to reply to system message
            my $i18n  = WebGUI::International->new($session,'Account_Inbox');
            $errorMsg = $i18n->get("system message error");
        }
        if($errorMsg) {
            return $self->showError($var,$errorMsg,$backUrl,$self->getInboxErrorTemplateId);
        }

        #Otherwise you should be able to reply to anyone who sent you a message    
        $toUser = WebGUI::User->new($session,$message->get("sentBy"));
        $var->{'isReply'        } = "true";
        $var->{'message_to'     } = $toUser->getWholeName;
        $var->{'message_subject'} = $message->get("subject");
    }
    elsif($userId) {
        #This is a private message to a user - check user private message settings

        #Handle Errors
        $toUser = WebGUI::User->new($session,$userId);
        if($toUser->isVisitor || !$toUser->acceptsPrivateMessages($fromUser->userId)) {
            #Trying to send messages to the visitor or a user that doesn't exist
            my $i18n  = WebGUI::International->new($session,'Account_Inbox');
            $errorMsg = $i18n->get("blocked error");
        }
        elsif($toUser->userId eq $fromUser->userId) {
            #Trying to send a message to yourself
            my $i18n  = WebGUI::International->new($session,'Account_Inbox');
            $errorMsg = $i18n->get("no self error");
        }
        if($errorMsg) {
            return $self->showError($var,$errorMsg,$backUrl,$self->getInboxErrorTemplateId);
        }
        
        $var->{'isPrivateMessage'} = "true";
        $var->{'message_to'      } = $toUser->getWholeName;
    }
    else {
        #This is a new message
        $var->{'isNew'     } = "true";
        
        my $friends           = $fromUser->friends->getUserList;
        my @checkedFriends    = ();
        my @friendsChecked    = $form->process("friend","checkList");
        my $activeFriendCount = 0;
        #Append this users friends to the template
        my @friendsLoop = ();
        foreach my $friendId (keys %{$friends}) {
            my $friend     = WebGUI::User->new($session,$friendId);
            #This friend has private messages turned off
            my $disabled   = "disabled";
            if($friend->acceptsPrivateMessages($fromUser->userId)) {
                $disabled  = "";
                $activeFriendCount++;
            }
            my $fname      = $friend->profileField("firstName");
            my $lname      = $friend->profileField("lastName");
            my $wholeName  = "";
            $wholeName     = $fname." ".$lname if($fname && $lname);

            my $isChecked  = WebGUI::Utility::isIn($friendId,@friendsChecked);            
            my $friendHash = {
                'friend_id'        => $friendId,
                'friend_name'      => $friends->{$friendId},
                'friend_wholeName' => $wholeName,
            };

            push(@checkedFriends,$friendHash) if($isChecked);

            $friendHash->{'friend_checkbox'} = WebGUI::Form::checkbox($session,{
                name    => "friend",
                value   => $friendId,
                checked => $isChecked,
                extras  => q{id="friend_}.$friendId.qq{_id" $disabled},
            });

            push (@friendsLoop, $friendHash);
        }
        
        #You can't send new messages if you don't have any friends to send to
        unless($activeFriendCount) {
            my $i18n  = WebGUI::International->new($session,'Account_Inbox');
            $errorMsg = $i18n->get("no friends error");
            return $self->showError($var,$errorMsg,$backUrl,$self->getInboxErrorTemplateId);
        }

        $var->{'friends_loop'       } = \@friendsLoop;
        $var->{'checked_fiends_loop'} = \@checkedFriends;
    }
 
    $var->{'message_from'         }  = $fromUser->getWholeName;
    
    my $subject = $form->get("subject");
    if($subject eq "" && $messageId) {
        $subject = "Re: ".$var->{'message_subject'};
    }

	$var->{'form_subject'     }  = WebGUI::Form::text($session, {
        name   => "subject",
        value  => $subject,
        extras => q{ class="inbox_subject" }
    });

    $var->{'message_body'     } = $form->get('message');
    
    $var->{'form_message_text'}  = WebGUI::Form::textarea($session, {
        name  =>"message",
        value =>$var->{'message_body'} || "",
    });

    $var->{'form_message_rich'}  = WebGUI::Form::HTMLArea($session, {
        name  => "message",
        value => $var->{'message_body'} || "",
        width => "600",
    });
    
    $var->{'form_header'      }  = WebGUI::Form::formHeader($session,{
        action => $self->getUrl("module=inbox;do=sendMessageSave;messageId=$messageId;userId=$userId"),
        extras => q{name="messageForm"}
    });
    
    $var->{'submit_button'    }  = WebGUI::Form::submit($session,{});
    $var->{'form_footer'      }  = WebGUI::Form::formFooter($session, {});
    $var->{'back_url'         }  = $backUrl;

    return $self->processTemplate($var,$self->getSendMessageTemplateId);
}

#-------------------------------------------------------------------

=head2 www_sendMessageSave ( )

Sends the message created by the user

=cut

sub www_sendMessageSave {
    my $self      = shift;
    my $session   = $self->session;
    my $form      = $session->form;
    my $fromUser  = $session->user;
    my $var       = {};
    my $errorMsg  = "";
    my @toUsers   = ();

    #Add common template variable for displaying the inbox
    my $inbox     = WebGUI::Inbox->new($session); 
    
    my $messageId = $form->get("messageId");
    my $userId    = $form->get("userId");
    my @friends   = $form->get("friend","checkList");    
    push (@friends, $userId) if ($userId);

    my $hasError  = 0;

    my $subject   = $form->get("subject");
    my $message   = $form->get("message");

    #Check for hacker errors / set who the message is going to
    if($messageId) {
        #This is a reply to a message - automate who the user is
        my $message = $inbox->getMessage($messageId);
        #Handle Errors
        if (!(defined $message)
                || !$inbox->canRead($message)
                || $message->get("status") eq "completed"
                || $message->get("status") eq "pending") {
            $hasError = 1;
        }
        push(@toUsers,$message->get("sentBy"));
        $message->setStatus("replied");
    }
    elsif(scalar(@friends)) {
        #This is a private message to a user - check user private message settings
        foreach my $userId (@friends) {
            my $toUser = WebGUI::User->new($session,$userId);
            if($toUser->isVisitor
                    || !$toUser->acceptsPrivateMessages($fromUser->userId)
                    || $toUser->userId eq $fromUser->userId) {
                $hasError = 1;
            }
            push(@toUsers,$userId);
        }
    }

    #Check for client errors
    if($subject eq "") {
        my $i18n  = WebGUI::International->new($session,'Account_Inbox');
        $errorMsg = $i18n->get("no subject error");
        $hasError = 1;
    }
    elsif($message eq "") {
        my $i18n  = WebGUI::International->new($session,'Account_Inbox');
        $errorMsg = $i18n->get("no message error");
        $hasError = 1;
    }
    elsif(scalar(@toUsers) == 0) {
        my $i18n  = WebGUI::International->new($session,'Account_Inbox');
        $errorMsg = $i18n->get("no user error");
        $hasError = 1;
    }

    #Let sendMessage deal with displaying errors
    return $self->www_sendMessage($errorMsg) if $hasError;

    foreach my $uid (@toUsers) {
        $inbox->addMessage({
            message => $message,
            subject => $subject,
            userId  => $uid,
            status  => 'unread',
            sentBy  => $fromUser->userId
        });
    }

    $self->appendCommonVars($var,$inbox);

    return $self->processTemplate($var,$self->getMessageConfirmTemplateId);
}


#-------------------------------------------------------------------

=head2 www_view ( )

The main view page for editing the user's profile.

=cut

sub www_view {
    my $self    = shift;
    my $session = $self->session;
    my $user    = $session->user;
    my $var     = {};
   
    #Deal with sort order
    my $sortBy       = $session->form->get("sortBy") || undef;
    my $sort_url     = ($sortBy)?";sortBy=$sortBy":"";
    
    #Deal with sort direction
    my $sortDir      = $session->form->get("sortDir") || "desc";
    my $sortDir_url  = ";sortDir=".(($sortDir eq "desc")?"asc":"desc");

    #Deal with rows per page
    my $rpp          = $session->form->get("rpp") || 25;
    my $rpp_url      = ";rpp=$rpp";
    
    #Cache the base url
    my $inboxUrl     =  $self->getUrl;

    #Create sortBy headers
    $var->{'subject_url'   } = $inboxUrl.";sortBy=subject".$sortDir_url.$rpp_url;
   	$var->{'status_url'    } = $inboxUrl.";sortBy=status".$sortDir_url.$rpp_url;
    $var->{'from_url'      } = $inboxUrl.";sortBy=sentBy".$sortDir_url.$rpp_url;
    $var->{'dateStamp_url' } = $inboxUrl.";sortBy=dateStamp".$sortDir_url.$rpp_url;
    $var->{'rpp_url'       } = $inboxUrl.$sort_url.";sortDir=".$sortDir;
    
    #Create the paginator
    my $inbox     = WebGUI::Inbox->new($session);
    my $p         = $inbox->getMessagesPaginator($session->user,{
        sortBy        => $sortBy,
        sortDir       => $sortDir,
        baseUrl       => $inboxUrl.$sort_url.";sortDir=".$sortDir.$rpp_url,
        paginateAfter => $rpp
    });
    
    #Export page to template
    my @msg       = ();
    foreach my $row ( @{$p->getPageData} ) {
        my $message = $inbox->getMessage( $row->{messageId} );
        #next if($message->get('status') eq 'deleted');

        my $hash                       = {};
        $hash->{'message_id'         } = $message->getId;
        $hash->{'message_url'        } = $self->getUrl("module=inbox;do=viewMessage;messageId=".$message->getId);
        $hash->{'subject'            } = $message->get("subject");
        $hash->{'status_class'       } = $message->get("status");
        $hash->{'status'             } = $message->getStatus;
        $hash->{'isRead'             } = $message->isRead;
        $hash->{'isReplied'          } = $hash->{'status_class'} eq "replied";
        $hash->{'isPending'          } = $hash->{'status_class'} eq "pending";
        $hash->{'isCompleted'        } = $hash->{'status_class'} eq "completed";
        $hash->{'from_id'            } = $message->get("sentBy");
        $hash->{'from_url'           } = $self->getUserProfileUrl($hash->{'from_id'});  #Get the profile url of this user which may be cached.
        $hash->{'from'               } = $row->{'fullName'};
        $hash->{'dateStamp'          } = $message->get("dateStamp");
	  	$hash->{'dateStamp_formatted'} = $session->datetime->epochToHuman($hash->{'dateStamp'});
        $hash->{'inbox_form_delete'  } = WebGUI::Form::checkbox($session,{
            name  => "message",
            value => $message->getId
        });
	  	push(@msg,$hash);
   	}
    my $msgCount  = $p->getRowCount;
         
   	$var->{'message_loop'        } = \@msg;
    $var->{'has_messages'        } = $msgCount > 0;
    $var->{'message_total'       } = $msgCount;
    $var->{'new_message_url'     } = $self->getUrl("module=inbox;do=sendMessage");
    $var->{'canSendMessages'     } = $user->hasFriends;

    $var->{'inbox_form_start'    } = WebGUI::Form::formHeader($session,{
        action => $self->getUrl("module=inbox;do=deleteMessages")
    });
    $var->{'inbox_form_end'      } = WebGUI::Form::formFooter($session);

    tie my %rpps, "Tie::IxHash";
    %rpps = (25 => "25", 50 => "50", 100=>"100");
    $var->{'message_rpp'  } = WebGUI::Form::selectBox($session,{
        name    =>"rpp",
        options => \%rpps,
        value   => $session->form->get("rpp") || 25,
        extras  => q{onchange="location.href='}.$var->{'rpp_url'}.q{;rpp='+this.options[this.selectedIndex].value"}
    });

    #Append common vars
    $self->appendCommonVars($var,$inbox);
    #Append pagination vars
    $p->appendTemplateVars($var);
    return $self->processTemplate($var,$self->getViewTemplateId);
}

#-------------------------------------------------------------------

=head2 www_viewMessage ( )

The page on which users view their messages

=cut

sub www_viewMessage {
    my $self      = shift;
    my $session   = $self->session;
    my $user      = $session->user;

    my $var       = {};
    my $messageId = shift || $session->form->get("messageId");
    my $errorMsg  = shift;

    my $inbox     = WebGUI::Inbox->new($session);    
    my $message   = $inbox->getMessage($messageId);

    #Add common template variable for displaying the inbox
    $self->appendCommonVars($var,$inbox);
    
    #Handler Errors
    if (!(defined $message)) {
        my $i18n  = WebGUI::International->new($session,'Account_Inbox');
        $errorMsg = $i18n->get("message does not exist");        
    }
    elsif (!$inbox->canRead($message)) { 
        my $i18n  = WebGUI::International->new($session,'Account_Inbox');
        $errorMsg = $i18n->get("no access");
    }

    if($errorMsg) {
        my $backUrl = $var->{'view_inbox_url'};
        return $self->showError($var,$errorMsg,$backUrl,$self->getInboxErrorTemplateId);
    }
    
    $message->setStatus("read") unless ($message->isRead);

    $var->{'message_id'             } = $messageId;
    $var->{'message_subject'        } = $message->get("subject");
    $var->{'message_dateStamp'      } = $message->get("dateStamp");
    $var->{'message_dateStemp_human'} = $session->datetime->epochToHuman($var->{'message_dateStamp'});
    $var->{'message_status'         } = $message->getStatus;
    $var->{'message_body'           } = $message->get("message");

    unless ($var->{'message_body'} =~ /\<a/ig) {
        $var->{'message_body'} =~ s/(http\S*)/\<a href=\"$1\"\>$1\<\/a\>/g;
    }
    unless ($var->{'message_body'} =~ /\<div/ig
                || $var->{'message_body'} =~ /\<br/ig
                || $var->{'message_body'} =~ /\<p/ig) {
        $var->{'message_body'} =~ s/\n/\<br \/\>\n/g;
    }

    #Get the user the message was sent by 
    my $sentBy        = $message->get("sentBy");
    my $from          = WebGUI::User->new($session,$sentBy);
    my $sentByVisitor = 0;
    if ($from->isVisitor) {
        $sentByVisitor = 1;
        $from = WebGUI::User->new($session,3);        
    }
    $var->{'message_from_id'        } = $from->userId; 
    $var->{'message_from'           } = $from->getWholeName;

    #Build the action URLs
    $var->{'delete_url'             } = $self->getUrl("module=inbox;do=deleteMessage;messageId=".$messageId);

    my $status = $message->get("status");
    if($sentBy ne $user->userId
                && !$sentByVisitor
                && $status ne "pending"
                && $status ne "completed" ) {
        $var->{'canReply' } = "true";
        $var->{'reply_url'} = $self->getUrl("module=inbox;do=sendMessage;messageId=".$messageId);
    }

    my $nextMessage = $inbox->getNextMessage($message);
    if( defined $nextMessage ) {
        $var->{'hasNext'         } = "true";
        $var->{'next_message_url'} = $self->getUrl("module=inbox;do=viewMessage;messageId=".$nextMessage->getId);
    }

    my $prevMessage = $inbox->getPreviousMessage($message);
    if(defined $prevMessage) {
        $var->{'hasPrevious'     } = "true";
        $var->{'prev_message_url'} = $self->getUrl("module=inbox;do=viewMessage;messageId=".$prevMessage->getId);
    }

    return $self->processTemplate($var,$self->getViewMessageTemplateId);
}


1;
