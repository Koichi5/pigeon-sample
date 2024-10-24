// Autogenerated from Pigeon (v22.5.0), do not edit directly.
// See also: https://pub.dev/packages/pigeon

#import "messages.h"

#if TARGET_OS_OSX
#import <FlutterMacOS/FlutterMacOS.h>
#else
#import <Flutter/Flutter.h>
#endif

#if !__has_feature(objc_arc)
#error File requires ARC to be enabled.
#endif

static NSArray<id> *wrapResult(id result, FlutterError *error) {
  if (error) {
    return @[
      error.code ?: [NSNull null], error.message ?: [NSNull null], error.details ?: [NSNull null]
    ];
  }
  return @[ result ?: [NSNull null] ];
}

static FlutterError *createConnectionError(NSString *channelName) {
  return [FlutterError errorWithCode:@"channel-error" message:[NSString stringWithFormat:@"%@/%@/%@", @"Unable to establish connection on channel: '", channelName, @"'."] details:@""];
}

static id GetNullableObjectAtIndex(NSArray<id> *array, NSInteger key) {
  id result = array[key];
  return (result == [NSNull null]) ? nil : result;
}

@implementation FLTStateBox
- (instancetype)initWithValue:(FLTState)value {
  self = [super init];
  if (self) {
    _value = value;
  }
  return self;
}
@end

@interface FLTStateResult ()
+ (FLTStateResult *)fromList:(NSArray<id> *)list;
+ (nullable FLTStateResult *)nullableFromList:(NSArray<id> *)list;
- (NSArray<id> *)toList;
@end

@implementation FLTStateResult
+ (instancetype)makeWithErrorMessage:(nullable NSString *)errorMessage
    state:(FLTState)state {
  FLTStateResult* pigeonResult = [[FLTStateResult alloc] init];
  pigeonResult.errorMessage = errorMessage;
  pigeonResult.state = state;
  return pigeonResult;
}
+ (FLTStateResult *)fromList:(NSArray<id> *)list {
  FLTStateResult *pigeonResult = [[FLTStateResult alloc] init];
  pigeonResult.errorMessage = GetNullableObjectAtIndex(list, 0);
  FLTStateBox *boxedFLTState = GetNullableObjectAtIndex(list, 1);
  pigeonResult.state = boxedFLTState.value;
  return pigeonResult;
}
+ (nullable FLTStateResult *)nullableFromList:(NSArray<id> *)list {
  return (list) ? [FLTStateResult fromList:list] : nil;
}
- (NSArray<id> *)toList {
  return @[
    self.errorMessage ?: [NSNull null],
    [[FLTStateBox alloc] initWithValue:self.state],
  ];
}
@end

@interface FLTMessagesPigeonCodecReader : FlutterStandardReader
@end
@implementation FLTMessagesPigeonCodecReader
- (nullable id)readValueOfType:(UInt8)type {
  switch (type) {
    case 129: {
      NSNumber *enumAsNumber = [self readValue];
      return enumAsNumber == nil ? nil : [[FLTStateBox alloc] initWithValue:[enumAsNumber integerValue]];
    }
    case 130: 
      return [FLTStateResult fromList:[self readValue]];
    default:
      return [super readValueOfType:type];
  }
}
@end

@interface FLTMessagesPigeonCodecWriter : FlutterStandardWriter
@end
@implementation FLTMessagesPigeonCodecWriter
- (void)writeValue:(id)value {
  if ([value isKindOfClass:[FLTStateBox class]]) {
    FLTStateBox *box = (FLTStateBox *)value;
    [self writeByte:129];
    [self writeValue:(value == nil ? [NSNull null] : [NSNumber numberWithInteger:box.value])];
  } else if ([value isKindOfClass:[FLTStateResult class]]) {
    [self writeByte:130];
    [self writeValue:[value toList]];
  } else {
    [super writeValue:value];
  }
}
@end

@interface FLTMessagesPigeonCodecReaderWriter : FlutterStandardReaderWriter
@end
@implementation FLTMessagesPigeonCodecReaderWriter
- (FlutterStandardWriter *)writerWithData:(NSMutableData *)data {
  return [[FLTMessagesPigeonCodecWriter alloc] initWithData:data];
}
- (FlutterStandardReader *)readerWithData:(NSData *)data {
  return [[FLTMessagesPigeonCodecReader alloc] initWithData:data];
}
@end

NSObject<FlutterMessageCodec> *FLTGetMessagesCodec(void) {
  static FlutterStandardMessageCodec *sSharedObject = nil;
  static dispatch_once_t sPred = 0;
  dispatch_once(&sPred, ^{
    FLTMessagesPigeonCodecReaderWriter *readerWriter = [[FLTMessagesPigeonCodecReaderWriter alloc] init];
    sSharedObject = [FlutterStandardMessageCodec codecWithReaderWriter:readerWriter];
  });
  return sSharedObject;
}
void SetUpFLTExampleApi(id<FlutterBinaryMessenger> binaryMessenger, NSObject<FLTExampleApi> *api) {
  SetUpFLTExampleApiWithSuffix(binaryMessenger, api, @"");
}

void SetUpFLTExampleApiWithSuffix(id<FlutterBinaryMessenger> binaryMessenger, NSObject<FLTExampleApi> *api, NSString *messageChannelSuffix) {
  messageChannelSuffix = messageChannelSuffix.length > 0 ? [NSString stringWithFormat: @".%@", messageChannelSuffix] : @"";
  ///
  /// ドキュメントは全プラットフォームに反映されます
  ///
  {
    FlutterBasicMessageChannel *channel =
      [[FlutterBasicMessageChannel alloc]
        initWithName:[NSString stringWithFormat:@"%@%@", @"dev.flutter.pigeon.pigeon_sample.ExampleApi.example", messageChannelSuffix]
        binaryMessenger:binaryMessenger
        codec:FLTGetMessagesCodec()];
    if (api) {
      NSCAssert([api respondsToSelector:@selector(exampleWithError:)], @"FLTExampleApi api (%@) doesn't respond to @selector(exampleWithError:)", api);
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        [api exampleWithError:&error];
        callback(wrapResult(nil, error));
      }];
    } else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [[FlutterBasicMessageChannel alloc]
        initWithName:[NSString stringWithFormat:@"%@%@", @"dev.flutter.pigeon.pigeon_sample.ExampleApi.openUrl", messageChannelSuffix]
        binaryMessenger:binaryMessenger
        codec:FLTGetMessagesCodec()];
    if (api) {
      NSCAssert([api respondsToSelector:@selector(openUrlUrl:error:)], @"FLTExampleApi api (%@) doesn't respond to @selector(openUrlUrl:error:)", api);
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        NSArray<id> *args = message;
        NSString *arg_url = GetNullableObjectAtIndex(args, 0);
        FlutterError *error;
        [api openUrlUrl:arg_url error:&error];
        callback(wrapResult(nil, error));
      }];
    } else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [[FlutterBasicMessageChannel alloc]
        initWithName:[NSString stringWithFormat:@"%@%@", @"dev.flutter.pigeon.pigeon_sample.ExampleApi.queryState", messageChannelSuffix]
        binaryMessenger:binaryMessenger
        codec:FLTGetMessagesCodec()];
    if (api) {
      NSCAssert([api respondsToSelector:@selector(queryStateWithError:)], @"FLTExampleApi api (%@) doesn't respond to @selector(queryStateWithError:)", api);
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        FLTStateResult *output = [api queryStateWithError:&error];
        callback(wrapResult(output, error));
      }];
    } else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [[FlutterBasicMessageChannel alloc]
        initWithName:[NSString stringWithFormat:@"%@%@", @"dev.flutter.pigeon.pigeon_sample.ExampleApi.getToken", messageChannelSuffix]
        binaryMessenger:binaryMessenger
        codec:FLTGetMessagesCodec()];
    if (api) {
      NSCAssert([api respondsToSelector:@selector(getTokenWithCompletion:)], @"FLTExampleApi api (%@) doesn't respond to @selector(getTokenWithCompletion:)", api);
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        [api getTokenWithCompletion:^(NSString *_Nullable output, FlutterError *_Nullable error) {
          callback(wrapResult(output, error));
        }];
      }];
    } else {
      [channel setMessageHandler:nil];
    }
  }
}
@interface FLTExample2Api ()
@property(nonatomic, strong) NSObject<FlutterBinaryMessenger> *binaryMessenger;
@property(nonatomic, strong) NSString *messageChannelSuffix;
@end

@implementation FLTExample2Api

- (instancetype)initWithBinaryMessenger:(NSObject<FlutterBinaryMessenger> *)binaryMessenger {
  return [self initWithBinaryMessenger:binaryMessenger messageChannelSuffix:@""];
}
- (instancetype)initWithBinaryMessenger:(NSObject<FlutterBinaryMessenger> *)binaryMessenger messageChannelSuffix:(nullable NSString*)messageChannelSuffix{
  self = [self init];
  if (self) {
    _binaryMessenger = binaryMessenger;
    _messageChannelSuffix = [messageChannelSuffix length] == 0 ? @"" : [NSString stringWithFormat: @".%@", messageChannelSuffix];
  }
  return self;
}
- (void)handleUriUri:(NSString *)arg_uri completion:(void (^)(FlutterError *_Nullable))completion {
  NSString *channelName = [NSString stringWithFormat:@"%@%@", @"dev.flutter.pigeon.pigeon_sample.Example2Api.handleUri", _messageChannelSuffix];
  FlutterBasicMessageChannel *channel =
    [FlutterBasicMessageChannel
      messageChannelWithName:channelName
      binaryMessenger:self.binaryMessenger
      codec:FLTGetMessagesCodec()];
  [channel sendMessage:@[arg_uri ?: [NSNull null]] reply:^(NSArray<id> *reply) {
    if (reply != nil) {
      if (reply.count > 1) {
        completion([FlutterError errorWithCode:reply[0] message:reply[1] details:reply[2]]);
      } else {
        completion(nil);
      }
    } else {
      completion(createConnectionError(channelName));
    } 
  }];
}
@end

