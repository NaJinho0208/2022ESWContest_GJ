"""
SensorData Code Ver.3
    * USE FIFO
    * USE BLUETOOTH: BLUETOOTH FUNCTIONS INCLUDED
    * function file separated, this file only include main funciton.

** Line Info:
Purple: SCL
Grey:   SDA
White:  GND
Black:  VDD

** Pin Info:
2  4  6  8 10 12 14 .... 38 40 >>
1  3  5  7  9 11 13 .... 37 39 >> USB Port Side

*I2C
VDD(3.3V):  1, 17
GND:        6, 9, 14
SDA:        3
SCL:        5

*SPI
SCLK:       23
MISO:       21
MOSI:       19
CE0(SS0):   24
CE1(SS1):   26

"""

from datetime import datetime
import pandas as pd
import os
import sys
import numpy as np
import time
import scipy.fftpack as fft
import sensordata_functions_ver2 as func
import gait_plot as plt
from bluetooth import *
import socket as sk

log_path = "/home/jongsul/Documents/Data_Log"

## main function
def main():

    getdata_unit = 32

    left_data_axis = np.empty((6, 1024), float)
    right_data_axis = np.empty((6, 1024), float)
    left_fft = np.empty((6, 180), float)  # variable for fft data
    right_fft = np.empty((6, 180), float)  # variable for fft data

    loop_max = 1  # max loop

    # Bluetooth socket open
    socket = BluetoothSocket(RFCOMM)
    socket.connect(("98:DA:60:01:49:3A", 1))  # LEFT HC-06 MAC address
    print("Left Foot bluetooth connected!")
    socket1 = BluetoothSocket(RFCOMM)
    socket1.connect(("98:DA:60:01:AC:EC", 1))  # RIGHT HC-06 MAC address
    print("Right Foot bluetooth connected!")

    left_data = []
    right_data = []
    output_list = []  # final class data
    spectrogram = np.empty(shape=0)  # final spectrogram data

    # ONE SPECTROGRAM LOOP START POINT
    loop_count = 0
    while loop_count < loop_max:
        # DATA FETCHING AREA: 32 sample * 32 loop = 1024 sample
        for j in range(int(1024 / getdata_unit)):
            left_data.clear()
            right_data.clear()
            past = time.time()  # time measure

            try:
                socket.send((1).to_bytes(1, byteorder="little"))  # 아두이노에게 시작 신호 전송
                socket1.send((1).to_bytes(1, byteorder="little"))  # 아두이노에게 시작 신호 전송
                func.btgetarray(socket, left_data, 384)
                func.btgetarray(socket1, right_data, 384)
                # print(data)
                # print("length of data: " + str(len(left_data)))
            except KeyboardInterrupt:
                print("Finished")

            #print("length of left data: " + str(len(left_data)))
            #print("length of right data: " + str(len(right_data)))
            print("receiving : " + str(j))
            # recent = float((time.time() - past) * 1000)  # millisecond unit
            # print("{} * {} amount sample I/O time: {:.2f}ms".format(j, getdata_unit, recent))

            # past = time.time()  # time measure

            func.data_processing(
                left_data,
                right_data,
                getdata_unit,
                j,
                left_data_axis,
                right_data_axis,
                left_fft,
                right_fft,
            )
            # recent = float((time.time() - past) * 1000)  # millisecond unit
            # print(
            #    "{} * {} amount sample waiting time: {:.2f}ms".format(j, getdata_unit, recent)
            # )  # time print

        # DATA PROCESSING AREA
        output_list.clear()
        spectrogram_old = spectrogram
        spectrogram = np.concatenate((left_fft, right_fft), axis=0)

        output_list = func.data2spi(spectrogram, False)
        if loop_count != 0:
            print(output_list)
            plt.gait_plot(spectrogram_old, np.array(output_list))
            print("one spectrogram finished.")
        recent = float((time.time() - past) * 1000)  # millisecond unit
        print("end of one sample waiting time: {:.2f}ms".format(recent))  # time print

        # convert numpy array to pandas dataframe
        """
        left_data_axis = left_data_axis * 333
        right_data_axis *= 333
        df = pd.DataFrame(np.concatenate((left_data_axis, right_data_axis), axis=0))
        df.to_csv(
            os.path.join(
                log_path, datetime.now().strftime("%Y-%m-%d_%H-%M-%S") + "_raw.csv"
            ),
            index=False,
        )

        df = pd.DataFrame(spectrogram)
        df.to_csv(
            os.path.join(
                log_path, datetime.now().strftime("%Y-%m-%d_%H-%M-%S") + "_fft.csv"
            ),
            index=False,
        )
        """

        loop_count += 1  # loop count increment

    # ONE SPECTROGRAM LOOP END

    # final data receiving & display
    output_list = func.data2spi(spectrogram, True)
    print(output_list)
    plt.gait_plot(spectrogram, np.array(output_list))
    print("final spectrogram finished.")

    return 0


## main function start
if __name__ == "__main__":
    main()
