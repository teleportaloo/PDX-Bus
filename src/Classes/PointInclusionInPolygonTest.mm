
/*
   Copyright (c) 1970-2003, Wm. Randolph Franklin

   Permission is hereby granted, free of charge, to any person obtaining a
   copy of this software and associated documentation files (the "Software"),
   to deal in the Software without restriction, including without limitation
   the rights to use, copy, modify, merge, publish, distribute, sublicense,
   and/or sell copies of the Software, and to permit persons to whom the Software
   is furnished to do so, subject to the following conditions:

   1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimers.
   2. Redistributions in binary form must reproduce the above copyright notice in
   the documentation and/or other materials provided with the distribution.
   3. The name of W. Randolph Franklin may not be used to endorse or promote products
   derived from this Software without specific prior written permission.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
   LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
   USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

/*
 * https://wrf.ecse.rpi.edu//Research/Short_Notes/pnpoly.html
 * Modified for the objective C objects CG points
 * Compare with original C code
 */

#if 0
 int pnpoly(int nvert, float *vertx, float *verty, float testx, float testy)
 {
   int i, j, c = 0;
   for (i = 0, j = nvert-1; i < nvert; j = i++) {
     if ( ((verty[i]>testy) != (verty[j]>testy)) &&
      (testx < (vertx[j]-vertx[i]) * (testy-verty[i]) / (verty[j]-verty[i]) + vertx[i]) )
        c = !c;
   }
   return c;
 }
#endif

#import "PointInclusionInPolygonTest.h"

@implementation PointInclusionInPolygonTest

+ (bool)pnpoly:(int)npol points:(const CGPoint *)p x:(CGFloat)x y:(CGFloat)y {
    int i, j, c = 0;
    const CGPoint *pj;
    const CGPoint *pi;

    for (i = 0, j = npol - 1; i < npol; j = i++) {
        pj = p + j;
        pi = p + i;

        if ((((pi->y <= y) && (y < pj->y)) ||
             ((pj->y <= y) && (y < pi->y))) &&
            (x < (pj->x - pi->x) * (y - pi->y) / (pj->y - pi->y) + pi->x)) {
            c = !c;
        }
    }

    return c;
}

@end
