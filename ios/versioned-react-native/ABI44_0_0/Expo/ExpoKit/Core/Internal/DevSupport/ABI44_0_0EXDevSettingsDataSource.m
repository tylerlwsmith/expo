// Copyright 2015-present 650 Industries. All rights reserved.

#import "ABI44_0_0EXDevSettingsDataSource.h"

#import <ABI44_0_0React/ABI44_0_0RCTLog.h>
#import <ABI44_0_0React/ABI44_0_0RCTUtils.h>

// redefined from ABI44_0_0RCTDevMenu.mm
NSString *const ABI44_0_0EXDevSettingsUserDefaultsKey = @"ABI44_0_0RCTDevMenu";
NSString *const ABI44_0_0EXDevSettingShakeToShowDevMenu = @"shakeToShow";
NSString *const ABI44_0_0EXDevSettingProfilingEnabled = @"profilingEnabled";
NSString *const ABI44_0_0EXDevSettingHotLoadingEnabled = @"hotLoadingEnabled";
NSString *const ABI44_0_0EXDevSettingLiveReloadEnabled = @"liveReloadEnabled";
NSString *const ABI44_0_0EXDevSettingIsInspectorShown = @"showInspector";
NSString *const ABI44_0_0EXDevSettingIsDebuggingRemotely = @"isDebuggingRemotely";

@interface ABI44_0_0EXDevSettingsDataSource ()

@property (nonatomic, strong) NSString *scopeKey;
@property (nonatomic, readonly) NSSet *settingsDisabledInProduction;

@end

@implementation ABI44_0_0EXDevSettingsDataSource {
  NSMutableDictionary *_settings;
  NSUserDefaults *_userDefaults;
  BOOL _isDevelopment;
}

- (instancetype)initWithDefaultValues:(NSDictionary *)defaultValues
                forScopeKey:(NSString *)scopeKey
                        isDevelopment:(BOOL)isDevelopment
{
  if (self = [super init]) {
    _scopeKey = scopeKey;
    _userDefaults = [NSUserDefaults standardUserDefaults];
    _isDevelopment = isDevelopment;
    _settingsDisabledInProduction = [NSSet setWithArray:@[
      ABI44_0_0EXDevSettingShakeToShowDevMenu,
      ABI44_0_0EXDevSettingProfilingEnabled,
      ABI44_0_0EXDevSettingHotLoadingEnabled,
      ABI44_0_0EXDevSettingLiveReloadEnabled,
      ABI44_0_0EXDevSettingIsInspectorShown,
      ABI44_0_0EXDevSettingIsDebuggingRemotely,
    ]];
    if (defaultValues) {
      [self _reloadWithDefaults:defaultValues];
    }
  }
  return self;
}

- (void)updateSettingWithValue:(id)value forKey:(NSString *)key
{
  ABI44_0_0RCTAssert((key != nil), @"%@", [NSString stringWithFormat:@"%@: Tried to update nil key", [self class]]);

  id currentValue = [self settingForKey:key];
  if (currentValue == value || [currentValue isEqual:value]) {
    return;
  }
  if (value) {
    _settings[key] = value;
  } else {
    [_settings removeObjectForKey:key];
  }
  [_userDefaults setObject:_settings forKey:[self _userDefaultsKey]];
}

- (id)settingForKey:(NSString *)key
{
  // live reload is always disabled in ABI44_0_0React-native@>=0.61 due to fast refresh
  // we can remove this when live reload is completely removed from the
  // ABI44_0_0React-native runtime
  if ([key isEqualToString:ABI44_0_0EXDevSettingLiveReloadEnabled]) {
    return @NO;
  }

  // prohibit these settings if not serving the experience as a developer
  if (!_isDevelopment && [_settingsDisabledInProduction containsObject:key]) {
    return @NO;
  }
  return _settings[key];
}

#pragma mark - internal

- (void)_reloadWithDefaults:(NSDictionary *)defaultValues
{
  NSString *defaultsKey = [self _userDefaultsKey];
  NSDictionary *existingSettings = [_userDefaults objectForKey:defaultsKey];
  _settings = existingSettings ? [existingSettings mutableCopy] : [NSMutableDictionary dictionary];
  for (NSString *key in [defaultValues keyEnumerator]) {
    if (!_settings[key]) {
      _settings[key] = defaultValues[key];
    }
  }
  [_userDefaults setObject:_settings forKey:defaultsKey];
}

- (NSString *)_userDefaultsKey
{
  if (_scopeKey) {
    return [NSString stringWithFormat:@"%@/%@", _scopeKey, ABI44_0_0EXDevSettingsUserDefaultsKey];
  } else {
    ABI44_0_0RCTLogWarn(@"Can't scope dev settings because bridge is not set");
    return ABI44_0_0EXDevSettingsUserDefaultsKey;
  }
}

@end
