#ifndef SpaceBridge_h
#define SpaceBridge_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// SkyLight's bridged window-management operations, resolved with NSClassFromString.
// The classes are Objective-C only, so unlike the CGS functions in CGSInternal.h
// they cannot be linked; a missing class degrades to the documented failure value.

/// SLSWindowManagementFallbackBridge instance, or nil if unavailable.
NSObject *_Nullable TXTSpaceBridgeCreate(void);
/// Returns 0 on failure.
uint64_t TXTSpaceBridgeCreateSpace(NSObject *bridge, NSDictionary *values);
/// Creates an unknown, unmanaged Space using creation option 1, with no Dock owner metadata. Returns 0 on failure.
uint64_t TXTSpaceBridgeCreateUnknownSpace(NSObject *bridge, NSString *uuid);
/// Enqueues unknown membership addition; existing memberships must be removed separately and verified.
BOOL TXTSpaceBridgeAddWindowToUnknownSpace(NSObject *bridge, uint32_t windowID, uint64_t spaceID);
/// Enqueues membership removal; success means accepted, not independently verified.
BOOL TXTSpaceBridgeRemoveWindowFromSpaces(NSObject *bridge, uint32_t windowID, NSArray<NSNumber *> *spaces);
BOOL TXTSpaceBridgeMoveWindow(NSObject *bridge, uint32_t windowID, uint64_t spaceID);
BOOL TXTSpaceBridgeDestroySpace(NSObject *bridge, uint64_t spaceID);

NS_ASSUME_NONNULL_END

#endif /* SpaceBridge_h */
