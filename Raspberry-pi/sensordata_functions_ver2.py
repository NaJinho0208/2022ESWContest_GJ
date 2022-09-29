"""
SensorData Functions Code Ver2 (functions and variables declared, Bluetooth Module version)
"""


from datetime import datetime
from logging import exception
import time
import numpy as np
import smbus
import scipy.fftpack as fft
import gait_plot as plt
from bluetooth import *

## define section
GYRO_FS_SEL = 0  # (±250 degree/s)
ACCEL_FS_SEL = 1  # (±4g)

## global object Section
bt_temp = []  # global object for btgetarray function

# bluetooth data transaction
def btgetarray(socket, result, length):
    bt_temp.extend(list(socket.recv(1024)))
    if len(bt_temp) < length:
        btgetarray(socket, result, length)
    else:
        for j in range(int(len(bt_temp) / 2)):  # 8bit로 전송된 byte 데이터를 2byte 데이터로 다시 합병
            result.append(np.int16((bt_temp[2 * j] << 8) | bt_temp[2 * j + 1]))
        bt_temp.clear()
        return result


# bluetooth data accumulation
def btgetarrays(socket, sample_size):
    data = []
    try:
        socket.send((1).to_bytes(1, byteorder="little"))  # 아두이노에게 시작 신호 전송

        for i in range(sample_size):  # 32 x 32 = 1024 sample
            temp = []
            btgetarray(socket, temp, 384)
            for j in range(int(len(temp) / 2)):  # 8bit로 전송된 byte 데이터를 2byte 데이터로 다시 합병
                data.append(np.int16((temp[2 * j] << 8) | temp[2 * j + 1]))
            # print(data)
            print("length of data: " + str(len(data)))
            socket.send((1).to_bytes(1, byteorder="little"))  # 아두이노에게 시작 신호 전송
    except KeyboardInterrupt:
        print("Finished")


## integer to float data conversion
def int2float(data):
    acc_scale = 2 + ACCEL_FS_SEL * 2
    gyr_scale = 250 + GYRO_FS_SEL * 250
    result = []
    for j in range(int(len(data) / 6)):
        for i in range(3):
            result.append(data[(6 * j) + i] * acc_scale / 32768 * 0.003)
        for i in range(3):
            result.append(
                data[(6 * j) + (3 + i)] * gyr_scale / 32768 * 0.003
            )  # must multiply 1/Fs
    return result


## FOR threading: input sensor data to (6, 128) size array
def data_processing(
    left_in, right_in, unit, iter, left_out, right_out, left_fft, right_fft
):
    past = time.time()  # time measure
    # data plot (execute when j = 0, Not at First data processing)
    # if loop_count != 0 and iter == 0:
    #    plt.gait_plot(plt_spec, plt_data)
    # data processing (FFT)
    left_in = int2float(left_in)
    right_in = int2float(right_in)
    for k in range(unit):
        for i in range(6):
            left_out[i][k + (iter * unit)] = left_in[(k * 6) + i]
            right_out[i][k + (iter * unit)] = right_in[(k * 6) + i]

    if iter != 1 and iter % 2 == 1:
        data_fft(left_out, right_out, int((iter - 3) / 2), left_fft, right_fft)

    recent = float((time.time() - past) * 1000)  # millisecond unit
    # print(
    #    "{} * {} amount sample CPU only time: {:.2f}ms".format(iter, unit, recent)
    # )  # CPU time print
    return


## FOR threading: dc-norm data and get fft data
def data_fft(left_in, right_in, order, left_fft, right_fft):
    # past = time.time()
    global dc_biasL
    global dc_biasR
    for i in range(6):
        point_arr = left_in[i][(order * 64) : (order * 64 + 128)]
        if order == 0 and i == 2:
            dc_biasL = point_arr.mean()
        if i == 2:
            point_arr = point_arr - dc_biasL  # accel z axis norm: 1 is dc value
        temp = np.abs(fft.fft(point_arr, n=128))
        for j in range(12):
            left_fft[i][(order * 12) + j] = temp[j]
    for i in range(6):
        point_arr = right_in[i][(order * 64) : (order * 64 + 128)]
        if order == 0 and i == 2:
            dc_biasR = point_arr.mean()
        if i == 2:
            point_arr = point_arr - dc_biasR  # accel z axis norm: 1 is dc value
        temp = np.abs(fft.fft(point_arr, n=128))
        for j in range(12):
            right_fft[i][(order * 12) + j] = temp[j]

    # recent = float((time.time() - past) * 1000)  # millisecond unit
    # print("fft time spent: {:.2f}".format(recent))  # fft time print
    return


import spidev
import os

## FOR threading: data 2 spi processing function
# Normalizing & spi send/receive
# data_tmp: data to send
# receive_only: skip sending, only receive data
def data2spi(data_tmp, receive_only=False):
    past = time.time()
    spi = spidev.SpiDev()  # define spi module
    spi.open(0, 0)  # open spi
    spi.mode = 1  # CPOL:0, CPHA:1 => MISO/MOSI updates at pos edge.
    spi.max_speed_hz = 25000000  # 2.5Mhz Max clock

    if receive_only:
        temp = np.zeros(16, dtype=int).flatten().tolist()
        miso = spi.xfer2(temp)  # only receive: get 10 bytes
    else:
        data = np.zeros(shape=(12, 15, 12))

        for i in range(12):
            tmp1 = data_tmp[i, :].reshape(15, 12)
            tmp2 = np.rot90(tmp1)
            data[:, :, 11 - i] = tmp2  # put data reversely

        mean = [
            0.022864,
            0.016581,
            0.018955,
            1.9266,
            3.6982,
            1.6796,
            0.02268,
            0.016511,
            0.019214,
            2.0609,
            3.725,
            1.6977,
        ]
        std = [
            0.039005,
            0.023538,
            0.032722,
            3.4016,
            7.8508,
            3.3401,
            0.036059,
            0.024486,
            0.03225,
            3.5045,
            7.7277,
            3.3724,
        ]

        for i in range(12):
            data[:, :, i] = (data[:, :, i] - mean[11 - i]) / std[11 - i]  # Normalize

        data_Q84 = (data * (2**4)).astype("int")  # 소수점 제거
        data_Q84[data_Q84 < -128] = -128  # Clipping
        data_Q84[data_Q84 > 127] = 127  # Clipping

        data_Q84 = data_Q84.astype("uint8")  # 8bit 표현
        data_Q84 = data_Q84.flatten()
        data_Q84 = np.concatenate((data_Q84, np.zeros(12, dtype=int)), axis=0)
        data_Q84 = data_Q84.tolist()  # 1차원 list 형태로 변환
        data_Q84.append(0)  # 쓰레기값: 추가 클럭을 주기위해 쓰레기값을 보냄

        miso = spi.xfer2(data_Q84)  # miso data: 먼저 보낸 수가 낮은 클래스 수임.
        # Normal(high -> low data) ->
        # toeoutB -> toeoutS -> toeinB -> toeinS 순으로
    output = []
    for i in range(3, 8):
        if (miso[2 * i - 1] & 0x10) >> 4:  # int16 기준으로 음수일때
            output.append(
                int(((miso[2 * i - 1] & 0x0F) << 8) | miso[2 * i]) - 4096
            )  # 8bit & 8bit로 된 데이터를 하나의 int로 합성
        else:
            output.append(int(((miso[2 * i - 1] & 0x0F)) | miso[2 * i]))

    #output = np.array(output)
    output = softmax(np.array(output))

    recent = float((time.time() - past) * 1000)  # millisecond unit
    print("Norm & Transaction time: {:.2f}ms".format(recent))  # time print

    return output  # final output: 5 data list


def softmax(x):
    x_off = np.exp(x - np.max(x))
    return x_off / np.sum(x_off)
    # return x_off - np.log(np.sum(np.exp(x_off)))
