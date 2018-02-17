#include <cstdlib>
#include <iostream>
#include<stdlib.h>
#include<string.h>
#include<time.h>
#include<vector>
#include<algorithm>
#include <graphics.h>      // ����ͼ�ο�ͷ�ļ�
#include <conio.h>
#define GRID_NUM    15 //ÿһ��(��)�����̽�����
#define GRID_COUNT  225*4//�����ڴ��С
#define MYBLACK        0 //������0��ʾ
#define MYWHITE        1 //������1��ʾ
#define NOSTONE     9  //û������
//����궨�������Դ��������͵�����
#define STWO        1  //�߶�
#define STHREE        2  //����
#define SFOUR        3  //����
#define TWO        4  //���
#define THREE        5  //����
#define FOUR        6  //����
#define FIVE        7  //����
#define NOTYPE        11 //δ����
#define ANALSISED   255//�ѷ�������
#define TOBEANALSIS 0  //�ѷ�������
//��������Լ��ĳһ�����Ƿ��������ϵ���Ч���ӵ�
#define IsValidPos(x,y) ((x>=0 && x<GRID_NUM) && (y>=0 && y<GRID_NUM)
//������ö���͵��������ͣ���ȷ���±߽磬�ϱ߽�
using namespace std;
//ȫ�ֱ���,����ͳ�ƹ�ֵ������ִ�б���
int ccount = 0;
typedef struct Node
{
	int x;
	int y;
}MYPOINT;

//���Ա�ʾ����λ�õĽṹ

class MOVESTONE
{
public:
	int color;
	MYPOINT ptMovePoint;
	MOVESTONE() {};
	MOVESTONE(unsigned char color, int x, int y) {
		this->color = color;
		this->ptMovePoint.x = x;
		this->ptMovePoint.y = y;
	}
	void operator=(MOVESTONE &m2) {
		this->color = m2.color;
		this->ptMovePoint.x = m2.ptMovePoint.x;
		this->ptMovePoint.y = m2.ptMovePoint.y;
	}
};
//����ṹ���Ա�ʾ�߷�
class State {
public:
	int grid[GRID_NUM][GRID_NUM];
	State() {};
	State(int position[GRID_NUM][GRID_NUM]) {
		memcpy(grid, position, GRID_COUNT);
	}
	void operator=(State &s2) {
		memcpy(this->grid, s2.grid, GRID_COUNT);
	}
};
class AFTERMOVE
{
public:
	State state;//��һ��֮���״̬
	int score;        //�߷��ķ���
	AFTERMOVE() {};
	AFTERMOVE(State &s,int score) {
		this->state = s;
		this->score = score;
	}
	void operator=(AFTERMOVE& a) {
		this->score = a.score;
		this->state = a.state;
	}
};



typedef vector<MOVESTONE> movelists;
//=================================================================//
int AnalysisLine(int* position, int GridNum, int StonePos);
int AnalysisRight(int position[GRID_NUM][GRID_NUM], int i, int j);
int AnalysisLeft(int position[GRID_NUM][GRID_NUM], int i, int j);
int AnalysisVertical(int position[GRID_NUM][GRID_NUM], int i, int j);
int AnalysisHorizon(int position[GRID_NUM][GRID_NUM], int i, int j);
//int Evaluate(unsigned int position[][GRID_NUM], bool bIsWhiteTurn);
int CreatePossibleMove(int position[GRID_NUM][GRID_NUM], int nPly, int nSide);
void display(int position[GRID_NUM][GRID_NUM]);


//=================================================================//
int m_LineRecord[30];          //���AnalysisLine�������������
int TypeRecord[GRID_NUM][GRID_NUM][4];//���ȫ���������������,������ά��,���ڴ��ˮƽ����ֱ����б����б 4 ���������������ͷ������
int TypeCount[2][20];          //���ͳ�ǹ��ķ������������
int m_nMoveCount;//�˱������Լ�¼�߷�������  
int m_nSearchDepth;        //����������
int MaxDepth=2;        //��ǰ����������������
							   //CSearchEngine* m_pSE;         //��������ָ�� 
										 //λ����Ҫ�Լ�ֵ��,�˱���м�����,Խ�����ֵԽ��
int PosValue[GRID_NUM][GRID_NUM] =
{
	{ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 },
{ 0,1,1,1,1,1,1,1,1,1,1,1,1,1,0 },
{ 0,1,2,2,2,2,2,2,2,2,2,2,2,1,0 },
{ 0,1,2,3,3,3,3,3,3,3,3,3,2,1,0 },
{ 0,1,2,3,4,4,4,4,4,4,4,3,2,1,0 },
{ 0,1,2,3,4,5,5,5,5,5,4,3,2,1,0 },
{ 0,1,2,3,4,5,6,6,6,5,4,3,2,1,0 },
{ 0,1,2,3,4,5,6,7,6,5,4,3,2,1,0 },
{ 0,1,2,3,4,5,6,6,6,5,4,3,2,1,0 },
{ 0,1,2,3,4,5,5,5,5,5,4,3,2,1,0 },
{ 0,1,2,3,4,4,4,4,4,4,4,3,2,1,0 },
{ 0,1,2,3,3,3,3,3,3,3,3,3,2,1,0 },
{ 0,1,2,2,2,2,2,2,2,2,2,2,2,1,0 },
{ 0,1,1,1,1,1,1,1,1,1,1,1,1,1,0 },
{ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 }
};


int Evaluate(int position[GRID_NUM][GRID_NUM], int color)
{
	int i, j, k;
	int nStoneType;
	ccount++;//�������ۼ�
			  //������ͷ������
	memset(TypeRecord, TOBEANALSIS, GRID_NUM*GRID_NUM * 4*4);
	memset(TypeCount, 0, 40 * 4);

	for (i = 0; i<GRID_NUM; i++)
		for (j = 0; j<GRID_NUM; j++)
		{
			if (position[i][j] != NOSTONE)
			{
				//���ˮƽ������û�з�����
				if (TypeRecord[i][j][0] == TOBEANALSIS)
					AnalysisHorizon(position, i, j);

				//�����ֱ������û�з�����
				if (TypeRecord[i][j][1] == TOBEANALSIS)
					AnalysisVertical(position, i, j);

				//�����б������û�з�����
				if (TypeRecord[i][j][2] == TOBEANALSIS)
					AnalysisLeft(position, i, j);

				//�����б������û�з�����
				if (TypeRecord[i][j][3] == TOBEANALSIS)
					AnalysisRight(position, i, j);
			}
		}
	//�Է����������ͳ��,�õ�ÿ�����͵�����
	for (i = 0; i<GRID_NUM; i++)
		for (j = 0; j<GRID_NUM; j++)
			for (k = 0; k<4; k++){
				nStoneType = position[i][j];
				if (nStoneType != NOSTONE){
					switch (TypeRecord[i][j][k])
					{
					case FIVE://����
						TypeCount[nStoneType][FIVE]++;
						break;
					case FOUR://����
						TypeCount[nStoneType][FOUR]++;
						break;
					case SFOUR://����
						TypeCount[nStoneType][SFOUR]++;
						break;
					case THREE://����
						TypeCount[nStoneType][THREE]++;
						break;
					case STHREE://����
						TypeCount[nStoneType][STHREE]++;
						break;
					case TWO://���
						TypeCount[nStoneType][TWO]++;
						break;
					case STWO://�߶�
						TypeCount[nStoneType][STWO]++;
						break;
					default:
						break;
					}
				}
			}
	//���������,���ؼ�ֵ

	if (TypeCount[MYBLACK][FIVE])
	{
		return -9999;
	}
	if (TypeCount[MYWHITE][FIVE])
	{
		return 9999;
	}

	//�������ĵ���һ������
	if (TypeCount[MYWHITE][SFOUR]>1)
		TypeCount[MYWHITE][FOUR]++;
	if (TypeCount[MYBLACK][SFOUR]>1)
		TypeCount[MYBLACK][FOUR]++;
	int WValue = 0, BValue = 0;

	if (color== MYWHITE)//�ֵ�������
	{
		if (TypeCount[MYWHITE][FOUR])
		{
			return 9990;//����,��ʤ���ؼ�ֵ
		}
		if (TypeCount[MYWHITE][SFOUR])
		{
			return 9980;//����,��ʤ���ؼ�ֵ
		}
		if (TypeCount[MYBLACK][FOUR])
		{
			return -9970;//���޳��Ļ���,�����л���,��ʤ���ؼ�ֵ
		}
		if (TypeCount[MYBLACK][SFOUR] && TypeCount[MYBLACK][THREE])
		{
			return -9960;//�����г��ĺͻ���,��ʤ���ؼ�ֵ
		}
		if (TypeCount[MYWHITE][THREE] && TypeCount[MYBLACK][SFOUR] == 0)
		{
			return 9950;//���л�������û����,��ʤ���ؼ�ֵ
		}
		if (TypeCount[MYBLACK][THREE]>1 && TypeCount[MYWHITE][SFOUR] == 0 && TypeCount[MYWHITE][THREE] == 0 && TypeCount[MYWHITE][STHREE] == 0)
		{
			return -9940;//�ڵĻ�������һ��,�������ĺ���,��ʤ���ؼ�ֵ
		}
		if (TypeCount[MYWHITE][THREE]>1)
			WValue += 2000;//�׻�������һ��,�����ֵ��2000
		else
			//��������ֵ��200
			if (TypeCount[MYWHITE][THREE])
				WValue += 200;
		if (TypeCount[MYBLACK][THREE]>1)
			BValue += 500;//�ڵĻ�������һ��,�����ֵ��500
		else
			//��������ֵ��100
			if (TypeCount[MYBLACK][THREE])
				BValue += 100;
		//ÿ��������10
		if (TypeCount[MYWHITE][STHREE])
			WValue += TypeCount[MYWHITE][STHREE] * 10;
		//ÿ��������10
		if (TypeCount[MYBLACK][STHREE])
			BValue += TypeCount[MYBLACK][STHREE] * 10;
		//ÿ�������4
		if (TypeCount[MYWHITE][TWO])
			WValue += TypeCount[MYWHITE][TWO] * 4;
		//ÿ�������4
		if (TypeCount[MYBLACK][STWO])
			BValue += TypeCount[MYBLACK][TWO] * 4;
		//ÿ���߶���1
		if (TypeCount[MYWHITE][STWO])
			WValue += TypeCount[MYWHITE][STWO];
		//ÿ���߶���1
		if (TypeCount[MYBLACK][STWO])
			BValue += TypeCount[MYBLACK][STWO];
	}
	else//�ֵ�������
	{
		if (TypeCount[MYBLACK][FOUR])
		{
			return -9990;//����,��ʤ���ؼ�ֵ
		}
		if (TypeCount[MYBLACK][SFOUR])
		{
			return -9980;//����,��ʤ���ؼ�ֵ
		}
		if (TypeCount[MYWHITE][FOUR])
			return 9970;//����,��ʤ���ؼ�ֵ

		if (TypeCount[MYWHITE][SFOUR] && TypeCount[MYWHITE][THREE])
			return 9960;//���Ĳ�����,��ʤ���ؼ�ֵ

		if (TypeCount[MYBLACK][THREE] && TypeCount[MYWHITE][SFOUR] == 0)
			return -9950;//�ڻ���,�����ġ���ʤ���ؼ�ֵ

		if (TypeCount[MYWHITE][THREE]>1 && TypeCount[MYBLACK][SFOUR] == 0 && TypeCount[MYBLACK][THREE] == 0 && TypeCount[MYBLACK][STHREE] == 0)
			return 9940;//�׵Ļ�������һ��,�������ĺ���,��ʤ���ؼ�ֵ

						 //�ڵĻ�������һ��,�����ֵ��2000
		if (TypeCount[MYBLACK][THREE]>1)
			BValue += 2000;
		else
			//��������ֵ��200
			if (TypeCount[MYBLACK][THREE])
				BValue += 200;

		//�׵Ļ�������һ��,�����ֵ�� 500
		if (TypeCount[MYWHITE][THREE]>1)
			WValue += 500;
		else
			//��������ֵ��100
			if (TypeCount[MYWHITE][THREE])
				WValue += 100;

		//ÿ��������10
		if (TypeCount[MYWHITE][STHREE])
			WValue += TypeCount[MYWHITE][STHREE] * 10;
		//ÿ��������10
		if (TypeCount[MYBLACK][STHREE])
			BValue += TypeCount[MYBLACK][STHREE] * 10;
		//ÿ�������4
		if (TypeCount[MYWHITE][TWO])
			WValue += TypeCount[MYWHITE][TWO] * 4;
		//ÿ�������4
		if (TypeCount[MYBLACK][STWO])
			BValue += TypeCount[MYBLACK][TWO] * 4;
		//ÿ���߶���1
		if (TypeCount[MYWHITE][STWO])
			WValue += TypeCount[MYWHITE][STWO];
		//ÿ���߶���1
		if (TypeCount[MYBLACK][STWO])
			BValue += TypeCount[MYBLACK][STWO];
	}

	//�����������ӵ�λ�ü�ֵ
	for (i = 0; i<GRID_NUM; i++)
		for (j = 0; j<GRID_NUM; j++){
			nStoneType = position[i][j];
			if (nStoneType != NOSTONE)
				if (nStoneType == MYBLACK)
					BValue += PosValue[i][j];
				else
					WValue += PosValue[i][j];
		}
	//���ع�ֵ
		return WValue - BValue;
}

//����������ĳ����ˮƽ�����ϵ�����
int AnalysisHorizon(int position[GRID_NUM][GRID_NUM], int i, int j)
{
	//����ֱ�߷�����������
	AnalysisLine(position[i], 15, j);
	//ʰȡ�������
	for (int s = 0; s<15; s++)
		if (m_LineRecord[s] != TOBEANALSIS)
			TypeRecord[i][s][0] = m_LineRecord[s];
	return TypeRecord[i][j][0];
}

//����������ĳ���ڴ�ֱ�����ϵ�����
int AnalysisVertical(int position[GRID_NUM][GRID_NUM], int i, int j)
{
	int tempArray[GRID_NUM];
	//����ֱ�����ϵ�����ת��һά����
	for (int k = 0; k<GRID_NUM; k++)
		tempArray[k] = position[k][j];
	//����ֱ�߷�����������
	AnalysisLine (tempArray, GRID_NUM, i);
	//ʰȡ�������
	for (int s = 0; s<GRID_NUM; s++)
		if (m_LineRecord[s] != TOBEANALSIS)
			TypeRecord[s][j][1] = m_LineRecord[s];

	return TypeRecord[i][j][1];
}

//����������ĳ������б�����ϵ�����
int AnalysisLeft(int position[GRID_NUM][GRID_NUM], int i, int j)
{
	int tempArray[GRID_NUM];
	int x, y;
	int k;
	if (i<j)
	{
		y = 0;
		x = j - i;
	}
	else
	{
		x = 0;
		y = i - j;
	}
	//��б�����ϵ�����ת��һά����
	for (k = 0; k<GRID_NUM; k++)
	{
		if (x + k>14 || y + k>14)
			break;
		tempArray[k] = position[y + k][x + k];
	}
	//����ֱ�߷�����������
	AnalysisLine(tempArray, k, j - x);
	//ʰȡ�������
	for (int s = 0; s<k; s++)
		if (m_LineRecord[s] != TOBEANALSIS)
			TypeRecord[y + s][x + s][2] = m_LineRecord[s];
	return TypeRecord[i][j][2];
}

//����������ĳ������б�����ϵ�����
int AnalysisRight(int position[][GRID_NUM], int i, int j)
{
	int tempArray[GRID_NUM];
	int x, y, realnum;
	int k;
	if (14 - i<j)
	{
		y = 14;
		x = j - 14 + i;
		realnum = 14 - i;
	}
	else
	{
		x = 0;
		y = i + j;
		realnum = j;
	}
	//��б�����ϵ�����ת��һά����
	for (k = 0; k<GRID_NUM; k++)
	{
		if (x + k>14 || y - k<0)
			break;
		tempArray[k] = position[y - k][x + k];
	}
	//����ֱ�߷�����������
	AnalysisLine(tempArray, k, j - x);
	//ʰȡ�������
	for (int s = 0; s<k; s++)
		if (m_LineRecord[s] != TOBEANALSIS)
			TypeRecord[y - s][x + s][3] = m_LineRecord[s];

	return TypeRecord[i][j][3];
}

int AnalysisLine(int* position, int GridNum, int StonePos)
{
	int StoneType;
	int AnalyLine[30];
	int nAnalyPos;
	int LeftEdge, RightEdge;
	int LeftRange, RightRange;

	if (GridNum<5)
	{
		//���鳤��С��5û������
		memset(m_LineRecord, ANALSISED, GridNum*4);
		return 0;
	}
	nAnalyPos = StonePos;
	memset(m_LineRecord, TOBEANALSIS, 30*4);
	memset(AnalyLine, 0x0F, 30*4);
	//����������װ��AnalyLine;
	memcpy(&AnalyLine, position, GridNum*4);
	GridNum--;
	StoneType = AnalyLine[nAnalyPos];
	LeftEdge = nAnalyPos;
	RightEdge = nAnalyPos;
	//������������߽�
	while (LeftEdge>0)
	{
		if (AnalyLine[LeftEdge - 1] != StoneType)
			break;
		LeftEdge--;
	}

	//�����������ұ߽�
	while (RightEdge<GridNum)
	{
		if (AnalyLine[RightEdge + 1] != StoneType)
			break;
		RightEdge++;
	}
	LeftRange = LeftEdge;
	RightRange = RightEdge;
	//��������ѭ��������ӿ��µķ�Χ
	while (LeftRange>0)
	{
		if (AnalyLine[LeftRange - 1] == !StoneType)
			break;
		LeftRange--;
	}
	while (RightRange<GridNum)
	{
		if (AnalyLine[RightRange + 1] == !StoneType)
			break;
		RightRange++;
	}
	//����˷�ΧС��4�����û������
	if (RightRange - LeftRange<4)
	{
		for (int k = LeftRange; k <= RightRange; k++)
			m_LineRecord[k] = ANALSISED;
		return false;
	}
	//������������Ϊ��������,��ֹ�ظ�������һ����
	for (int k = LeftEdge; k <= RightEdge; k++)
		m_LineRecord[k] = ANALSISED;
	if (RightEdge - LeftEdge>3)
	{
		//���������������Ϊ����
		m_LineRecord[nAnalyPos] = FIVE;
		return FIVE;
	}
	if (RightEdge - LeftEdge == 3)
	{
		//���������������Ϊ����
		bool Leftfour = false;
		if (LeftEdge>0)
			if (AnalyLine[LeftEdge - 1] == NOSTONE)
				Leftfour = true;//�������

		if (RightEdge<GridNum)
			//�ұ�δ���߽�
			if (AnalyLine[RightEdge + 1] == NOSTONE)
				//�ұ�����
				if (Leftfour == true)//���������
					m_LineRecord[nAnalyPos] = FOUR;//����
				else
					m_LineRecord[nAnalyPos] = SFOUR;//����
			else
				if (Leftfour == true)//���������
					m_LineRecord[nAnalyPos] = SFOUR;//����
				else
					if (Leftfour == true)//���������
						m_LineRecord[nAnalyPos] = SFOUR;//����

		return m_LineRecord[nAnalyPos];
	}

	if (RightEdge - LeftEdge == 2)
	{
		//���������������Ϊ����
		bool LeftThree = false;
		if (LeftEdge>1)
			if (AnalyLine[LeftEdge - 1] == NOSTONE)
				//�������
				if (LeftEdge>1 && AnalyLine[LeftEdge - 2] == AnalyLine[LeftEdge])
				{
					//��߸�һ�հ��м�������
					m_LineRecord[LeftEdge] = SFOUR;//����
					m_LineRecord[LeftEdge - 2] = ANALSISED;
				}
				else
					LeftThree = true;

		if (RightEdge<GridNum)
			if (AnalyLine[RightEdge + 1] == NOSTONE)
				//�ұ�����
				if (RightEdge<GridNum - 1 && AnalyLine[RightEdge + 2] == AnalyLine[RightEdge])
				{
					//�ұ߸�1����������
					m_LineRecord[RightEdge] = SFOUR;//����
					m_LineRecord[RightEdge + 2] = ANALSISED;
				}
				else
					if (LeftThree == true)//���������
						m_LineRecord[RightEdge] = THREE;//����
					else
						m_LineRecord[RightEdge] = STHREE; //����
			else
			{
				if (m_LineRecord[LeftEdge] == SFOUR)//�������
					return m_LineRecord[LeftEdge];//����

				if (LeftThree == true)//���������
					m_LineRecord[nAnalyPos] = STHREE;//����
			}
		else
		{
			if (m_LineRecord[LeftEdge] == SFOUR)//�������
				return m_LineRecord[LeftEdge];//����
			if (LeftThree == true)//���������
				m_LineRecord[nAnalyPos] = STHREE;//����
		}

		return m_LineRecord[nAnalyPos];
	}

	if (RightEdge - LeftEdge == 1)
	{
		//���������������Ϊ����
		bool Lefttwo = false;
		bool Leftthree = false;

		if (LeftEdge>2)
			if (AnalyLine[LeftEdge - 1] == NOSTONE)
				//�������
				if (LeftEdge - 1>1 && AnalyLine[LeftEdge - 2] == AnalyLine[LeftEdge])
					if (AnalyLine[LeftEdge - 3] == AnalyLine[LeftEdge])
					{
						//��߸�2����������
						m_LineRecord[LeftEdge - 3] = ANALSISED;
						m_LineRecord[LeftEdge - 2] = ANALSISED;
						m_LineRecord[LeftEdge] = SFOUR;//����
					}
					else
						if (AnalyLine[LeftEdge - 3] == NOSTONE)
						{
							//��߸�1����������
							m_LineRecord[LeftEdge - 2] = ANALSISED;
							m_LineRecord[LeftEdge] = STHREE;//����
						}
						else
							Lefttwo = true;

		if (RightEdge<GridNum - 2)
			if (AnalyLine[RightEdge + 1] == NOSTONE)
				//�ұ�����
				if (RightEdge + 1<GridNum - 1 && AnalyLine[RightEdge + 2] == AnalyLine[RightEdge])
					if (AnalyLine[RightEdge + 3] == AnalyLine[RightEdge])
					{
						//�ұ߸�������������
						m_LineRecord[RightEdge + 3] = ANALSISED;
						m_LineRecord[RightEdge + 2] = ANALSISED;
						m_LineRecord[RightEdge] = SFOUR;//����
					}
					else
						if (AnalyLine[RightEdge + 3] == NOSTONE)
						{
							//�ұ߸� 1 ����������
							m_LineRecord[RightEdge + 2] = ANALSISED;
							m_LineRecord[RightEdge] = STHREE;//����
						}
						else
						{
							if (m_LineRecord[LeftEdge] == SFOUR)//��߳���
								return m_LineRecord[LeftEdge];//����

							if (m_LineRecord[LeftEdge] == STHREE)//�������        
								return m_LineRecord[LeftEdge];

							if (Lefttwo == true)
								m_LineRecord[nAnalyPos] = TWO;//���ػ��
							else
								m_LineRecord[nAnalyPos] = STWO;//�߶�
						}
				else
				{
					if (m_LineRecord[LeftEdge] == SFOUR)//���ķ���
						return m_LineRecord[LeftEdge];

					if (Lefttwo == true)//�߶�
						m_LineRecord[nAnalyPos] = STWO;
				}

		return m_LineRecord[nAnalyPos];
	}

	return 0;
}


int CreatePossibleMove(int position[GRID_NUM][GRID_NUM],int color,movelists* movlptr)
{
	int i, j;
	int count = 0;
	for (i = 0; i < GRID_NUM; i++) {
		for (j = 0; j < GRID_NUM; j++){
			if (position[i][j] == NOSTONE) {
				movlptr->push_back(MOVESTONE(color, i, j));
				count++;
			}
		}
	}
	return count;//���غϷ��߷�����
}

//��m_MoveList�в���һ���߷�
//nToX��Ŀ��λ�ú�����
//nToY��Ŀ��λ��������
//nPly�Ǵ��߷����ڵĲ��
AFTERMOVE alphabeta(int position[GRID_NUM][GRID_NUM],int depth, int a, int b,int color) {
	int temp[GRID_NUM][GRID_NUM];
	memcpy(temp, position, GRID_COUNT);
	int count;
	AFTERMOVE retn;
	if (depth <= 0) {
		State state(position);
		AFTERMOVE s(state, Evaluate(position, color));
		retn = s;
		return retn;
	}
	else if (color== MYWHITE) {
		movelists movl;
		count=CreatePossibleMove(position, color, &movl);
		for (int i = 0; i < count; i++) {
			temp[movl[i].ptMovePoint.x][movl[i].ptMovePoint.y] = MYWHITE;
			AFTERMOVE s = alphabeta(temp, depth - 1, a, b, MYBLACK);
			State state(temp);
			AFTERMOVE ret(state , 0);//Ҫ���ص�״̬ ���ڷ�������֪����ʱΪ�� Ȼ���������Ǹ��ķ�������
			if (a < s.score) {
				a = s.score;
				ret.score = s.score;
				retn = ret;
			}
			if (a > b) {
				temp[movl[i].ptMovePoint.x][movl[i].ptMovePoint.y] = NOSTONE;
				break;
			}
			temp[movl[i].ptMovePoint.x][movl[i].ptMovePoint.y] = NOSTONE;
		}
		return retn;
	}
	else if (color == MYBLACK) {
		movelists movl;
		count = CreatePossibleMove(position, color, &movl);
		for (int i = 0; i < count; i++) {
			temp[movl[i].ptMovePoint.x][movl[i].ptMovePoint.y] = MYBLACK;
			AFTERMOVE s = alphabeta(temp, depth - 1, a, b, MYWHITE);
			State state(temp);
			AFTERMOVE ret(state, 0);//Ҫ���ص�״̬ ���ڷ�������֪����ʱΪ�� Ȼ���������Ǹ��ķ�������
			if (b > s.score) {
				b = s.score;
				ret.score = s.score;
				retn = ret;
			}
			if (a > b) {
				temp[movl[i].ptMovePoint.x][movl[i].ptMovePoint.y] = NOSTONE;
				break;
			}
			temp[movl[i].ptMovePoint.x][movl[i].ptMovePoint.y] = NOSTONE;
		}
		return retn;
	}
}
AFTERMOVE makemove(int position[GRID_NUM][GRID_NUM], int color,int depth) {
	AFTERMOVE retn = alphabeta(position, depth, -20000, +20000, color);
	return retn;
}
bool isgameover(int position[GRID_NUM][GRID_NUM],int color) {
	return abs(Evaluate(position,color)) >= 9999;
}
void display(int position[GRID_NUM][GRID_NUM]) {
	for (int i = 0; i < 16; i++) {
		if(i < 10) {
			cout << "0" << i << " ";
		}
		else {
			cout << i  << " ";
			if (i == 15) {
				cout << endl;
			}
		}
	}
	for (int i = 0; i < 15; i++) {
		if (i < 9) {
			cout << "0"<<i + 1 << " ";
		}
		else {
			cout << i + 1 << " ";
		}
		for (int j = 0; j < 15; j++) {
			if (position[i][j] == MYWHITE) {
				cout << " W" << " ";
			}
			else if (position[i][j] == MYBLACK) {
				cout << " B" << " ";
			}
			else {
				cout <<" +"<< " ";
			}
			if (j == 14) {
				cout << endl;
			}
		}
	}
}
void initboard(int position[GRID_NUM][GRID_NUM]) {
	for (int i = 0; i < GRID_NUM; i++) {
		for (int j = 0; j < GRID_NUM; j++) {
			position[i][j] = NOSTONE;
		}
	}
}
void initUI() {
	int distance = 26;
	int length = distance * 16;
	initgraph(length, length);
}
void drawachess(int x, int y,int color) {
	int distance = 26;
	if (color == MYWHITE) {
		setfillcolor(RGB(255,255, 255));
	}
	else if(color==MYBLACK) {
		setfillcolor(RGB(0, 0, 0));
	}
	if (color==MYBLACK||color==MYWHITE) {
		fillcircle(x*distance, y*distance, distance / 2 - 1);
	}
}
void draw(int position[GRID_NUM][GRID_NUM]) {
	int distance = 26;
	int length = distance * 16;
	for (int i = 1; i <=15; i++) {
		line(distance*i, 0, distance*i, length);
	}
	for (int i = 1; i <= 15; i++) {
		line(0,distance*i, length,distance*i);
	}
	for (int i = 0; i < 15; i++) {
		for (int j = 0; j < 15; j++) {
			drawachess(i + 1, j + 1, position[i][j]);
		}
	}
}
int getdistance(int x1, int y1, int x2, int y2) {
	return sqrt((x1 - x2)*(x1 - x2) + (y1 - y2)*(y1 - y2));
}
MYPOINT mousetoboard(int mousex,int mousey) {
	MYPOINT p;
	int distance = 26;
	for (int i = 0; i < 15; i++) {
		for (int j = 0; j < 15; j++) {
			int x = (i + 1)*distance;
			int y = (j + 1)*distance;
			if (getdistance(mousex, mousey, x, y) < distance / 2.0) {
				p.x = i;
				p.y = j;
			}
		}
	}
	return p;
}
int main() {
	int board[GRID_NUM][GRID_NUM];
	initboard(board);
	int playercolor;
	int aicolor;
	int nowcolor = MYBLACK;
	int x;
	int y;
	int step = 0;//����
	int depth = 2;
	cout << "enter your color:black 0,white 1" << endl;
	cin >> playercolor;
	if (playercolor == MYBLACK) {
		aicolor = MYWHITE;
	}
	else {
		aicolor = MYBLACK;
	}
	initUI();
	draw(board);
	while (!isgameover(board,nowcolor)) {
		if(nowcolor==playercolor){
			MOUSEMSG m;
			while (true) {
				m = GetMouseMsg();
				if (m.uMsg == WM_LBUTTONDOWN) {
					int mousex = m.x;
					int mousey = m.y;
					MYPOINT p;
					p = mousetoboard(mousex, mousey);
					x = p.x;
					y = p.y;
					break;
				}
			}
			//cout << "enter your position" << endl;
			//cin >> x >> y;
			board[x][y] = playercolor;//ע��������귵�صľ��Ǵ��㿪ʼ��
			//display(board);
			draw(board);
			nowcolor = aicolor;
			step++;
		}
		else if(nowcolor==aicolor){
			if (step == 0) {
				board[7][7] = MYBLACK;
				//display(board);
				draw(board);
				nowcolor = playercolor;
				step++;
			}
			else {
				AFTERMOVE next = makemove(board, aicolor, depth);
				memcpy(board, next.state.grid, GRID_COUNT);
				//display(board);
				draw(board);
				nowcolor = playercolor;
				step++;
			}
		}
	}
		cout << "OVER" << endl;
		int sdf;
		cin >> sdf;

	return 0;
}