import numpy as np
import pandas as pd
import os
import matplotlib.pyplot as plt

def gait_plot(input_data, class_data):

    data = np.zeros(shape=(12,15,12))
    for i in range(12):
        tmp1 = input_data[i,:].reshape(15,12)
        tmp2 = np.transpose(tmp1)
        data[:,:,i] = tmp2

    cmax_AccX = 0.7;    cmax_AccY = 0.2;    cmax_AccZ = 0.7
    cmax_GyroX = 55;    cmax_GyroY = 75;    cmax_GyroZ = 40

    data[:,:,0] /= cmax_AccX
    data[:,:,1] /= cmax_AccY
    data[:,:,2] /= cmax_AccZ
    data[:,:,3] /= cmax_GyroX
    data[:,:,4] /= cmax_GyroY
    data[:,:,5] /= cmax_GyroZ
    data[:,:,6] /= cmax_AccX
    data[:,:,7] /= cmax_AccY
    data[:,:,8] /= cmax_AccZ
    data[:,:,9] /= cmax_GyroX
    data[:,:,10] /= cmax_GyroY
    data[:,:,11] /= cmax_GyroZ
    
    plt.ioff()
    
    plt.figure(1, figsize=(15, 5))

    plt.subplots_adjust(hspace=0.2, wspace=0.1)
    gridshape = (3,6)

    size_t = 5

    loc=(0,0); plt.subplot2grid(gridshape, loc)
    plt.pcolor(data[:,:,0], vmin=0, vmax=1);    plt.axis('off'); plt.title('L_AccX', fontsize=size_t)

    loc=(1,0); plt.subplot2grid(gridshape, loc)
    plt.pcolor(data[:,:,1], vmin=0, vmax=1);    plt.axis('off'); plt.title('L_AccY', fontsize=size_t)

    loc=(2,0); plt.subplot2grid(gridshape, loc)
    plt.pcolor(data[:,:,2], vmin=0, vmax=1);    plt.axis('off'); plt.title('L_AccZ', fontsize=size_t)

    loc=(0,1); plt.subplot2grid(gridshape, loc)
    plt.pcolor(data[:,:,3], vmin=0, vmax=1);    plt.axis('off'); plt.title('L_GyroX', fontsize=size_t)

    loc=(1,1); plt.subplot2grid(gridshape, loc)
    plt.pcolor(data[:,:,4], vmin=0, vmax=1);    plt.axis('off'); plt.title('L_GyroY', fontsize=size_t)

    loc=(2,1); plt.subplot2grid(gridshape, loc)
    plt.pcolor(data[:,:,5], vmin=0, vmax=1);    plt.axis('off'); plt.title('L_GyroZ', fontsize=size_t)

    loc=(0,2); plt.subplot2grid(gridshape, loc)
    plt.pcolor(data[:,:,6], vmin=0, vmax=1);    plt.axis('off'); plt.title('R_AccX', fontsize=size_t)

    loc=(1,2); plt.subplot2grid(gridshape, loc)
    plt.pcolor(data[:,:,7], vmin=0, vmax=1);    plt.axis('off'); plt.title('R_AccY', fontsize=size_t)

    loc=(2,2); plt.subplot2grid(gridshape, loc)
    plt.pcolor(data[:,:,8], vmin=0, vmax=1);    plt.axis('off'); plt.title('R_AccZ', fontsize=size_t)

    loc=(0,3); plt.subplot2grid(gridshape, loc)
    plt.pcolor(data[:,:,9], vmin=0, vmax=1);    plt.axis('off'); plt.title('R_GyroX', fontsize=size_t)

    loc=(1,3); plt.subplot2grid(gridshape, loc)
    plt.pcolor(data[:,:,10], vmin=0, vmax=1);   plt.axis('off'); plt.title('R_GyroY', fontsize=size_t)

    loc=(2,3); plt.subplot2grid(gridshape, loc)
    plt.pcolor(data[:,:,11], vmin=0, vmax=1);   plt.axis('off'); plt.title('R_GyroZ', fontsize=size_t)

    # Output Data
    max_index = np.argmax(class_data)

    if max_index == 0:
        top_y = 0.65
    elif max_index == 1: 
        top_y = 0.50
    elif max_index == 2: 
        top_y = 0.35
    elif max_index == 3: 
        top_y = 0.20
    else: 
        top_y = 0.05

    top_box = {'facecolor': 'y',
               'boxstyle': 'round',
               'alpha': 0.5}

    title_font = {'color': 'black',
              'weight': 'bold',
              'size': 20,
              'alpha': 0.7}

    class_font = {'color': 'black',
              'size': 16,
              'alpha': 0.7}

    top_font = {'color': 'red',
              'size': 13,
              'weight': 'bold',
              'alpha': 0.7}

    loc=(0,4); plt.subplot2grid(gridshape, loc, rowspan=3, colspan=2)

    plt.text(0.5, 0.85, '[Classification]', fontdict=title_font, horizontalalignment='center')
    plt.text(0.15, 0.65, 'Normal: {:.2f}'.format(class_data[0]), fontdict=class_font, bbox=top_box if max_index==0 else None)
    plt.text(0.15, 0.50, 'Toeout_B: {:.2f}'.format(class_data[1]), fontdict=class_font, bbox=top_box if max_index==1 else None)
    plt.text(0.15, 0.35, 'Toeout_S: {:.2f}'.format(class_data[2]), fontdict=class_font, bbox=top_box if max_index==2 else None)
    plt.text(0.15, 0.20, 'Toein_B: {:.2f}'.format(class_data[3]), fontdict=class_font, bbox=top_box if max_index==3 else None)
    plt.text(0.15, 0.05, 'Toein_S: {:.2f}'.format(class_data[4]), fontdict=class_font, bbox=top_box if max_index==4 else None)
    plt.text(0.10, top_y+0.07, 'TOP', fontdict=top_font)
    plt.axis('off')

    plt.tight_layout()
    #plt.draw()
    plt.show()
    plt.pause(0.001)

