#import <Foundation/Foundation.h>

NSString *_ILLog(NSString *format, ...);
void ILLog(NSString *msg);

// '#define LOG_DISABLED 1' before '#import "Log.h"' in .m file to disable logging only in that file
#ifndef ILLOG_DISABLED
# define ILLOG_DISABLED 0
#endif

#if (defined(IRKIT_DEBUG) && ! ILLOG_DISABLED)
# define ILLOG_CURRENT_METHOD NSLog(@"%s#%d", __PRETTY_FUNCTION__, __LINE__)
# define ILLOG(...)           NSLog(@"%s#%d %@", __PRETTY_FUNCTION__, __LINE__, _ILLog(__VA_ARGS__))
#
#else
#  define ILLOG_CURRENT_METHOD
#  define ILLOG(...)
#
#endif

#ifdef IRKIT_DEBUG
# define ILASSERT(A,B) NSAssert(A,B)
#else
# define ILASSERT(A,B)
#endif
