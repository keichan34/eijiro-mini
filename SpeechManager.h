//
//  SpeechManager.h
//  CocoaSpeechExample
//
//  Created by numata on Mon Sep 30 2002.
//  Copyright (c) 2002 Satoshi NUMATA. All rights reserved.
//
//  �p���e�L�X�g�ǂݏグ�@�\���T�|�[�g���邽�߂̃N���X�B
//


#import <Cocoa/Cocoa.h>


@interface SpeechManager : NSObject
{
	// �ǂݏグ�@�\���T�|�[�g���邽�߂̃����o
    SpeechChannel	speechChannel;
	long			stopMode;

	// �e����
	BOOL	isSpeaking;
	int		currentPos;
	int		currentLength;
	OSErr	lastError;

	// �R�[���o�b�N�̂��߂̃Z���N�^�ƃ^�[�Q�b�g
	id	target;
	SEL	speakingStartedMethod;
	SEL	speakingPosChangedMethod;
	SEL	speakingDoneMethod;
	SEL	errorOccuredMethod;
}

// ���������\�b�h
- (id)initWithStopMode:(long)stopMode_
	target:(id)target
	speakingStartedMethod:(SEL)speakingStartedMethod_
	speakingPosChangedMethod:(SEL)speakingPosChangedMethod_
	speakingDoneMethod:(SEL)speakingDoneMethod_
	errorOccuredMethod:(SEL)errorOccuredMethod_;
- (BOOL)createSpeechChannel;

// �ǂݏグ�̊J�n�ƏI�����\�b�h
- (void)speakText:(NSString *)text;
- (void)stopSpeaking;

// �ǂݏグ���[�e�B���e�B
- (NSString *)convertToSpeakableText:(NSString *)text;

// �e���Ԃ̕ύX���\�b�h
- (void)setSpeaking:(BOOL)flag;
- (void)setCurrentSpeakingPos:(int)pos length:(int)length;
- (void)setError:(OSErr)error pos:(int)pos;

// �e���Ԃ̎擾���\�b�h
- (BOOL)isSpeaking;
- (int)currentPos;
- (int)currentLength;
- (OSErr)lastError;

@end


// �R�[���o�b�N�֐��̃v���g�^�C�v
pascal void ErrorCallBackProc(
	SpeechChannel inSpeechChannel, long inRefCon, OSErr inError, long inBytePos);

pascal void TextDoneCallBackProc(
	SpeechChannel inSpeechChannel, long inRefCon,
	const void **nextBuf, unsigned long *byteLen, long *controlFlags);

pascal void SpeechDoneCallBackProc (SpeechChannel inSpeechChannel, long inRefCon);

pascal void WordCallBackProc(
	SpeechChannel inSpeechChannel, long inRefCon, long inWordPos, short inWordLen);

