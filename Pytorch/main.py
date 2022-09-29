import argparse
import os
import time
import logging
import torch
import torch.nn as nn
import torch.nn.parallel
import torch.backends.cudnn as cudnn
import torch.optim
import torch.utils.data
import models
from torch.autograd import Variable
from torchvision import transforms
from CustomDataset import CustomDataset
from preprocess import get_transform
from utils import *
from datetime import datetime
from ast import literal_eval
from torchvision.utils import save_image
import numpy as np
from torchsummary_use import summary
import csv

# 추가된 dataset 이용

# make download available 
import ssl
ssl._create_default_https_context = ssl._create_unverified_context

# 파일 디렉토리: trainset과 testset이 들어가 있는 폴더 이름 지정
os.chdir(os.path.dirname(os.path.realpath(__file__)))
file_dir = "./dataset"

model_names = sorted(name for name in models.__dict__
                     if name.islower() and not name.startswith("__")
                     and callable(models.__dict__[name]))

parser = argparse.ArgumentParser(description='PyTorch ConvNet Training')

parser.add_argument('--results_dir', metavar='RESULTS_DIR', default='./results_BNN',
                    help='results dir')
parser.add_argument('--save', metavar='SAVE', default='',
                    help='saved folder')
parser.add_argument('--dataset', metavar='DATASET', default='CustomDataset',
                    help='dataset name or folder')
parser.add_argument('--model', '-a', metavar='MODEL', default='alexnet_BNN_Custom_best',
                    choices=model_names,
                    help='model architecture: ' +
                    ' | '.join(model_names) +
                    ' (default: alexnet)')
parser.add_argument('--input_size', type=int, default=None,
                    help='image input size')
parser.add_argument('--model_config', default='',
                    help='additional architecture configuration')
parser.add_argument('--type', default='torch.cuda.FloatTensor',         # torch.cuda.FloatTensor, torch.FloatTensor(summary 부분: cpu, cuda 변경)
                    help='type of tensor - e.g torch.cuda.HalfTensor')
parser.add_argument('--gpus', default='0',
                    help='gpus used for training - e.g 0,1,3')
parser.add_argument('-j', '--workers', default=4, type=int, metavar='N',
                    help='number of data loading workers (default: 4)')
parser.add_argument('--epochs', default=200, type=int, metavar='N',
                    help='number of total epochs to run')
parser.add_argument('--start-epoch', default=0, type=int, metavar='N',
                    help='manual epoch number (useful on restarts)')
parser.add_argument('-b', '--batch-size', default=128, type=int,
                    metavar='N', help='mini-batch size (default: 25)')
parser.add_argument('--optimizer', default='SGD', type=str, metavar='OPT',
                    help='optimizer function used')
parser.add_argument('--lr', '--learning_rate', default=0.01, type=float,
                    metavar='LR', help='initial learning rate')
parser.add_argument('--momentum', default=0.9, type=float, metavar='M',
                    help='momentum')
parser.add_argument('--weight-decay', '--wd', default=1e-4, type=float,
                    metavar='W', help='weight decay (default: 1e-4)')
parser.add_argument('--print-freq', '-p', default=10, type=int,
                    metavar='N', help='print frequency (default: 10)')
parser.add_argument('--resume', default='', type=str, metavar='PATH',
                    help='path to latest checkpoint (default: none)')
parser.add_argument('-e', '--evaluate', type=str, metavar='FILE', default='./model_best.pth',
                    help='evaluate model FILE on validation set')

def main():
    global args, best_prec1, confusion_matrix, pred_list, feature1_out
    best_prec1 = 0
    args = parser.parse_args()

    #torch.use_deterministic_algorithms(True)
    #torch.backends.cudnn.benchmark = False
    cudnn.deterministic=True

    if args.evaluate:
        args.results_dir = './eval'
    if args.save == '':
        args.save = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    save_path = os.path.join(args.results_dir, args.save)
    if not os.path.exists(save_path):
        os.makedirs(save_path)
        os.makedirs(save_path + '/checkpoint')

    setup_logging(os.path.join(save_path, 'log.txt'))
    results_file = os.path.join(save_path, 'results.%s')
    results = ResultsLog(results_file % 'csv', results_file % 'html')

    logging.info("saving to %s", save_path)
    logging.debug("run arguments: %s", args)

    if 'cuda' in args.type:
        args.gpus = [int(i) for i in args.gpus.split(',')]
        torch.cuda.set_device(args.gpus[0])
        logging.info(torch.cuda.set_device(args.gpus[0]))
        cudnn.benchmark = True
        logging.info("CUDA")
    else:
        args.gpus = None
        logging.info("NonCUDA")

    # create model
    logging.info("creating model %s", args.model)
    model = models.__dict__[args.model]
    model_config = {'input_size': args.input_size, 'dataset': args.dataset}

    if args.model_config != '':
        model_config = dict(model_config, **literal_eval(args.model_config))

    model = model(**model_config)
    logging.info("created model with configuration: %s", model_config)

    # optionally resume from a checkpoint
    if args.evaluate:
        if not os.path.isfile(args.evaluate):
            parser.error('invalid checkpoint: {}'.format(args.evaluate))
        checkpoint = torch.load(args.evaluate)
        model.load_state_dict(checkpoint['state_dict'])
        logging.info("loaded checkpoint '%s' (epoch %s)",
                     args.evaluate, checkpoint['epoch'])
    elif args.resume:
        checkpoint_file = args.resume
        if os.path.isdir(checkpoint_file):
            results.load(os.path.join(checkpoint_file, 'results.csv'))
            checkpoint_file = os.path.join(
                checkpoint_file, 'model_best.pth')
        if os.path.isfile(checkpoint_file):
            logging.info("loading checkpoint '%s'", args.resume)
            checkpoint = torch.load(checkpoint_file)
            args.start_epoch = checkpoint['epoch'] - 1
            best_prec1 = checkpoint['best_prec1']
            model.load_state_dict(checkpoint['state_dict'])
            logging.info("loaded checkpoint '%s' (epoch %s)",
                         checkpoint_file, checkpoint['epoch'])
        else:
            logging.error("no checkpoint found at '%s'", args.resume)

    num_parameters = sum([l.nelement() for l in model.parameters()])
    logging.info("number of parameters: %d", num_parameters)

    # Data loading code
    default_transform = {
        'train': get_transform(args.dataset,
                               input_size=args.input_size, augment=True),
        'eval': get_transform(args.dataset,
                              input_size=args.input_size, augment=False)
    }
    transform = getattr(model, 'input_transform', default_transform)
    regime = getattr(model, 'regime', {0: {'optimizer': args.optimizer,
                                           'lr': args.lr,
                                           'momentum': args.momentum,
                                           'weight_decay': args.weight_decay}})
    # define loss function (criterion) and optimizer
    criterion = getattr(model, 'criterion', nn.CrossEntropyLoss)()
    criterion.type(args.type)
    model.type(args.type)

    ''' mean and standard (왼발이 먼저)
    Trainset - 16883 / Testset - 4199
    <Left foot>
    AccX - mean: 0.022864 / std: 0.039005
    AccY - mean: 0.016581 / std: 0.023538
    AccZ - mean: 0.018955 / std: 0.032722
    GyroX - mean: 1.9266 / std: 3.4016
    GyroY - mean: 3.6982 / std: 7.8508
    GyroZ - mean: 1.6796 / std: 3.3401
    <Right foot>
    AccX - mean: 0.02268 / std: 0.036059
    AccY - mean: 0.016511 / std: 0.024486
    AccZ - mean: 0.019214 / std: 0.03225
    GyroX - mean: 2.0609 / std: 3.5045
    GyroY - mean: 3.725 / std: 7.7277
    GyroZ - mean: 1.6977 / std: 3.3724
    '''

    # 평균 및 표준편차 정의(왼발이 먼저)
    dataset_mean = [0.022864, 0.016581, 0.018955, 1.9266, 3.6982, 1.6796,
                    0.02268, 0.016511, 0.019214, 2.0609, 3.725, 1.6977]

    dataset_std = [0.039005, 0.023538, 0.032722, 3.4016, 7.8508, 3.3401,
                   0.036059, 0.024486, 0.03225, 3.5045, 7.7277, 3.3724]

    datatrans = transforms.Compose([
        # transforms.ToTensor(),
        transforms.Normalize(mean=dataset_mean, std=dataset_std)
    ])

    '''val_data = get_dataset(args.dataset, 'val', transform['eval'])
    val_loader = torch.utils.data.DataLoader(
        val_data,
        batch_size=args.batch_size, shuffle=False,
        num_workers=args.workers, pin_memory=True)'''
    
    logging.info("dataset: " + file_dir)
    val_data = CustomDataset(filenames = file_dir + "/Testset", transform=datatrans, shuffle=False, fixed_fraction=4, fixed_int=4)
    val_loader = torch.utils.data.DataLoader(val_data, batch_size=args.batch_size, shuffle=False, pin_memory=False)
    confusion_matrix = torch.zeros(len(val_data.__getclass__()), len(val_data.__getclass__()))
    print(confusion_matrix.shape)

    logging.info("batch_size: %d", args.batch_size)
    logging.info("val_data: %d", val_data.__len__())
    logging.info("val_loader: %d", val_loader.__len__())

    # evalutate만 할 때 결과 출력
    if args.evaluate:
        # Model Summary
        result = summary(model, (12,12,15), args.batch_size, device="cuda")
        tmp1 = result.split("\n")
        for i in range(tmp1.__len__()):
            logging.info(tmp1[i])

        val_loss, val_prec1, val_prec5, correct_pred, total_pred = validate(
            val_loader, model, criterion, epoch=checkpoint['epoch'], classes=val_data.__getclass__())

        print(correct_pred.shape)
        print(total_pred.shape)

        # 전체 정확도
        correct_num = 0
        for classname, correct_count in correct_pred.items():
            correct_num += correct_count
        logging.info('\n\t Epoch: {} \t'
                     'Average loss: {:.4f} \t'
                     'Accuracy: {}/{} ({:.3f}%) \n'
                     .format(checkpoint['epoch'], val_loss, correct_num, val_data.__len__(),
                     100*float(correct_num)/val_data.__len__()))

        # Class별 정확도
        for classname, correct_count in correct_pred.items():
            accuracy = 100 * float(correct_count) / total_pred[classname]
            logging.info('\t Accuracy for class {:7s} is: {:.3f} % -- {}/{}'
                         .format(classname, accuracy, correct_count, total_pred[classname]))

        return

    # if args.evaluate:
    #     validate(val_loader, model, criterion, 0)
    #     return

    '''train_data = get_dataset(args.dataset, 'train', transform['train'])
    train_loader = torch.utils.data.DataLoader(
        train_data,
        batch_size=args.batch_size, shuffle=True,
        num_workers=args.workers, pin_memory=True)'''
    
    train_data = CustomDataset(filenames = file_dir + "/Trainset", transform=datatrans, shuffle=True)
    train_loader = torch.utils.data.DataLoader(train_data, batch_size=args.batch_size, shuffle=True, pin_memory=True)
    logging.info("train_data: %d", train_data.__len__())
    logging.info("train_loader: %d", train_loader.__len__())

    optimizer = torch.optim.Adam(model.parameters(), lr=args.lr)
    logging.info('training regime: %s', regime)

    # Torch Summary
    result = summary(model, (12,12,15), args.batch_size, device="cuda")
    tmp1 = result.split("\n")
    for i in range(tmp1.__len__()):
        logging.info(tmp1[i])

    # Start Time
    st = time.time()
    
    # Classes 설정
    classes = val_data.__getclass__()

    for epoch in range(args.start_epoch, args.epochs):
        optimizer = adjust_optimizer(optimizer, epoch, regime)

        # train for one epoch
        train_loss, train_prec1, train_prec5, _, _ = train(
            train_loader, model, criterion, epoch, optimizer)

        # evaluate on validation set
        val_loss, val_prec1, val_prec5, correct_pred, total_pred = validate(
            val_loader, model, criterion, epoch, classes=classes)

        # remember best prec@1 and save checkpoint
        is_best = val_prec1 > best_prec1
        best_prec1 = max(val_prec1, best_prec1)
        
        save_checkpoint({
                'epoch': epoch + 1,
                'model': args.model,
                'config': args.model_config,
                'state_dict': model.state_dict(),
                'best_prec1': best_prec1,
                'regime': regime
            }, is_best, path=save_path)            
            
        logging.info('\n Epoch: {0}\t'
                     'Training Loss {train_loss:.4f} \t'
                     'Training Prec@1 {train_prec1:.3f} \t'
                     'Training Prec@3 {train_prec5:.3f} \t'
                     'Validation Loss {val_loss:.4f} \t'
                     'Validation Prec@1 {val_prec1:.3f} \t'
                     'Validation Prec@3 {val_prec5:.3f} \n'
                     .format(epoch + 1, train_loss=train_loss, val_loss=val_loss,
                             train_prec1=train_prec1, val_prec1=val_prec1,
                             train_prec5=train_prec5, val_prec5=val_prec5))

        ### 추가: class 별 결과 확인
        # 전체 정확도
        correct_num = 0
        for classname, correct_count in correct_pred.items():
            correct_num += correct_count
        logging.info('\t Epoch: {} \t'
                     'Average loss: {:.4f} \t'
                     'Accuracy: {}/{} ({:.3f}%)'
                     .format(epoch + 1, val_loss, correct_num, val_data.__len__(),
                     100*float(correct_num)/val_data.__len__()))

        # Class별 정확도
        for classname, correct_count in correct_pred.items():
            accuracy = 100 * float(correct_count) / total_pred[classname]
            logging.info('\t Accuracy for class {:7s} is: {:.3f} % -- {}/{}'
                         .format(classname, accuracy, correct_count, total_pred[classname]))
        logging.info('\n')

        results.add(epoch=epoch + 1, train_loss=train_loss, val_loss=val_loss,
                    train_error1=100 - train_prec1, val_error1=100 - val_prec1,
                    train_error5=100 - train_prec5, val_error5=100 - val_prec5)
                    
        results.save()

    logging.info("Time elapsed: %ds", time.time() - st)

def forward(data_loader, model, criterion, epoch=0, training=True, optimizer=None, clss=None):
    if args.gpus and len(args.gpus) > 1:
        model = torch.nn.DataParallel(model, args.gpus)
    
    if not training:
        # 추가: 각 분류(class)에 대한 예측값 계산을 위해 준비
        correct_pred = {classname: 0 for classname in clss}
        total_pred = {classname: 0 for classname in clss}
        y_pred = []
        y_true = []
    else:
        correct_pred = {}
        total_pred = {}

    batch_time = AverageMeter()
    data_time = AverageMeter()
    losses = AverageMeter()
    top1 = AverageMeter()
    top5 = AverageMeter()

    end = time.time()
    for i, (inputs, target) in enumerate(data_loader):
        # measure data loading time
        data_time.update(time.time() - end)
        if args.gpus is not None:
            target = target.cuda()

        if not training:
            with torch.no_grad():
                input_var = Variable(inputs.type(args.type), volatile=not training)
                target_var = Variable(target)
                # compute output
                output, _ = model(input_var)
                # 추가: class별 accuracy
                _, predictions = torch.max(output, 1)
                for label, prediction in zip(target_var, predictions):
                    if label == prediction:
                        correct_pred[clss[label]] += 1
                    total_pred[clss[label]] += 1
                    y_pred.extend(target_var)
                    y_true.extend(prediction)

        else:
            input_var = Variable(inputs.type(args.type), volatile=not training)
            target_var = Variable(target)
            # compute output
            output, _ = model(input_var)
            # output, outputList = model(input_var)

        # outputList = np.array(outputList.cpu())
        # temp1 = outputList[0].cpu().detach().numpy()
        # temp2 = outputList[0].cpu().detach().numpy()
        # temp3 = outputList[0].cpu().detach().numpy()
        # temp4 = outputList[0].cpu().detach().numpy()
        # temp5 = outputList[0].cpu().detach().numpy()
        # temp6 = outputList[0].cpu().detach().numpy()
        # outputList.clear()

        loss = criterion(output, target_var)
        if type(output) is list:
            output = output[0]

        # measure accuracy and record loss
        prec1, prec5 = accuracy(output.data, target, topk=(1, 3))
        losses.update(loss.item(), inputs.size(0))
        top1.update(prec1.item(), inputs.size(0))
        top5.update(prec5.item(), inputs.size(0))

        if training:
            # compute gradient and do SGD step
            optimizer.zero_grad()
            loss.backward()
            for p in list(model.parameters()):
                if hasattr(p,'org'):
                    p.data.copy_(p.org)
            optimizer.step()
            for p in list(model.parameters()):
                if hasattr(p,'org'):
                    p.org.copy_(p.data.clamp_(-1,1))


        # measure elapsed time
        batch_time.update(time.time() - end)
        end = time.time()

        if i % args.print_freq == 0:
            logging.info('{phase} - Epoch: [{0}][{1}/{2}]\t'
                         'Time {batch_time.val:.3f} ({batch_time.avg:.3f})\t'
                         'Data {data_time.val:.3f} ({data_time.avg:.3f})\t'
                         'Loss {loss.val:.4f} ({loss.avg:.4f})\t'
                         'Prec@1 {top1.val:.3f} ({top1.avg:.3f})\t'
                         'Prec@3 {top5.val:.3f} ({top5.avg:.3f})'.format(
                             epoch, i, len(data_loader),
                             phase='TRAINING' if training else 'EVALUATING',
                             batch_time=batch_time,
                             data_time=data_time, loss=losses, top1=top1, top5=top5))

    return losses.avg, top1.avg, top5.avg, correct_pred, total_pred


def train(data_loader, model, criterion, epoch, optimizer):
    # switch to train mode
    model.train()
    return forward(data_loader, model, criterion, epoch,
                   training=True, optimizer=optimizer)


def validate(data_loader, model, criterion, epoch, classes):
    # switch to evaluate mode
    model.eval()
    return forward(data_loader, model, criterion, epoch,
                   training=False, optimizer=None, clss=classes)


if __name__ == '__main__':
    main()
