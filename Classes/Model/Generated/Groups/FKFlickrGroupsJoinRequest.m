//
//  FKFlickrGroupsJoinRequest.m
//  FlickrKit
//
//  Generated by FKAPIBuilder.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com
//
//  DO NOT MODIFY THIS FILE - IT IS MACHINE GENERATED


#import "FKFlickrGroupsJoinRequest.h" 

@implementation FKFlickrGroupsJoinRequest



- (BOOL) needsLogin {
    return YES;
}

- (BOOL) needsSigning {
    return YES;
}

- (FKPermission) requiredPerms {
    return 1;
}

- (NSString *) name {
    return @"flickr.groups.joinRequest";
}

- (BOOL) isValid:(NSError **)error {
    BOOL valid = YES;
	NSMutableString *errorDescription = [[NSMutableString alloc] initWithString:@"You are missing required params: "];
	if(!self.group_id) {
		valid = NO;
		[errorDescription appendString:@"'group_id', "];
	}
	if(!self.message) {
		valid = NO;
		[errorDescription appendString:@"'message', "];
	}
	if(!self.accept_rules) {
		valid = NO;
		[errorDescription appendString:@"'accept_rules', "];
	}

	if(error != NULL) {
		if(!valid) {	
			NSDictionary *userInfo = @{NSLocalizedDescriptionKey: errorDescription};
			*error = [NSError errorWithDomain:FKFlickrKitErrorDomain code:FKErrorInvalidArgs userInfo:userInfo];
		}
	}
    return valid;
}

- (NSDictionary *) args {
    NSMutableDictionary *args = [NSMutableDictionary dictionary];
	if(self.group_id) {
		[args setValue:self.group_id forKey:@"group_id"];
	}
	if(self.message) {
		[args setValue:self.message forKey:@"message"];
	}
	if(self.accept_rules) {
		[args setValue:self.accept_rules forKey:@"accept_rules"];
	}

    return [args copy];
}

- (NSString *) descriptionForError:(NSInteger)error {
    switch(error) {
		case FKFlickrGroupsJoinRequestError_RequiredArgumentsMissing:
			return @"Required arguments missing";
		case FKFlickrGroupsJoinRequestError_GroupDoesNotExist:
			return @"Group does not exist";
		case FKFlickrGroupsJoinRequestError_GroupNotAvailableToTheAccount:
			return @"Group not available to the account";
		case FKFlickrGroupsJoinRequestError_AccountIsAlreadyInThatGroup:
			return @"Account is already in that group";
		case FKFlickrGroupsJoinRequestError_GroupIsPublicAndOpen:
			return @"Group is public and open";
		case FKFlickrGroupsJoinRequestError_UserMustAcceptTheGroupRulesBeforeJoining:
			return @"User must accept the group rules before joining";
		case FKFlickrGroupsJoinRequestError_UserHasAlreadyRequestedToJoinThatGroup:
			return @"User has already requested to join that group";
		case FKFlickrGroupsJoinRequestError_SSLIsRequired:
			return @"SSL is required";
		case FKFlickrGroupsJoinRequestError_InvalidSignature:
			return @"Invalid signature";
		case FKFlickrGroupsJoinRequestError_MissingSignature:
			return @"Missing signature";
		case FKFlickrGroupsJoinRequestError_LoginFailedOrInvalidAuthToken:
			return @"Login failed / Invalid auth token";
		case FKFlickrGroupsJoinRequestError_UserNotLoggedInOrInsufficientPermissions:
			return @"User not logged in / Insufficient permissions";
		case FKFlickrGroupsJoinRequestError_InvalidAPIKey:
			return @"Invalid API Key";
		case FKFlickrGroupsJoinRequestError_ServiceCurrentlyUnavailable:
			return @"Service currently unavailable";
		case FKFlickrGroupsJoinRequestError_WriteOperationFailed:
			return @"Write operation failed";
		case FKFlickrGroupsJoinRequestError_FormatXXXNotFound:
			return @"Format \"xxx\" not found";
		case FKFlickrGroupsJoinRequestError_MethodXXXNotFound:
			return @"Method \"xxx\" not found";
		case FKFlickrGroupsJoinRequestError_InvalidSOAPEnvelope:
			return @"Invalid SOAP envelope";
		case FKFlickrGroupsJoinRequestError_InvalidXMLRPCMethodCall:
			return @"Invalid XML-RPC Method Call";
		case FKFlickrGroupsJoinRequestError_BadURLFound:
			return @"Bad URL found";
  
		default:
			return @"Unknown error code";
    }
}

@end
