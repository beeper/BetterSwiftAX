#ifndef SpaceBridge_h
#define SpaceBridge_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Runtime-resolved SkyLight Space APIs (dlsym / NSClassFromString). Unlike the
// CGS declarations in CGSInternal.h, nothing here links private symbols, so a
// missing symbol or class degrades to the documented failure value.

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

/// Includes unknown/OS Spaces (mask 15), unlike the legacy mask-7 query.
NSArray<NSNumber *> *_Nullable TXTSpacesForWindow(uint32_t windowID);
/// Returns 0 when unavailable.
uint64_t TXTActiveSpace(void);
NSArray<NSDictionary *> *_Nullable TXTCopyManagedDisplaySpaces(void);
/// Reads the intrinsic Space type; -1 means the binding or WindowServer connection is unavailable.
int32_t TXTSpaceType(uint64_t spaceID);
/// Copies Space metadata independently of its type; nil means the read failed.
NSDictionary *_Nullable TXTCopySpaceValues(uint64_t spaceID);

NS_ASSUME_NONNULL_END

#endif /* SpaceBridge_h */
