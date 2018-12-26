//
//  NeDBManager.m
//  nedb
//
//  Created by wuxushun on 2018/11/12.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "NeDBManager.h"

#define private_header_path @"nedb"

@implementation NeDBManager

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

- (dispatch_queue_t)methodQueue
{
  return dispatch_queue_create("pe.lum.nedb", DISPATCH_QUEUE_SERIAL);
}

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

RCT_EXPORT_METHOD(exists:(NSString *)filepath
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(__unused RCTPromiseRejectBlock)reject)
{
  BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[self getPrivatePath:filepath]];
  
  resolve([NSNumber numberWithBool:fileExists]);
}

RCT_EXPORT_METHOD(writeFile:(NSString *)filepath
                  contents:(NSString *)contents
                  options:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSData *data = [contents dataUsingEncoding:NSUTF8StringEncoding];;
  
  NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
  
  if ([options objectForKey:@"NSFileProtectionKey"]) {
    [attributes setValue:[options objectForKey:@"NSFileProtectionKey"] forKey:@"NSFileProtectionKey"];
  }
  
  BOOL success = [[NSFileManager defaultManager] createFileAtPath:[self getPrivatePath:filepath] contents:data attributes:attributes];
  
  if (!success) {
    return reject(@"ENOENT", [NSString stringWithFormat:@"ENOENT: no such file or directory, open '%@'", [self getPrivatePath:filepath]], nil);
  }
  
  return resolve(nil);
}

RCT_EXPORT_METHOD(unlink:(NSString*)filepath
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSFileManager *manager = [NSFileManager defaultManager];
  BOOL exists = [manager fileExistsAtPath:[self getPrivatePath:filepath] isDirectory:false];
  
  if (!exists) {
    return reject(@"ENOENT", [NSString stringWithFormat:@"ENOENT: no such file or directory, open '%@'", [self getPrivatePath:filepath]], nil);
  }
  
  NSError *error = nil;
  BOOL success = [manager removeItemAtPath:[self getPrivatePath:filepath] error:&error];
  
  if (!success) {
    return [self reject:reject withError:error];
  }
  
  resolve(nil);
}

RCT_EXPORT_METHOD(appendFile:(NSString *)filepath
                  contents:(NSString *)contents
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSData *data = [contents dataUsingEncoding:NSUTF8StringEncoding];;
  
  NSFileManager *fM = [NSFileManager defaultManager];
  
  if (![fM fileExistsAtPath:[self getPrivatePath:filepath]])
  {
    BOOL success = [[NSFileManager defaultManager] createFileAtPath:[self getPrivatePath:filepath] contents:data attributes:nil];
    
    if (!success) {
      return reject(@"ENOENT", [NSString stringWithFormat:@"ENOENT: no such file or directory, open '%@'", [self getPrivatePath:filepath]], nil);
    } else {
      return resolve(nil);
    }
  }
  
  @try {
    NSFileHandle *fH = [NSFileHandle fileHandleForUpdatingAtPath:[self getPrivatePath:filepath]];
    
    [fH seekToEndOfFile];
    [fH writeData:data];
    
    return resolve(nil);
  } @catch (NSException *e) {
    return [self reject:reject withError:e];
  }
}

RCT_EXPORT_METHOD(readFile:(NSString *)filepath
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[self getPrivatePath:filepath]];
  
  if (!fileExists) {
    return reject(@"ENOENT", [NSString stringWithFormat:@"ENOENT: no such file or directory, open '%@'", [self getPrivatePath:filepath]], nil);
  }
  
  NSError *error = nil;
  
  NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[self getPrivatePath:filepath] error:&error];
  
  if (error) {
    return [self reject:reject withError:error];
  }
  
  if ([attributes objectForKey:NSFileType] == NSFileTypeDirectory) {
    return reject(@"EISDIR", @"EISDIR: illegal operation on a directory, read", nil);
  }
  
  NSData *content = [[NSFileManager defaultManager] contentsAtPath:[self getPrivatePath:filepath]];
  NSString *base64Content = [[NSString alloc] initWithData:content encoding:NSUTF8StringEncoding];
  
  resolve(base64Content);
}

RCT_EXPORT_METHOD(mkdir:(NSString *)filepath
                  options:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSFileManager *manager = [NSFileManager defaultManager];
  
  NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
  
  if ([options objectForKey:@"NSFileProtectionKey"]) {
    [attributes setValue:[options objectForKey:@"NSFileProtectionKey"] forKey:@"NSFileProtectionKey"];
  }
  
  NSError *error = nil;
  BOOL success = [manager createDirectoryAtPath:[self getPrivatePath:filepath] withIntermediateDirectories:YES attributes:attributes error:&error];
  
  if (!success) {
    return [self reject:reject withError:error];
  }
  
  NSURL *url = [NSURL fileURLWithPath:[self getPrivatePath:filepath]];
  
  if ([[options allKeys] containsObject:@"NSURLIsExcludedFromBackupKey"]) {
    NSNumber *value = options[@"NSURLIsExcludedFromBackupKey"];
    success = [url setResourceValue: value forKey: NSURLIsExcludedFromBackupKey error: &error];
    
    if (!success) {
      return [self reject:reject withError:error];
    }
  }
  
  resolve(nil);
}

RCT_EXPORT_METHOD(rename:(NSString *)filepath
                  destPath:(NSString *)destPath
                  options:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSFileManager *manager = [NSFileManager defaultManager];
  
  BOOL isOriginExists = [[NSFileManager defaultManager] fileExistsAtPath:[self getPrivatePath:filepath]];
  if (!isOriginExists) {
    return reject(@"filepath", @"filepath: no filepath found", nil);;
  }
  BOOL isDestExists = [[NSFileManager defaultManager] fileExistsAtPath:[self getPrivatePath:destPath]];
  
  if (isDestExists) {
    NSError *error = nil;
    BOOL success = [manager removeItemAtPath:[self getPrivatePath:destPath] error:&error];
    if (!success) {
      return [self reject:reject withError:error];
    }
  }
  
  NSError *error = nil;
  
  BOOL success = [manager moveItemAtPath:[self getPrivatePath:filepath]
                                  toPath:[self getPrivatePath:destPath]
                                   error:&error];
  
  if (!success) {
    return [self reject:reject withError:error];
  }
  
  if ([options objectForKey:@"NSFileProtectionKey"]) {
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    [attributes setValue:[options objectForKey:@"NSFileProtectionKey"] forKey:@"NSFileProtectionKey"];
    BOOL updateSuccess = [manager setAttributes:attributes ofItemAtPath:[self getPrivatePath:destPath] error:&error];
    
    if (!updateSuccess) {
      return [self reject:reject withError:error];
    }
  }
  
  resolve(nil);
}

- (void)reject:(RCTPromiseRejectBlock)reject withError:(NSError *)error
{
  NSString *codeWithDomain = [NSString stringWithFormat:@"E%@%zd", error.domain.uppercaseString, error.code];
  reject(codeWithDomain, error.localizedDescription, error);
}

- (NSString *)getPrivatePath:(NSString *)path
{
#if TARGET_IPHONE_SIMULATOR  //模拟器
  NSString *docPath = NSHomeDirectory();
#elif TARGET_OS_IPHONE      //真机
  NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
#endif
  NSString *homePath = [docPath stringByAppendingPathComponent:private_header_path];
  return [homePath stringByAppendingPathComponent:path];
}

@end
