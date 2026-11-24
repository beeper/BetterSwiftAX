#import "SpaceBridge.h"

// SkyLight is already loaded: CoreGraphics links it. The classes are looked up by name; this
// declaration type-checks the calls without linking anything. A missing class gives nil, and a
// missing method throws, which the @try blocks turn into the documented failure values.
@protocol TXTSkyLightBridge <NSObject>
- (id)performSynchronousBridgedWindowManagementOperation:(id)operation;
- (void)performAsynchronousBridgedWindowManagementOperation:(id)operation;
- (uint64_t)spaceID;
- (instancetype)initWithOptions:(uint32_t)options values:(NSDictionary *)values;
- (instancetype)initWithSpaceID:(uint64_t)spaceID windows:(NSArray<NSNumber *> *)windows options:(uint32_t)options;
- (instancetype)initWithWindows:(NSArray<NSNumber *> *)windows spaces:(NSArray<NSNumber *> *)spaces;
- (instancetype)initWithWindows:(NSArray<NSNumber *> *)windows spaceID:(uint64_t)spaceID;
- (instancetype)initWithSpaceID:(uint64_t)spaceID;
@end

typedef id<TXTSkyLightBridge> TXTBridgeObject;

static TXTBridgeObject SpaceBridgeAllocate(NSString *className) {
    return [NSClassFromString(className) alloc];
}

static BOOL SpaceBridgeEnqueue(NSObject *bridge, NSString *className, TXTBridgeObject (^initialize)(TXTBridgeObject)) {
    @try {
        TXTBridgeObject operation = initialize(SpaceBridgeAllocate(className));
        if (!operation) return NO;
        [(TXTBridgeObject)bridge performAsynchronousBridgedWindowManagementOperation:operation];
        return YES;
    } @catch (NSException *exception) { return NO; }
}

NSObject *TXTSpaceBridgeCreate(void) {
    @try {
        Class cls = NSClassFromString(@"SLSWindowManagementFallbackBridge");
        if (![cls instancesRespondToSelector:@selector(performSynchronousBridgedWindowManagementOperation:)] ||
            ![cls instancesRespondToSelector:@selector(performAsynchronousBridgedWindowManagementOperation:)]) return nil;
        return [[cls alloc] init];
    } @catch (NSException *exception) { return nil; }
}

static uint64_t SpaceBridgeCreateSpaceWithOptions(NSObject *bridge, uint32_t options, NSDictionary *values) {
    @try {
        TXTBridgeObject operation = [SpaceBridgeAllocate(@"SLSBridgedSpaceCreateOperation") initWithOptions:options values:values];
        if (!operation) return 0;
        return [[(TXTBridgeObject)bridge performSynchronousBridgedWindowManagementOperation:operation] spaceID];
    } @catch (NSException *exception) { return 0; }
}

uint64_t TXTSpaceBridgeCreateSpace(NSObject *bridge, NSDictionary *values) {
    return SpaceBridgeCreateSpaceWithOptions(bridge, 0, values);
}

uint64_t TXTSpaceBridgeCreateUnknownSpace(NSObject *bridge, NSString *uuid) {
    // Option 1 creates an intrinsically unknown Space. A type=3 dictionary
    // with option 0 still creates a managed user Space on current macOS.
    return SpaceBridgeCreateSpaceWithOptions(bridge, 1, @{@"type": @3, @"uuid": uuid});
}

BOOL TXTSpaceBridgeAddWindowToUnknownSpace(NSObject *bridge, uint32_t windowID, uint64_t spaceID) {
    return SpaceBridgeEnqueue(bridge, @"SLSBridgedSpaceAddWindowsAndRemoveFromSpacesOperation", ^(TXTBridgeObject op) {
        return [op initWithSpaceID:spaceID windows:@[@(windowID)] options:0];
    });
}

BOOL TXTSpaceBridgeRemoveWindowFromSpaces(NSObject *bridge, uint32_t windowID, NSArray<NSNumber *> *spaces) {
    return SpaceBridgeEnqueue(bridge, @"SLSBridgedRemoveWindowsFromSpacesOperation", ^(TXTBridgeObject op) {
        return [op initWithWindows:@[@(windowID)] spaces:spaces];
    });
}

BOOL TXTSpaceBridgeMoveWindow(NSObject *bridge, uint32_t windowID, uint64_t spaceID) {
    return SpaceBridgeEnqueue(bridge, @"SLSBridgedMoveWindowsToManagedSpaceOperation", ^(TXTBridgeObject op) {
        return [op initWithWindows:@[@(windowID)] spaceID:spaceID];
    });
}

BOOL TXTSpaceBridgeDestroySpace(NSObject *bridge, uint64_t spaceID) {
    return SpaceBridgeEnqueue(bridge, @"SLSBridgedSpaceDestroyOperation", ^(TXTBridgeObject op) {
        return [op initWithSpaceID:spaceID];
    });
}
