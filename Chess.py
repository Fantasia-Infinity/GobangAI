# -*- coding: utf-8 -*-
"""
Created on Tue Apr 25 15:38:16 2017

@author: Fantasia
"""
import copy as cp
import random
k=9#棋盘大小
d=2#搜索层数
class Chessboard:
    def __init__(self):
        self.board=[]
        for i in range(k):
            self.board.append([])
        for i in range(k):
            for j in range(k):
                self.board[i].append(0)
    def newchess(self,x,y,color):#黑为-1 白为1 给人类使用
        self.board[x][y]=color
    def assess(self,board):#未完成的评估函数 返回一个表示棋局偏向的值 白↑黑↓
        return random.randint(1,100)
    def posnext(self,board,color):#可能的走法 此处color为轮到下的颜色（还没下）
        l=[]
        for i in range(k):
            for j in range(k):
                if board[i][j]==0:
                    a=[-2,-1,0,1,2]
                    for s in a:
                        for d in a:
                            if not (s==0 and d==0):
                                if self.inrange(i+s,j+d):
                                    if board[i+s][j+d]!=0:#待进一步剪枝...
                                        newboard=cp.deepcopy(board)
                                        newboard[i][j]=color
                                        l.append(newboard)
                                        break
        return l
    def maxminsearch(self,board,color,n):#此处color也为轮到下的颜色（还没下）
        if n==0:
            return self.assess(board)
        elif color==1:
            ls=self.posnext(board,color)
            return max([self.maxminsearch(b,-color,n-1) for b in ls])
        elif color==-1:
            ls=self.posnext(board,color)
            return min([self.maxminsearch(b,-color,n-1) for b in ls])
    def newcomchess(self,color):#程序下一步棋 color为待落的子色
        def mms(board):
            return self.maxminsearch(board,color,d)
        if color==1:
            nextboard=max(self.posnext(self.board,color),key=mms)
            self.board=nextboard
        elif color==-1:
            nextboard=min(self.posnext(self.board,color),key=mms)
            self.board=nextboard
    def inrange(self,x,y):#判断一个位置在不在棋盘之内
        return (x in range(k)) and (y in range(k))
    def checkfive(self,board,x,y,color):
        def checkline(board,x,y,color):
            def countleft(board,x,y,color):
                if not self.inrange(x,y-1):
                    return 0
                elif board[x][y-1]!=color:
                    return 0
                else:
                    return 1+countleft(board,x,y-1,color)
            def countright(boart,x,y,color):
                if not self.inrange(x,y+1):
                    return 0
                elif board[x][y+1]!=color:
                    return 0
                else:
                    return 1+countright(board,x,y+1,color)
            count=countleft(board,x,y,color)+countright(board,x,y,color)
            return count>=4
        def checkrow(board,x,y,color):
            def countup(board,x,y,color):
                if not self.inrange(x-1,y):
                    return 0
                elif board[x-1][y]!=color:
                    return 0
                else:
                    return 1+countup(board,x-1,y,color)
            def countdown(board,x,y,color):
                if not self.inrange(x+1,y):
                    return 0
                elif board[x+1][y]!=color:
                    return 0
                else:
                    return 1+countdown(board,x+1,y,color)
            count=countup(board,x,y,color)+countdown(board,x,y,color)
            return count>=4
        def checkyszx(board,x,y,color):
            def countys(board,x,y,color):
                if not self.inrange(x-1,y+1):
                    return 0
                elif board[x-1][y+1]!=color:
                    return 0
                else:
                    return countys(board,x-1,y+1,color)
            def countzx(board,x,y,color):
                if not self.inrange(x+1,y-1):
                    return 0
                elif board[x+1][y-1]!=color:
                    return 0
                else:
                    return countzx(board,x+1,y-1,color)
            count=countys(board,x,y,color)+countzx(board,x,y,color)
            return count>=4
        def checkzsyx(board,x,y,color):
            def countzs(board,x,y,color):
                if not self.inrange(x-1,y-1):
                    return 0
                elif board[x-1][y-1]!=color:
                    return 0
                else:
                    return countzs(board,x-1,y-1,color)
            def countys(board,x,y,color):
                if not self.inrange(x+1,y+1):
                    return 0
                elif board[x+1][y+1]!=color:
                    return 0
                else:
                    return countys(board,x+1,y+1,color)
            count=countzs(board,x,y,color)+countys(board,x,y,color)
            return count>=4
        a=checkline(board,x,y,color) or checkrow(board,x,y,color)
        b=checkzsyx(board,x,y,color) or checkyszx(board,x,y,color)
        return (a or b)
    def show(self):
        for l in self.board:
            print l
        print ''
    def game(self):
        state=True
        player=input("first:1 second:-1")
        if player==1:
            while state:
                x,y=input("position:")
                self.newchess(x,y,player)
                self.newcomchess(-player)
                self.show()
        
        
        
    
    
        
            
            
        
        
    
        
