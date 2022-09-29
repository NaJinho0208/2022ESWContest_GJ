import os
import torchvision.datasets as datasets
import glob
import numpy as np
import pandas as pd
import torchvision.transforms as transforms

#------------------------------
# 저장된 csv 파일을 데이터셋으로 변환: 데이터셋 함수 선언
# Dataset0 : 양발&한발 / 6축 전부
#------------------------------
import torch
from torch.utils.data import Dataset

'''
Custom dataset: 기존 데이터셋과 유사함, 그러나 정의한 csv 파일을 가져오는 클래스
# 내부 구조 설명:
# CustomDataset(Dataset): 파이썬에선 상속 시 괄호 안에 부모 클래스 이름을 넣고 정의하면 됨
# __init__(self, ...): 생성자, 이때 내부 메소드엔 반드시 self를 첫 인자로 넣는데, 이것은 객체를 인자로 받는 파이썬만의 특징임
# __len__, __getitem__: 상속받은 Dataset에서도 정의된 메소드, 반드시 구현해야 하며 각각 데이터셋의 길이와 긁어올 텐서 값을 결정
'''

class CustomDataset(Dataset):
    classes = [] # 클래스 값을 가진 리스트
    def __init__(self, filenames, transform, shuffle=False):
        # `filenames` 불러올 모든 파일 이름을 가진 리스트
        # `batch_size` 한번에 긁어올 파일 개수를 결정 <<<< Loader에서 결정
        # 클래스 수를 확인하고 내부의 파일을 리스트로 만들어 self.filenames에 저장
        self.classes = ['Normal', 'ToeoutB', 'ToeoutS', 'ToeinB', 'ToeinS']
        self.transform = transform
        dataset_list = []
        for clss in self.classes:
            temp = glob.glob(filenames + "/" + clss + "/*")
            dataset_list += temp
        if shuffle == True:
            np.random.shuffle(dataset_list)
        self.filenames= dataset_list

    # 데이터셋의 클래스 수를 반환하는 메서드: 기존 Dataset.py엔 없음
    def __getclass__(self):
        return self.classes

    # 데이터 전체 수를 반환하는 메서드: 기존 Dataset.py엔 없음
    def __len__(self):
        return len(self.filenames)

    def __getitem__(self, idx): 
        # 'idx' 차례대로 불러올 인덱스값
        # 청크에서 파일을 읽고, 해당 파일의 라벨과 데이터 부분을 분리하고 반환 
        labels = []

        # 배치 사이즈 고려하지 않고 한개의 데이터만 반환
        file = self.filenames[idx]
        
        # open: 파이선 내장함수, file에 대해 모드에 맞게 파일을 열음. r의 경우 읽기 모드
        # pd.read_csv: pandas 내장함수, 해당 csv 파일에 대해 같은 행과 열을 가진 dataFrame을 생성
        temp = pd.read_csv(open(file,'r')) # 파일을 읽기 모드로 열고, 행과 열을 가진 temp 배열 생성
        #labels.append(int(temp.columns[0]) - 1) # dataFrame의 Column index의 첫 값이 Label임: Label 저장
        
        labels = int(temp.columns[0]) - 1 # label 값 한 개
        temp = np.array(temp, dtype = np.float32) # numpy array로 형태 변환: Label은 인덱스 부분이라 자동으로 인식되지않고 사라짐

        # 데이터를 오른발과 왼발 부분으로 쪼개어 6x15x12 형태로 가공: 만약 한쪽 발의 데이터만 쓴다면 이 부분 수정
        sliceIndex = len(temp) / 2
        tempLeft = temp[ : int(sliceIndex)]
        tempRight = temp[int(sliceIndex) : ]
        tempLeft = tempLeft.reshape(6, 15, 12)
        tempRight = tempRight.reshape(6, 15, 12)
        temp = np.concatenate((tempLeft,tempRight), axis = 0) # 6x15x12의 왼발/오른발 데이터 합성 -> 12x15x12
        temp = temp.transpose((0, 2, 1)).copy()
        temp = np.flip(temp, axis=1).copy()

        # 가공한 하나의 스펙트로그램 데이터 transform
        data = self.transform(torch.from_numpy(temp))

        # The following condition is actually needed in Pytorch. Otherwise, for our particular example, the iterator will be an infinite loop.
        # Readers can verify this by removing this condition.
        if idx == self.__len__():  
            raise IndexError

        return data, labels