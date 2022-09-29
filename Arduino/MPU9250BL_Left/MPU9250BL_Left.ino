/*****************************
 * MPU9250 Bluetooth Sensor VERSION: LEFT FOOT Sensor code
 */
#include "Wire.h"
#include "I2Cdev.h"
#include "MPU9250.h"


/*********** 샘플레이트 설정 **************
 *  레지스터 별 비트 라벨(필요한 성분만 표시)
 *  0x19    SMPLRT_DIV[7:0]     # 이 값 + 1로 sample freq.를 나누어 최종 sample freq.를 결정한다.
 *  0x1A    DLPF_CFG[2:0]       # 자이로스코프 Digital LPF의 Cutoff freq. 조절
 *  0x1B    GYRO_FS_SEL[4:3]    # 자이로스코프의 스케일 설정
 *          Fchoice_b[1:0]      # 자이로스코프 DLPF 사용 여부
 *  0x1C    ACCEL_FS_SEL[4:3]   # 가속도계의 스케일 설정
 *  0x1D    accel_fchoice_b[3]  # 가속도계의 DLPF 사용 여부
 *          A_DLPFCFG[2:0]      # 가속도계의 DLPF Cutoff freq. 조절
 *  최종 샘플레이트: internal_sample_rate / (1 + SMPLRT_DIV)
 *  internal_sample_rate: 32kHz(Fchoice_b = 0b11일 때)
 *                         8kHz(Fchoice_b = 0b00, DLPF_CFG = 0, 7일 때)
 *                         1kHz(Fchoice_b = 0b00, DLPF_CFG = 1 ~ 6일 때) << 이때만 샘플레이트 조절이 가능
 *  목표: 333Hz = 1kHz / 3
 *  SMPLRT_DIV = 2(0x2), DLPF_CFG = 0b001(BW = 184Hz), Fchoice_b = 0b00(기본이 0이라 건들필요 X)
 *  GYRO_FS_SEL = 0b00(+250degree/s), ACCEL_FS_SEL = 0b01(+4g)
//
 ****************************************/

/*********** mpu9250.h functions **************
 *  bool getFIFOEnabled();
    void setFIFOEnabled(bool enabled);
    bool testConnection();
    void resetFIFO();
 *  uint16_t getFIFOCount();
 *  uint8_t getFIFOByte();
 *  bool getTempFIFOEnabled();
    void setTempFIFOEnabled(bool enabled);
    bool getXGyroFIFOEnabled();
    void setXGyroFIFOEnabled(bool enabled);
    bool getYGyroFIFOEnabled();
    void setYGyroFIFOEnabled(bool enabled);
    bool getZGyroFIFOEnabled();
    void setZGyroFIFOEnabled(bool enabled);
    bool getAccelFIFOEnabled();
    void setAccelFIFOEnabled(bool enabled);
    void setFIFOByte(uint8_t data);
    void getFIFOBytes(uint8_t *data, uint8_t length);

    ********* FIFO Buffer 설정 *********
    * uint8_t fifobuffer에 FIFO 데이터를 저장함.
    * 1khz(1ms) 데이터를 500hz(2ms) 주기로 가져옴
    * 총 데이터:  Gyro X, Y, Z 각 16비트(2byte) => uint8_t * 6
    *           Accel X, Y ,Z 각 16bit(2byte) => uint8_t * 6
    * 위 데이터 *4 => 총 uint8_t * 12 * 4 = 48byte
    * FIFO Count가 24byte일 때 데이터를 가져오고 FIFO refresh
 */

// class default I2C address is 0x68
// specific I2C addresses may be passed as a parameter here
// AD0 low = 0x68 (default for InvenSense evaluation board)
// AD0 high = 0x69
//MPU9250 mpu_right(0x69);
MPU9250 mpu_left;
I2Cdev   I2C_M;

#define QUEUED_SAMPLE 32 // 한번에 긁어올 샘플 수
#define MAX_READBYTE_SIZE 48 // 한번에 긁어올수 있는 최대 바이트수(추정)

void getAccel_Data(uint8_t num);
void getGyro_Data(uint8_t num);

uint8_t deviceStatus; //device status , 0 = success , 
//int16_t fifoCountRight = 0; //count of all bytes currently in FIFO
int16_t fifoCountLeft = 0; //count of all bytes currently in FIFO
//int16_t fifoFlushCountRight = (12 * QUEUED_SAMPLE); // when fifoCount reach this value, flush data to serial
int16_t fifoFlushCountLeft = (12 * QUEUED_SAMPLE); // when fifoCount reach this value, flush data to serial
uint8_t fifoBuffer[12 * QUEUED_SAMPLE]; // FIFO buffer storage
int16_t AcX, AcY, AcZ, GyX, GyY, GyZ;
int16_t fifoMax = 512 - (512 % (12 * QUEUED_SAMPLE));   // Max size of data in FIFO
uint8_t loopcount = 0;
bool start_flag = false;

void setup()
{
    //join I2C bus 
    #if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE
        Wire.begin();
        Wire.setClock(400000);
        //TWBR = 48; // 400kHz I2C clock (200kHz if CPU is 8MHz)
    #elif I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_FASTWIRE
        Fastwire::setup(400, true);
    #endif
    //initialize serial communication
    Serial.begin(115200);
    Serial1.begin(115200);
    while(!Serial); //common for Leonardo issues
    
    //initialize the mpu 
    mpu_left.initialize(); //initialize I2C device by using MPU6050 library
    //mpu_right.initialize(); //initialize I2C device by using MPU6050 library 
    
      
    // FIFO 사용 설정 및 자이로/가속도계 데이터가 FIFO에 저장되도록 설정
    mpu_left.setFullScaleAccelRange(MPU9250_ACCEL_FS_4);   // accel scale: +-4g
    mpu_left.setDLPFMode(1); // sampling rate = 1kHz
    mpu_left.setRate(2); // sampling rate = 1khz/3 = 333Hz
    mpu_left.setFIFOEnabled(true);
    mpu_left.setXGyroFIFOEnabled(true);
    mpu_left.setYGyroFIFOEnabled(true);
    mpu_left.setZGyroFIFOEnabled(true);
    mpu_left.setAccelFIFOEnabled(true);
    mpu_left.setIntDataReadyEnabled(true);
    
    Serial.println("Left device connections");
    Serial.println(mpu_left.getRate() == 2);

    start_flag = true; // 시작신호 true

    mpu_left.resetFIFO();
}

void please_wait(int sec) {
    Serial.println("Program will start soon.");
    for(int i = 0; i < sec; i++) {
        Serial.print("Will Start after "); SerialUSB.print(sec - i); SerialUSB.print(" seconds...");
        Serial.println();
        delay(1000);
  }
}

void loop()
{
    uint16_t lp_time = 0;
    uint16_t past = micros();
    uint16_t bytecount = 0;

    // 라즈베리 파이로부터 신호가 오면 그때부터 측정 시작
    if(Serial1.available()) {
        if(start_flag == true) {
            mpu_left.resetFIFO(); // 가장 첫 루프에선 FIFO를 리셋하며 시작
            start_flag = false;
        }
        Serial1.read(); // flush read buffer
        
        fifoCountLeft = mpu_left.getFIFOCount();
        //Serial1.print("$"); Serial1.print(fifoBuffer[380]);
        // polling 필수: 데이터 다 찰 때까지 대기
        while(fifoCountLeft < (12 * QUEUED_SAMPLE))
        {
            fifoCountLeft = mpu_left.getFIFOCount();
            //Serial.print("$"); Serial.print(fifoCountLeft);
        }
        //Serial1.print("fifoCountIN: "); Serial1.println(fifoCount);
        past = micros(); 
        for(int i = 0; i < (QUEUED_SAMPLE / 4); i++)
        {
             mpu_left.getFIFOBytes((uint8_t *)(fifoBuffer + i * 48), MAX_READBYTE_SIZE);   
        }
        mpu_left.resetFIFO();
        /*
        for(int i = 0; i < QUEUED_SAMPLE; i++)
            {
            
            getAccel_Data(i);
            getGyro_Data(i);
            
            Serial1.print(AcX); 
            Serial1.print(",");
            Serial1.print(AcY); 
            Serial1.print(",");
            Serial1.print(AcZ); 
            Serial1.print(",");
            Serial1.print(GyX); 
            Serial1.print(",");
            Serial1.print(GyY); 
            Serial1.print(",");
            Serial1.print(GyZ); 
            if(i != QUEUED_SAMPLE-1) bytecount += Serial1.print(",");
            delay(1);
            

            }*/
        Serial1.write(fifoBuffer, 384);
        Serial1.flush();

        //bytecount += Serial1.print(lp_time); 
        //bytecount += Serial1.print("|");
       
        lp_time = (int16_t)(micros() - past);
        Serial.println(lp_time);

        if(loopcount >= 31) {
            loopcount = 0;
            start_flag = true;
        }
        else {
            loopcount++;
        }

   }
}



void getAccel_Data(uint8_t num)
{
    AcX = fifoBuffer[0 + num * 12] << 8 | fifoBuffer[1 + num * 12]; //두 개의 나뉘어진 바이트를 하나로 이어 붙여서 각 변수에 저장
    AcY = fifoBuffer[2 + num * 12] << 8 | fifoBuffer[3 + num * 12];
    AcZ = fifoBuffer[4 + num * 12] << 8 | fifoBuffer[5 + num * 12];
    
}
void getGyro_Data(uint8_t num)
{
    GyX = fifoBuffer[6 + num * 12] << 8 | fifoBuffer[7 + num * 12];
    GyY = fifoBuffer[8 + num * 12] << 8 | fifoBuffer[9 + num * 12];
    GyZ = fifoBuffer[10 + num * 12] << 8 | fifoBuffer[11 + num * 12];
}

/******************** OLD CODE
void loop()
{
    uint16_t lp_time;
    //testing overflow
    uint16_t past = micros(); 
    //fifoCount = mpu.getFIFOCount();

    
    while(digitalRead(9) == 0 && (fifoCount % (12 * QUEUED_SAMPLE) != 0)) // read the interrupt pin
    {
        fifoCount += 12;
    }
    
    //SerialUSB.println(fifoCount);
    if (fifoCount >= 512 - (512 % (12 * QUEUED_SAMPLE)) ) {
      mpu.resetFIFO();
      fifoCount = 0;
    } else {

    //wait for enough avaliable data length
    //while ((fifoCount - fifoCount_old) < (12 * QUEUED_SAMPLE)) {
      //waiting until get enough
      //fifoCount = mpu.getFIFOCount();
      //Serial.println(fifoCount);
    //}
    
    //read this packet from FIFO buffer 
    mpu.getFIFOBytes(fifoBuffer, 12 * QUEUED_SAMPLE);
    //mpu.resetFIFO();
    
    //track FIFO count here is more then one packeage avalible 

    //reset fifo count 
    //fifoCount -= 12 * QUEUED_SAMPLE ;
    
    //Serial.println(fifoCount);
    //display stage 
    
    for(int i = 0; i < QUEUED_SAMPLE; i++)
    {
      getAccel_Data(i);
      getGyro_Data(i);
      SerialUSB.print(AcX);
      SerialUSB.print(", ");
      SerialUSB.print(AcY);
      SerialUSB.print(", ");
      SerialUSB.print(AcZ);
      SerialUSB.print(", ");
      SerialUSB.print(GyX);
      SerialUSB.print(", ");
      SerialUSB.print(GyY);
      SerialUSB.print(", ");
      SerialUSB.print(GyZ);
      SerialUSB.println("");
    }
    lp_time = (int16_t)(micros() - past);
  }
  
  SerialUSB.println(lp_time);
  //fifoCount_old = fifoCount;
}

*/
