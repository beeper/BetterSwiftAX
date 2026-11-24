#import "WindowControl.h"

NSArray<NSNumber *> *TXTWindowListCreate(CGWindowListOption option, CGWindowID relativeToWindow) {
    CFArrayRef raw = CGWindowListCreate(option, relativeToWindow);
    if (!raw) {
        return nil;
    }
    CFIndex count = CFArrayGetCount(raw);
    NSMutableArray<NSNumber *> *result = [NSMutableArray arrayWithCapacity:(NSUInteger)count];
    for (CFIndex i = 0; i < count; i++) {
        CGWindowID windowID = (CGWindowID)(uintptr_t)CFArrayGetValueAtIndex(raw, i);
        [result addObject:@(windowID)];
    }
    CFRelease(raw);
    return result;
}

CFArrayRef TXTWindowListCreateDescription(CGWindowID windowID) {
    const void *values[1] = { (const void *)(uintptr_t)windowID };
    CFArrayRef ids = CFArrayCreate(kCFAllocatorDefault, values, 1, NULL);
    if (!ids) {
        return NULL;
    }
    CFArrayRef descriptions = CGWindowListCreateDescriptionFromArray(ids);
    CFRelease(ids);
    return descriptions;
}

OSStatus TXTGetProcessForPID(pid_t pid, ProcessSerialNumber *psn) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return GetProcessForPID(pid, psn);
#pragma clang diagnostic pop
}
