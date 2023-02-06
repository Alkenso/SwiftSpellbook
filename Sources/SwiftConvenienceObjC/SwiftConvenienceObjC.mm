//  MIT License
//
//  Copyright (c) 2021 Alkenso (Vladimir Vashurkin)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import "SwiftConvenienceObjC.h"

#include <stdexcept>

#if TARGET_OS_OSX == 1
@interface NSXPCConnection (SwiftConveniencePrivate)
@property (nonatomic, readonly) audit_token_t auditToken;
@end
#endif

@implementation SwiftConvenienceObjC

+ (nullable NSException *)NSException_catching:(void(NS_NOESCAPE ^)(void))block
{
    @try
    {
        block();
        return nil;
    }
    @catch (NSException *exception)
    {
        return exception;
    }
}

+ (nullable NSString *)CppException_catching:(void(NS_NOESCAPE ^)(void))block
{
    try
    {
        block();
        return nil;
    }
    catch (const std::exception& ex)
    {
        const char* reason = ex.what();
        return reason ? @(reason) : @"unknown std::exception";
    }
    catch (...)
    {
        return @"unknown C++ exception";
    }
}

+ (void)throwCppRuntineErrorException:(NSString *)reason
{
    throw std::runtime_error(reason.UTF8String ?: "");
}

#if TARGET_OS_OSX == 1
+ (audit_token_t)NSXPCConnection_auditToken:(NSXPCConnection *)connection
{
    return connection.auditToken;
}
#endif

@end
