//
//  StringUtil.h
//  Mini EIJIRO
//
//  Created by numata on Tue Jan 27 2004.
//  Copyright (c) 2004 Satoshi NUMATA. All rights reserved.
//

#import <Foundation/Foundation.h>

inline BOOL isFirst2BytesCharacter(unsigned char c);
BOOL isEnglishWord(NSString *str, BOOL *isAllCapital);

// 与えられたサイズで、大文字小文字を無視して文字列の比較を行う。
int mystrncmp(const unsigned char *str1, const unsigned char *str2, int size, BOOL eijiroHead);

