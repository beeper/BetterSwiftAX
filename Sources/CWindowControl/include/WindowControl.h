#ifndef WindowControl_h
#define WindowControl_h

#include "CGSInternal.h"
#include <CoreGraphics/CoreGraphics.h>
#include "SpaceBridge.h"

// CGWindowListCreate is unavailable in Swift because its CFArray holds raw CGWindowID
// integers cast to void* rather than CFNumber objects; box them into NSNumber here.
NSArray<NSNumber *> * _Nullable TXTWindowListCreate(CGWindowListOption option, CGWindowID relativeToWindow);
CFArrayRef _Nullable TXTWindowListCreateDescription(CGWindowID windowID);
OSStatus TXTGetProcessForPID(pid_t pid, ProcessSerialNumber * _Nonnull psn);

#endif /* WindowList_h */
