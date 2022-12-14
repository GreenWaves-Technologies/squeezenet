
#ifndef __SQUEEZE_H__
#define __SQUEEZE_H__

#define __PREFIX(x) squeezenet ## x

#include "Gap.h"

#ifdef __EMUL__
#include <sys/types.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/param.h>
#include <string.h>
#endif

extern AT_HYPERFLASH_FS_EXT_ADDR_TYPE __PREFIX(_L3_Flash);
extern AT_HYPERFLASH_FS_EXT_ADDR_TYPE __PREFIX(_L3_PrivilegedFlash);
#include "measurments_utils.h"

#endif

