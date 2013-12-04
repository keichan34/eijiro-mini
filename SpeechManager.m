//
//  SpeechManager.m
//  CocoaSpeechExample
//
//  Created by numata on Mon Sep 30 2002.
//  Copyright (c) 2002 Satoshi NUMATA. All rights reserved.
//

#import "SpeechManager.h"


//  �p���e�L�X�g�ǂݏグ�@�\���T�|�[�g���邽�߂̃N���X�B
@implementation SpeechManager

// ������
// stopMode �ɂ́AkImmediate�AkEndOfWord�AkEndOfSentence�̂����ꂩ���w�肷��
- (id)initWithStopMode:(long)stopMode_
		target:(id)target_
		speakingStartedMethod:(SEL)speakingStartedMethod_
		speakingPosChangedMethod:(SEL)speakingPosChangedMethod_
		speakingDoneMethod:(SEL)speakingDoneMethod_
		errorOccuredMethod:(SEL)errorOccuredMethod_;
{
	self = [super init];
	if (self) {
		stopMode = stopMode_;
		target = target_;
		speakingStartedMethod = speakingStartedMethod_;
		speakingPosChangedMethod = speakingPosChangedMethod_;
		speakingDoneMethod = speakingDoneMethod_;
		errorOccuredMethod = errorOccuredMethod_;
		speechChannel = NULL;
		if (![self createSpeechChannel]) {
			[self dealloc];
			return nil;
		}
	}
	return self;
}

// �N���[���A�b�v
- (void)dealloc
{
	if (isSpeaking) {
		[self stopSpeaking];
	}
	if (speechChannel) {
		DisposeSpeechChannel(speechChannel);
    }
	[super dealloc];
}

// �X�s�[�`�`�����l���̐���
- (BOOL)createSpeechChannel
{
    OSErr error;

	// �X�s�[�`�`�����l���̐���
	error = NewSpeechChannel(NULL, &speechChannel);
	if (error != noErr) {
		[self setError:error pos:-1];
		return NO;
	}
    
	// �R�[���o�b�N�֐����炱�̃N���X�ɃA�N�Z�X���邽�߂ɁARefCon �ɂ��̃N���X�̃|�C���^��ݒ肵�Ă���
	error = SetSpeechInfo(speechChannel, soRefCon, (Ptr) self);
	if (error != noErr) {
		return NO;
	}

	// �ȉ��A�e��R�[���o�b�N�̃Z�b�g
	error = SetSpeechInfo(speechChannel, soSpeechDoneCallBack, SpeechDoneCallBackProc);
	if (error != noErr) {
		return NO;
	}
	error = SetSpeechInfo(speechChannel, soTextDoneCallBack, TextDoneCallBackProc);
	if (error != noErr) {
		return NO;
	}
	error = SetSpeechInfo(speechChannel, soWordCallBack, WordCallBackProc);
	if (error != noErr) {
		return NO;
	}
	error = SetSpeechInfo(speechChannel, soErrorCallBack, ErrorCallBackProc);
	if (error != noErr) {
		return NO;
	}

    return YES;
}

// �e�L�X�g�ǂݏグ�̊J�n
- (void)speakText:(NSString *)text
{
	OSErr error;
	NSString *speakableText;

	// �ǂݏグ���ł���Β�~���Ă���Đ����s��
	if (isSpeaking) {
		[self stopSpeaking];
	}

	// �ǂݏグ���ł��镶���݂̂ɕϊ�����
	speakableText = [self convertToSpeakableText:text];

	// �ǂݏグ�J�n
	error = SpeakText(
			speechChannel, [speakableText cString], [speakableText cStringLength]);
	if (error != noErr) {
		[self setError:error pos:0];
	} else {
		[self setSpeaking:YES];
	}
}

// �ǂݏグ�̒�~
- (void)stopSpeaking
{
	OSErr error;

	if (!isSpeaking) {
		return;
	}

	error = StopSpeechAt(speechChannel, stopMode);
	if (error != noErr) {
		[self setError:error pos:0];
	} else {
		[self setSpeaking:NO];
	}
}

// �^����ꂽ�e�L�X�g���A�ǂݏグ�\�ȃe�L�X�g�ɕϊ�����
- (NSString *)convertToSpeakableText:(NSString *)text
{
	int i;
	NSString *modifiedText;
	unichar *fromBuffer = malloc(sizeof(unichar) * [text length]);
	unichar *toBuffer = malloc(sizeof(unichar) * [text length]);
	unichar c[5];
	BOOL pass = NO;
	BOOL pronunciation = NO;
	BOOL level = NO;
	[text getCharacters:fromBuffer];
	for (i = 0; i < [text length]; i++) {
		// �u{}�v�Ɓu�y�z�v�̊Ԃ̕����͓ǂݔ�΂�
		if (!pass && (fromBuffer[i] == 0x7b || fromBuffer[i] == 0x3010)) {
			pass = YES;
			// �ǂݏグ���Ȃ������́A�u/�v�ɕϊ�����ƃX�L�b�v�����
			toBuffer[i] = 0x2f;
			// �����L�����ǂݔ�΂�
			if (i + 3 < [text length]) {
				c[0] = fromBuffer[i];
				c[1] = fromBuffer[i+1];
				c[2] = fromBuffer[i+2];
				c[3] = fromBuffer[i+3];
				if (c[0] == 0x3010 && c[1] == 0x767a && c[2] == 0x97f3 && c[3] == 0x3011) {
					pronunciation = YES;
				} else if (i + 4 < [text length]) {
					c[4] = fromBuffer[i+4];
					if (c[0] == 0x3010 && c[1] == 0x767a && c[2] == 0x97f3 &&
							c[3] == 0xff01 && c[4] == 0x3011) {
						pronunciation = YES;
					} else if (c[0] == 0x3010 && c[1] == 0x30ec && c[2] == 0x30d9 &&
							c[3] == 0x30eb && c[4] == 0x3011) {
						level = YES;
					}
				}
			}
		} else if (pass) {
			toBuffer[i] = 0x2f;
			if (!pronunciation && !level && (fromBuffer[i] == 0x7d || fromBuffer[i] == 0x3011)) {
				pass = NO;
			} else if (pronunciation && fromBuffer[i] == 0x3001) {
				pronunciation = NO;
				pass = NO;
			} else if (level &&
					(fromBuffer[i] == 0x3001 || fromBuffer[i] == 0x0d || fromBuffer[i] == 0x0a)) {
				level = NO;
				pass = NO;
			}
		}
		// ���{��͓ǂ߂Ȃ�
		else if (fromBuffer[i] > 0x7e) {
			// �ǂݏグ���Ȃ������́A�u/�v�ɕϊ�����ƃX�L�b�v�����
			toBuffer[i] = 0x2f;
		}
		// �u/�v�͋�؂蕶���Ƃ��Ďg���Ă���B�u;�v�ɕϊ����ċ�؂��ǂ܂���
		else if (fromBuffer[i] == 0x2f) {
			toBuffer[i] = 0x3b;
		}
		// �ǂ߂镶��
		else {
			toBuffer[i] = fromBuffer[i];
		}
	}
	modifiedText = [NSString stringWithCharacters:toBuffer length:[text length]];
	free(fromBuffer);
	free(toBuffer);
	return modifiedText;
}

// �ǂݏグ�̊J�n/�I�����Ƀt���O���Z�b�g���A�R�[���o�b�N�̃Z���N�^���g���K����
- (void)setSpeaking:(BOOL)flag
{
	isSpeaking = flag;
	if (isSpeaking) {
		if (target && speakingStartedMethod) {
			[target performSelector:speakingStartedMethod withObject:self];
		}
	} else {
		if (target && speakingDoneMethod) {
			[target performSelector:speakingDoneMethod withObject:self];
		}
	}
}

// ���ꂩ��ǂݏグ��ꏊ��currentPos�ɃZ�b�g���āA�R�[���o�b�N�̃Z���N�^���g���K����
- (void)setCurrentSpeakingPos:(int)pos length:(int)length
{
	currentPos = pos;
	currentLength = length;
	if (target && speakingPosChangedMethod) {
		[target performSelector:speakingPosChangedMethod withObject:self];
	}
}

// lastError�ϐ��ɃG���[�ԍ����Z�b�g���A�G���[���N�������ꏊ��currentPos�ɃZ�b�g���āA
// �G���[��p�̃R�[���o�b�N�̃Z���N�^���g���K����
- (void)setError:(OSErr)error pos:(int)pos
{
	lastError = error;
	currentPos = pos;
	[self setSpeaking:NO];
	if (target && errorOccuredMethod) {
		[target performSelector:errorOccuredMethod withObject:self];
	}
}

// �ǂݏグ�����ǂ���
- (BOOL)isSpeaking
{
	return isSpeaking;
}

// �J�����g�̓ǂݏグ�ʒu
- (int)currentPos
{
	return currentPos;
}

// �J�����g�̓ǂݏグ������̒���
- (int)currentLength
{
	return currentLength;
}

// �G���[�ԍ�
- (OSErr)lastError
{
	return lastError;
}

@end


///// �ȉ��A�e��R�[���o�b�N���[�`��

// �J�����g�̒P�ꂪ�������ꂽ�Ƃ��ɃR�[�������B
// �ǉ��̃e�L�X�g��n���ď������p�������邱�Ƃ��ł���B
pascal void TextDoneCallBackProc(
		SpeechChannel inSpeechChannel, long inRefCon,
		const void **nextBuf, unsigned long *byteLen, long *controlFlags)
{
	*nextBuf = NULL;
}

// �P��𐶐����悤�Ƃ��閈�ɁA�V�����ʒu�ƒ����������ɓ���ăR�[�������B
pascal void WordCallBackProc(
	SpeechChannel inSpeechChannel, long inRefCon, long inWordPos, short inWordLen)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	SpeechManager *speechManager = (SpeechManager *) inRefCon;
	[speechManager setCurrentSpeakingPos:inWordPos length:inWordLen];
	[pool release];
}

// ���ׂĂ̓ǂݏグ�����������Ƃ��ɃR�[�������
pascal void SpeechDoneCallBackProc(SpeechChannel inSpeechChannel, long inRefCon)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	SpeechManager *speechManager = (SpeechManager *) inRefCon;
	[speechManager setSpeaking:NO];
	[pool release];
}

// �e�L�X�g�ǂݏグ���ɃG���[���N�������ꍇ�ɃR�[�������
pascal void ErrorCallBackProc(
	SpeechChannel inSpeechChannel, long inRefCon, OSErr inError, long inBytePos)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	SpeechManager *speechManager = (SpeechManager *) inRefCon;
	[speechManager setError:inError pos:inBytePos];
	[pool release];
}



