#line 21379 "../lpsrc/flx_judy.pak"
#ifndef JUDY_EXTERN
#if defined(_WIN32) && !defined(FLX_STATIC_LINK)
#ifdef BUILD_JUDY
#define JUDY_EXTERN __declspec(dllexport)
#else
#define JUDY_EXTERN __declspec(dllimport)
#endif
#else
#define JUDY_EXTERN
#endif
#endif

/* here JU_WIN <=> MSVC CL build */
#ifdef _MSC_VER
#define JU_WIN
#endif


#line 21175 "./lpsrc/flx_judy.pak"
#ifndef JUDY_EXTERN
#if defined(_WIN32) && !defined(FLX_STATIC_LINK)
#ifdef BUILD_JUDY
#define JUDY_EXTERN __declspec(dllexport)
#else
#define JUDY_EXTERN __declspec(dllimport)
#endif
#else
#define JUDY_EXTERN
#endif
#endif

// @(#) From generation tool: $Revision: 4.37 $ $Source: /judy/src/JudyCommon/JudyTables.c $
//

#include "Judy1.h"
// Leave the malloc() sizes readable in the binary (via strings(1)):
const char * Judy1MallocSizes = "Judy1MallocSizes = 3, 5, 7, 11, 15, 23, 32, 47, 64, Leaf1 = 20";


//      object uses 64 words
//      cJU_BITSPERSUBEXPB = 32
const uint8_t
j__1_BranchBJPPopToWords[cJU_BITSPERSUBEXPB + 1] =
{
         0,
         3,  5,  7, 11, 11, 15, 15, 23,
        23, 23, 23, 32, 32, 32, 32, 32,
        47, 47, 47, 47, 47, 47, 47, 64,
        64, 64, 64, 64, 64, 64, 64, 64
};

//      object uses 5 words
//      cJ1_LEAF1_MAXPOP1 = 20
const uint8_t
j__1_Leaf1PopToWords[cJ1_LEAF1_MAXPOP1 + 1] =
{
         0,
         3,  3,  3,  3,  3,  3,  3,  3,
         3,  3,  3,  3,  5,  5,  5,  5,
         5,  5,  5,  5
};

//      object uses 32 words
//      cJ1_LEAF2_MAXPOP1 = 64
const uint8_t
j__1_Leaf2PopToWords[cJ1_LEAF2_MAXPOP1 + 1] =
{
         0,
         3,  3,  3,  3,  3,  3,  5,  5,
         5,  5,  7,  7,  7,  7, 11, 11,
        11, 11, 11, 11, 11, 11, 15, 15,
        15, 15, 15, 15, 15, 15, 23, 23,
        23, 23, 23, 23, 23, 23, 23, 23,
        23, 23, 23, 23, 23, 23, 32, 32,
        32, 32, 32, 32, 32, 32, 32, 32,
        32, 32, 32, 32, 32, 32, 32, 32
};

//      object uses 32 words
//      cJ1_LEAF3_MAXPOP1 = 42
const uint8_t
j__1_Leaf3PopToWords[cJ1_LEAF3_MAXPOP1 + 1] =
{
         0,
         3,  3,  3,  3,  5,  5,  7,  7,
         7, 11, 11, 11, 11, 11, 15, 15,
        15, 15, 15, 15, 23, 23, 23, 23,
        23, 23, 23, 23, 23, 23, 32, 32,
        32, 32, 32, 32, 32, 32, 32, 32,
        32, 32
};

//      object uses 32 words
//      cJ1_LEAFW_MAXPOP1 = 31
const uint8_t
j__1_LeafWPopToWords[cJ1_LEAFW_MAXPOP1 + 1] =
{
         0,
         3,  3,  5,  5,  7,  7, 11, 11,
        11, 11, 15, 15, 15, 15, 23, 23,
        23, 23, 23, 23, 23, 23, 32, 32,
        32, 32, 32, 32, 32, 32, 32
};


