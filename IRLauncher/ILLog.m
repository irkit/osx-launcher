#import "ILLog.h"

NSString *_ILLog(NSString *format, ...){
    va_list args;
    va_start(args, format);
    NSString *str = [[NSString alloc] initWithFormat: format arguments: args];
    va_end(args);
    return str;
}

void ILLog(NSString *format, ...){
    va_list args;
    va_start(args, format);
    NSString *prepended_format = [NSString stringWithFormat: @"[IRLauncher]%@", format];
    va_end(args);

    NSLog( prepended_format, args );
}