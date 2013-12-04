//
//  StringUtil.m
//  Mini EIJIRO
//
//  Created by numata on Tue Jan 27 2004.
//  Copyright (c) 2004 Satoshi NUMATA. All rights reserved.
//

#import "StringUtil.h"

BOOL isFirst2BytesCharacter(unsigned char c) {
	return ((c >= 0x80 && c <= 0x9f) || (c >= 0xe0 && c <= 0xfc));
}

BOOL isEnglishWord(NSString *str, BOOL *isAllCapital) {
	unsigned int i;
	NSData *data = [str dataUsingEncoding:NSShiftJISStringEncoding];
	unsigned char *p = (unsigned char *) [data bytes];
	unsigned int length = [data length];
	*isAllCapital = YES;
	for (i = 0; i < length; i++) {
		if (isFirst2BytesCharacter(p[i])) {
			return NO;
		}
		if (islower(p[i])) {
			*isAllCapital = NO;
		}
	}
	return YES;
}

// 与えられたサイズで、大文字小文字を無視して文字列の比較を行う。
int mystrncmp(const unsigned char *str1, const unsigned char *str2, int size, BOOL eijiroHead)
{
	unsigned int i;
	
	// 英辞郎のデータには一部行頭が欠けているものがあるので、その対処
	// （オレが最初に間違えた比較をしていた可能性があるので、本当に必要かどうかちょっと怪しい）。
	// 「■」の1バイト目を必ず読み飛ばして比較を行うようにする。
	if (eijiroHead) {
		if (*str1 == 0x81) {
			str1++;
		}
		if (*str2 == 0x81) {
			str2++;
		}
		size -= 1;
	}
	
	// 比較のメイン
	for (i = 0; i < size; i++) {
		unsigned char c1 = str1[i];
		unsigned char c2 = str2[i];
		// '{' と ',' は単語の区切りと看做す。
		// "1,234" などがうまく検索できないが、とりあえず放っておこう。
		if (c1 == '{' || c1 == ',') {
			return -1;
		}
		// 文字コード順に並んでいない文字の対処。
		// '[', '\', '_' の順に 'z' よりも下に現れる。
		// これを '{', '|', '}' として扱うことで、とりあえず問題を回避できるだろう。
		if (c1 == '[') {
			c1 = '{';
		} else if (c1 == '\\') {
			c1 = '|';
		} else if (c1 == '_') {
			c1 = '}';
		}
		if (c2 == '[') {
			c2 = '{';
		} else if (c2 == '\\') {
			c2 = '|';
		} else if (c2 == '_') {
			c2 = '}';
		}
		// A〜Z の文字は a〜z に変換しておく
		if (c1 >= 'A' && c1 <= 'Z') {
			c1 = tolower(c1);
		}
		if (c2 >= 'A' && c2 <= 'Z') {
			c2 = tolower(c2);
		}
		// 比較する
		if (c1 != c2) {
			return c1 - c2;
		}
		// 2バイト文字の先頭文字であればもう1字を変換なしに比較する
		if (i < size && isFirst2BytesCharacter(c1)) {
			i++;
			c1 = str1[i];
			c2 = str2[i];
			if (c1 != c2) {
				return c1 - c2;
			}
		}
	}
	return 0;
}

// 文字列の中に文字列が含まれているかどうかを調べる
BOOL strContainsStr(const unsigned char *strTarget, unsigned int targetSize,
					const unsigned char *strSearch, unsigned int searchSize)
{
	unsigned int i;
	unsigned char firstChar = strSearch[0];
	if (targetSize < searchSize) {
		return NO;
	}
	if (firstChar >= 'A' && firstChar <= 'Z') {
		firstChar = tolower(firstChar);
	}
	for (i = 0; i < targetSize - searchSize + 1; i++) {
		unsigned char c = strTarget[i];
		if (c >= 'A' && c <= 'Z') {
			c = tolower(c);
		}
		if (c == firstChar) {
			if (mystrncmp(strTarget + i, strSearch, searchSize, NO) == 0) {
				return YES;
			}
		}
		if (isFirst2BytesCharacter(strTarget[i])) {
			i++;
		}
	}
	return NO;
}
