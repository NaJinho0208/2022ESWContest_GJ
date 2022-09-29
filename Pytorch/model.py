import torch.nn as nn
from binarized_modulesCustom import BinarizeLinear, BinarizeConv2d

class AlexNetOWT_BN(nn.Module):

    def __init__(self, num_classes=5):
        super(AlexNetOWT_BN, self).__init__()
        self.outputList = []

        self.conv1 = BinarizeConv2d(in_channels=12, out_channels=48, kernel_size=3, stride=1, padding=1, bias=False)
        self.pool1 = nn.MaxPool2d(kernel_size=2, stride=1)
        self.bn1 = nn.BatchNorm2d(48)
        self.hth1 = nn.Hardtanh(inplace=True)

        self.conv2 = BinarizeConv2d(in_channels=48, out_channels=48, kernel_size=3, stride=1, bias=False)
        self.bn2 = nn.BatchNorm2d(48)
        self.hth2 = nn.Hardtanh(inplace=True)

        self.conv3 = BinarizeConv2d(in_channels=48, out_channels=48, kernel_size=3, stride=1, bias=False)
        self.pool3 = nn.MaxPool2d(kernel_size=2, stride=1)
        self.bn3 = nn.BatchNorm2d(48)
        self.hth3 = nn.Hardtanh(inplace=True)

        self.flatten = nn.Flatten()

        self.fc1 = BinarizeLinear(54*48, num_classes, bias=False)

        self.softmax = nn.LogSoftmax()

    def forward(self, x):
        x, input_conv1 = self.conv1(x)
        x = self.pool1(x)
        x = self.bn1(x)
        x = self.hth1(x)

        x, input_conv2 = self.conv2(x)
        x = self.bn2(x)
        x = self.hth2(x)

        x, input_conv3 = self.conv3(x)
        x = self.pool3(x)
        x = self.bn3(x)
        x = self.hth3(x)

        x = self.flatten(x)

        x, input_fc1 = self.fc1(x)

        # x = self.softmax(x)

        return x, input_conv1, input_conv2, input_conv3, input_fc1