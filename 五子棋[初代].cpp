#include <cstdlib>
#include <iostream>
#include<stdlib.h>
#include<string.h>
#include<time.h>
#include<vector>
#include<algorithm>
#include <graphics.h>      // 引用图形库头文件
#include <conio.h>
#define GRID_NUM    15 //每一行(列)的棋盘交点数
#define GRID_COUNT  225*4//棋盘内存大小
#define MYBLACK        0 //黑棋用0表示
#define MYWHITE        1 //白棋用1表示
#define NOSTONE     9  //没有棋子
//这组宏定义了用以代表几种棋型的数字
#define STWO        1  //眠二
#define STHREE        2  //眠三
#define SFOUR        3  //冲四
#define TWO        4  //活二
#define THREE        5  //活三
#define FOUR        6  //活四
#define FIVE        7  //五连
#define NOTYPE        11 //未定义
#define ANALSISED   255//已分析过的
#define TOBEANALSIS 0  //已分析过的
//这个宏用以检查某一坐标是否是棋盘上的有效落子点
#define IsValidPos(x,y) ((x>=0 && x<GRID_NUM) && (y>=0 && y<GRID_NUM)
//定义了枚举型的数据类型，精确，下边界，上边界
using namespace std;
//全局变量,用以统计估值函数的执行遍数

//在搜索层数为3的时候有debug版和release版行为不一样（一个会变成智障）的玄学问题....暂时不知道为什么

int ccount = 0;
typedef struct Node
{
	int x;
	int y;
}MYPOINT;

//用以表示棋子位置的结构

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
//这个结构用以表示走法
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
	State state;//这一步之后的状态
	int score;        //走法的分数
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

int AnalysisLine(int* position, int GridNum, int StonePos);
int AnalysisRight(int position[GRID_NUM][GRID_NUM], int i, int j);
int AnalysisLeft(int position[GRID_NUM][GRID_NUM], int i, int j);
int AnalysisVertical(int position[GRID_NUM][GRID_NUM], int i, int j);
int AnalysisHorizon(int position[GRID_NUM][GRID_NUM], int i, int j);
//int Evaluate(unsigned int position[][GRID_NUM], bool bIsWhiteTurn);
int CreatePossibleMove(int position[GRID_NUM][GRID_NUM], int nPly, int nSide);
void display(int position[GRID_NUM][GRID_NUM]);



int m_LineRecord[30];          //存放AnalysisLine分析结果的数组
int TypeRecord[GRID_NUM][GRID_NUM][4];//存放全部分析结果的数组,有三个维度,用于存放水平、垂直、左斜、右斜 4 个方向上所有棋型分析结果
int TypeCount[2][20];          //存放统记过的分析结果的数组
int m_nMoveCount;//此变量用以记录走法的总数  
int m_nSearchDepth;        //最大搜索深度
int MaxDepth=2;        //当前搜索的最大搜索深度
							   //CSearchEngine* m_pSE;         //搜索引擎指针 
										 //位置重要性价值表,此表从中间向外,越往外价值越低
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
	ccount++;//计数器累加
			  //清空棋型分析结果
	memset(TypeRecord, TOBEANALSIS, GRID_NUM*GRID_NUM * 4*4);
	memset(TypeCount, 0, 40 * 4);

	for (i = 0; i<GRID_NUM; i++)
		for (j = 0; j<GRID_NUM; j++)
		{
			if (position[i][j] != NOSTONE)
			{
				//如果水平方向上没有分析过
				if (TypeRecord[i][j][0] == TOBEANALSIS)
					AnalysisHorizon(position, i, j);

				//如果垂直方向上没有分析过
				if (TypeRecord[i][j][1] == TOBEANALSIS)
					AnalysisVertical(position, i, j);

				//如果左斜方向上没有分析过
				if (TypeRecord[i][j][2] == TOBEANALSIS)
					AnalysisLeft(position, i, j);

				//如果右斜方向上没有分析过
				if (TypeRecord[i][j][3] == TOBEANALSIS)
					AnalysisRight(position, i, j);
			}
		}
	//对分析结果进行统计,得到每种棋型的数量
	for (i = 0; i<GRID_NUM; i++)
		for (j = 0; j<GRID_NUM; j++)
			for (k = 0; k<4; k++){
				nStoneType = position[i][j];
				if (nStoneType != NOSTONE){
					switch (TypeRecord[i][j][k])
					{
					case FIVE://五连
						TypeCount[nStoneType][FIVE]++;
						break;
					case FOUR://活四
						TypeCount[nStoneType][FOUR]++;
						break;
					case SFOUR://冲四
						TypeCount[nStoneType][SFOUR]++;
						break;
					case THREE://活三
						TypeCount[nStoneType][THREE]++;
						break;
					case STHREE://眠三
						TypeCount[nStoneType][STHREE]++;
						break;
					case TWO://活二
						TypeCount[nStoneType][TWO]++;
						break;
					case STWO://眠二
						TypeCount[nStoneType][STWO]++;
						break;
					default:
						break;
					}
				}
			}
	//如果已五连,返回极值

	if (TypeCount[MYBLACK][FIVE])
	{
		return -9999;
	}
	if (TypeCount[MYWHITE][FIVE])
	{
		return 9999;
	}

	//两个冲四等于一个活四
	if (TypeCount[MYWHITE][SFOUR]>1)
		TypeCount[MYWHITE][FOUR]++;
	if (TypeCount[MYBLACK][SFOUR]>1)
		TypeCount[MYBLACK][FOUR]++;
	int WValue = 0, BValue = 0;

	if (color== MYWHITE)//轮到白棋走
	{
		if (TypeCount[MYWHITE][FOUR])
		{
			return 9990;//活四,白胜返回极值
		}
		if (TypeCount[MYWHITE][SFOUR])
		{
			return 9980;//冲四,白胜返回极值
		}
		if (TypeCount[MYBLACK][FOUR])
		{
			return -9970;//白无冲四活四,而黑有活四,黑胜返回极值
		}
		if (TypeCount[MYBLACK][SFOUR] && TypeCount[MYBLACK][THREE])
		{
			return -9960;//而黑有冲四和活三,黑胜返回极值
		}
		if (TypeCount[MYWHITE][THREE] && TypeCount[MYBLACK][SFOUR] == 0)
		{
			return 9950;//白有活三而黑没有四,白胜返回极值
		}
		if (TypeCount[MYBLACK][THREE]>1 && TypeCount[MYWHITE][SFOUR] == 0 && TypeCount[MYWHITE][THREE] == 0 && TypeCount[MYWHITE][STHREE] == 0)
		{
			return -9940;//黑的活三多于一个,而白无四和三,黑胜返回极值
		}
		if (TypeCount[MYWHITE][THREE]>1)
			WValue += 2000;//白活三多于一个,白棋价值加2000
		else
			//否则白棋价值加200
			if (TypeCount[MYWHITE][THREE])
				WValue += 200;
		if (TypeCount[MYBLACK][THREE]>1)
			BValue += 500;//黑的活三多于一个,黑棋价值加500
		else
			//否则黑棋价值加100
			if (TypeCount[MYBLACK][THREE])
				BValue += 100;
		//每个眠三加10
		if (TypeCount[MYWHITE][STHREE])
			WValue += TypeCount[MYWHITE][STHREE] * 10;
		//每个眠三加10
		if (TypeCount[MYBLACK][STHREE])
			BValue += TypeCount[MYBLACK][STHREE] * 10;
		//每个活二加4
		if (TypeCount[MYWHITE][TWO])
			WValue += TypeCount[MYWHITE][TWO] * 4;
		//每个活二加4
		if (TypeCount[MYBLACK][STWO])
			BValue += TypeCount[MYBLACK][TWO] * 4;
		//每个眠二加1
		if (TypeCount[MYWHITE][STWO])
			WValue += TypeCount[MYWHITE][STWO];
		//每个眠二加1
		if (TypeCount[MYBLACK][STWO])
			BValue += TypeCount[MYBLACK][STWO];
	}
	else//轮到黑棋走
	{
		if (TypeCount[MYBLACK][FOUR])
		{
			return -9990;//活四,黑胜返回极值
		}
		if (TypeCount[MYBLACK][SFOUR])
		{
			return -9980;//冲四,黑胜返回极值
		}
		if (TypeCount[MYWHITE][FOUR])
			return 9970;//活四,白胜返回极值

		if (TypeCount[MYWHITE][SFOUR] && TypeCount[MYWHITE][THREE])
			return 9960;//冲四并活三,白胜返回极值

		if (TypeCount[MYBLACK][THREE] && TypeCount[MYWHITE][SFOUR] == 0)
			return -9950;//黑活三,白无四。黑胜返回极值

		if (TypeCount[MYWHITE][THREE]>1 && TypeCount[MYBLACK][SFOUR] == 0 && TypeCount[MYBLACK][THREE] == 0 && TypeCount[MYBLACK][STHREE] == 0)
			return 9940;//白的活三多于一个,而黑无四和三,白胜返回极值

						 //黑的活三多于一个,黑棋价值加2000
		if (TypeCount[MYBLACK][THREE]>1)
			BValue += 2000;
		else
			//否则黑棋价值加200
			if (TypeCount[MYBLACK][THREE])
				BValue += 200;

		//白的活三多于一个,白棋价值加 500
		if (TypeCount[MYWHITE][THREE]>1)
			WValue += 500;
		else
			//否则白棋价值加100
			if (TypeCount[MYWHITE][THREE])
				WValue += 100;

		//每个眠三加10
		if (TypeCount[MYWHITE][STHREE])
			WValue += TypeCount[MYWHITE][STHREE] * 10;
		//每个眠三加10
		if (TypeCount[MYBLACK][STHREE])
			BValue += TypeCount[MYBLACK][STHREE] * 10;
		//每个活二加4
		if (TypeCount[MYWHITE][TWO])
			WValue += TypeCount[MYWHITE][TWO] * 4;
		//每个活二加4
		if (TypeCount[MYBLACK][STWO])
			BValue += TypeCount[MYBLACK][TWO] * 4;
		//每个眠二加1
		if (TypeCount[MYWHITE][STWO])
			WValue += TypeCount[MYWHITE][STWO];
		//每个眠二加1
		if (TypeCount[MYBLACK][STWO])
			BValue += TypeCount[MYBLACK][STWO];
	}

	//加上所有棋子的位置价值
	for (i = 0; i<GRID_NUM; i++)
		for (j = 0; j<GRID_NUM; j++){
			nStoneType = position[i][j];
			if (nStoneType != NOSTONE)
				if (nStoneType == MYBLACK)
					BValue += PosValue[i][j];
				else
					WValue += PosValue[i][j];
		}
	//返回估值
		return WValue - BValue;
}

//分析棋盘上某点在水平方向上的棋型
int AnalysisHorizon(int position[GRID_NUM][GRID_NUM], int i, int j)
{
	//调用直线分析函数分析
	AnalysisLine(position[i], 15, j);
	//拾取分析结果
	for (int s = 0; s<15; s++)
		if (m_LineRecord[s] != TOBEANALSIS)
			TypeRecord[i][s][0] = m_LineRecord[s];
	return TypeRecord[i][j][0];
}

//分析棋盘上某点在垂直方向上的棋型
int AnalysisVertical(int position[GRID_NUM][GRID_NUM], int i, int j)
{
	int tempArray[GRID_NUM];
	//将垂直方向上的棋子转入一维数组
	for (int k = 0; k<GRID_NUM; k++)
		tempArray[k] = position[k][j];
	//调用直线分析函数分析
	AnalysisLine (tempArray, GRID_NUM, i);
	//拾取分析结果
	for (int s = 0; s<GRID_NUM; s++)
		if (m_LineRecord[s] != TOBEANALSIS)
			TypeRecord[s][j][1] = m_LineRecord[s];

	return TypeRecord[i][j][1];
}

//分析棋盘上某点在左斜方向上的棋型
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
	//将斜方向上的棋子转入一维数组
	for (k = 0; k<GRID_NUM; k++)
	{
		if (x + k>14 || y + k>14)
			break;
		tempArray[k] = position[y + k][x + k];
	}
	//调用直线分析函数分析
	AnalysisLine(tempArray, k, j - x);
	//拾取分析结果
	for (int s = 0; s<k; s++)
		if (m_LineRecord[s] != TOBEANALSIS)
			TypeRecord[y + s][x + s][2] = m_LineRecord[s];
	return TypeRecord[i][j][2];
}

//分析棋盘上某点在右斜方向上的棋型
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
	//将斜方向上的棋子转入一维数组
	for (k = 0; k<GRID_NUM; k++)
	{
		if (x + k>14 || y - k<0)
			break;
		tempArray[k] = position[y - k][x + k];
	}
	//调用直线分析函数分析
	AnalysisLine(tempArray, k, j - x);
	//拾取分析结果
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
		//数组长度小于5没有意义
		memset(m_LineRecord, ANALSISED, GridNum*4);
		return 0;
	}
	nAnalyPos = StonePos;
	memset(m_LineRecord, TOBEANALSIS, 30*4);
	memset(AnalyLine, 0x0F, 30*4);
	//将传入数组装入AnalyLine;
	memcpy(&AnalyLine, position, GridNum*4);
	GridNum--;
	StoneType = AnalyLine[nAnalyPos];
	LeftEdge = nAnalyPos;
	RightEdge = nAnalyPos;
	//算连续棋子左边界
	while (LeftEdge>0)
	{
		if (AnalyLine[LeftEdge - 1] != StoneType)
			break;
		LeftEdge--;
	}

	//算连续棋子右边界
	while (RightEdge<GridNum)
	{
		if (AnalyLine[RightEdge + 1] != StoneType)
			break;
		RightEdge++;
	}
	LeftRange = LeftEdge;
	RightRange = RightEdge;
	//下面两个循环算出棋子可下的范围
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
	//如果此范围小于4则分析没有意义
	if (RightRange - LeftRange<4)
	{
		for (int k = LeftRange; k <= RightRange; k++)
			m_LineRecord[k] = ANALSISED;
		return false;
	}
	//将连续区域设为分析过的,防止重复分析此一区域
	for (int k = LeftEdge; k <= RightEdge; k++)
		m_LineRecord[k] = ANALSISED;
	if (RightEdge - LeftEdge>3)
	{
		//如待分析棋子棋型为五连
		m_LineRecord[nAnalyPos] = FIVE;
		return FIVE;
	}
	if (RightEdge - LeftEdge == 3)
	{
		//如待分析棋子棋型为四连
		bool Leftfour = false;
		if (LeftEdge>0)
			if (AnalyLine[LeftEdge - 1] == NOSTONE)
				Leftfour = true;//左边有气

		if (RightEdge<GridNum)
			//右边未到边界
			if (AnalyLine[RightEdge + 1] == NOSTONE)
				//右边有气
				if (Leftfour == true)//如左边有气
					m_LineRecord[nAnalyPos] = FOUR;//活四
				else
					m_LineRecord[nAnalyPos] = SFOUR;//冲四
			else
				if (Leftfour == true)//如左边有气
					m_LineRecord[nAnalyPos] = SFOUR;//冲四
				else
					if (Leftfour == true)//如左边有气
						m_LineRecord[nAnalyPos] = SFOUR;//冲四

		return m_LineRecord[nAnalyPos];
	}

	if (RightEdge - LeftEdge == 2)
	{
		//如待分析棋子棋型为三连
		bool LeftThree = false;
		if (LeftEdge>1)
			if (AnalyLine[LeftEdge - 1] == NOSTONE)
				//左边有气
				if (LeftEdge>1 && AnalyLine[LeftEdge - 2] == AnalyLine[LeftEdge])
				{
					//左边隔一空白有己方棋子
					m_LineRecord[LeftEdge] = SFOUR;//冲四
					m_LineRecord[LeftEdge - 2] = ANALSISED;
				}
				else
					LeftThree = true;

		if (RightEdge<GridNum)
			if (AnalyLine[RightEdge + 1] == NOSTONE)
				//右边有气
				if (RightEdge<GridNum - 1 && AnalyLine[RightEdge + 2] == AnalyLine[RightEdge])
				{
					//右边隔1个己方棋子
					m_LineRecord[RightEdge] = SFOUR;//冲四
					m_LineRecord[RightEdge + 2] = ANALSISED;
				}
				else
					if (LeftThree == true)//如左边有气
						m_LineRecord[RightEdge] = THREE;//活三
					else
						m_LineRecord[RightEdge] = STHREE; //冲三
			else
			{
				if (m_LineRecord[LeftEdge] == SFOUR)//如左冲四
					return m_LineRecord[LeftEdge];//返回

				if (LeftThree == true)//如左边有气
					m_LineRecord[nAnalyPos] = STHREE;//眠三
			}
		else
		{
			if (m_LineRecord[LeftEdge] == SFOUR)//如左冲四
				return m_LineRecord[LeftEdge];//返回
			if (LeftThree == true)//如左边有气
				m_LineRecord[nAnalyPos] = STHREE;//眠三
		}

		return m_LineRecord[nAnalyPos];
	}

	if (RightEdge - LeftEdge == 1)
	{
		//如待分析棋子棋型为二连
		bool Lefttwo = false;
		bool Leftthree = false;

		if (LeftEdge>2)
			if (AnalyLine[LeftEdge - 1] == NOSTONE)
				//左边有气
				if (LeftEdge - 1>1 && AnalyLine[LeftEdge - 2] == AnalyLine[LeftEdge])
					if (AnalyLine[LeftEdge - 3] == AnalyLine[LeftEdge])
					{
						//左边隔2个己方棋子
						m_LineRecord[LeftEdge - 3] = ANALSISED;
						m_LineRecord[LeftEdge - 2] = ANALSISED;
						m_LineRecord[LeftEdge] = SFOUR;//冲四
					}
					else
						if (AnalyLine[LeftEdge - 3] == NOSTONE)
						{
							//左边隔1个己方棋子
							m_LineRecord[LeftEdge - 2] = ANALSISED;
							m_LineRecord[LeftEdge] = STHREE;//眠三
						}
						else
							Lefttwo = true;

		if (RightEdge<GridNum - 2)
			if (AnalyLine[RightEdge + 1] == NOSTONE)
				//右边有气
				if (RightEdge + 1<GridNum - 1 && AnalyLine[RightEdge + 2] == AnalyLine[RightEdge])
					if (AnalyLine[RightEdge + 3] == AnalyLine[RightEdge])
					{
						//右边隔两个己方棋子
						m_LineRecord[RightEdge + 3] = ANALSISED;
						m_LineRecord[RightEdge + 2] = ANALSISED;
						m_LineRecord[RightEdge] = SFOUR;//冲四
					}
					else
						if (AnalyLine[RightEdge + 3] == NOSTONE)
						{
							//右边隔 1 个己方棋子
							m_LineRecord[RightEdge + 2] = ANALSISED;
							m_LineRecord[RightEdge] = STHREE;//眠三
						}
						else
						{
							if (m_LineRecord[LeftEdge] == SFOUR)//左边冲四
								return m_LineRecord[LeftEdge];//返回

							if (m_LineRecord[LeftEdge] == STHREE)//左边眠三        
								return m_LineRecord[LeftEdge];

							if (Lefttwo == true)
								m_LineRecord[nAnalyPos] = TWO;//返回活二
							else
								m_LineRecord[nAnalyPos] = STWO;//眠二
						}
				else
				{
					if (m_LineRecord[LeftEdge] == SFOUR)//冲四返回
						return m_LineRecord[LeftEdge];

					if (Lefttwo == true)//眠二
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
	return count;//返回合法走法个数
}

//在m_MoveList中插入一个走法
//nToX是目标位置横坐标
//nToY是目标位置纵坐标
//nPly是此走法所在的层次
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
			AFTERMOVE ret(state , 0);//要返回的状态 由于分数还不知道暂时为零 然后由上面那个的分数给它
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
			AFTERMOVE ret(state, 0);//要返回的状态 由于分数还不知道暂时为零 然后由上面那个的分数给它
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
	int step = 0;//步数
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
			board[x][y] = playercolor;//注意这里鼠标返回的就是从零开始的
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


