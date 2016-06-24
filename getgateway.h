#ifndef __GETGATEWAY_H__
#define __GETGATEWAY_H__

#include <ctype.h>
#include <sys/param.h>
#include <sys/sysctl.h>
#include <stdlib.h>
#include <netinet/in.h>

 /*the very same from google-code*/

/* getdefaultgateway() :
 * return value :
 *    0 : success
 *   -1 : failure    */
int getdefaultgateway(struct in_addr * addr);

/* getdefaultgateway6() :
 * return value :
 *    0 : success
 *   -1 : failure    */
int getdefaultgateway6(struct in6_addr * addr);

#endif