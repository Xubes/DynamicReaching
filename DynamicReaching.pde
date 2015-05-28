import g4p_controls.*;
import processing.serial.*;

/*
Master control program for Dynamic Reaching task.  Reads sensor data from Arduino sensor
on the axel of a rotating chair and uses it to precisely rotate a the chair 180 degrees.
Each trial consists of two rotations: 180 degrees in one direction and then another in the
opposite direction to return the chair facing the starting location.
Must be able to maintain precision in 60+ trials.
*/

Serial serialPort;
double angleDelta;  // this will hold the angle of the chair (output from Arduino)
double angularVelocity, angularAcceleration, angularJerk;
long lastCommandTime;
int lastCommand;  // store the last command sent
static final int COMMAND_INTERVAL = 10;  // milliseconds between commands
static final double EPS = 1e-9;

void setup(){
  size(300,400);
  createGUI();
  System.out.println("Starting...");
  
  // Look for serial port to open.
  String[] availablePorts = Serial.list();
  for(String p : availablePorts){
    if(match(p,"tty.usbmodemfa131")!=null){
      serialPort = new Serial(this, p, 115200);
    }
  }
  // Error if unable to open serial port
  if(serialPort==null){
    System.err.println("Unable to open Serial port!");
    exit();
  }
  
  // Set serial port to buffer until newline.
  serialPort.bufferUntil(10);
  
  angleDelta = 0.0;
  angularVelocity = 0.0;
  lastCommandTime = millis();
}

void draw(){
  background(255);
  fill(255,0,0);
  txtArea.setText(String.format("%.3f\n%.3f",angleDelta,angularVelocity));
}

/* Update angleDelta and angularVelocity whenever data is available on the serial port. */
void serialEvent(Serial s){
  String str = trim(s.readString());
  String[] tokens = splitTokens(str,",");
  try{
    angleDelta = Double.parseDouble(tokens[0]);
    angularVelocity = Double.parseDouble(tokens[1]);
  }
  catch(Exception e){
    System.err.println("Unable to parse input : " + str);
  }
}

/* Sends command to reset Arduino's angle_delta value. */
void resetAngle(){
  if(serialPort==null) return;
  serialPort.write("0\n");
}

/* Get the sign of an int.  Returns one of {-1,0,1}. */
int sign(int n){
  if(n>0) return 1;
  else if(n<0) return -1;
  else return 0;
}

/* Get the sign of a double. Returns one of {-1.0, 0.0, 1.0}. */
double sign(double n){
  if(n>0.0) return 1.0;
  else if(n<0.0) return -1.0;
  else return 0.0;
}

/* Spin the chair 180 degrees. Sends motor commands to standard output which should be piped
    to the actionbot program.
   Direction specifies direction of spin: positive for clockwise.
   Speed is the minimum degrees per second at which to rotate the chair. Motor power will be
   adjusted until the rotation speed equals or exceeds the given speed.
   Speed will be overridden if the desired speed cannot be achieved with the given acceleration
   for a 180 degree rotation.
 */
int chairMotor = 3;    // actionbot code for chair motor
int acceleration = 2;
void spin180(int direction, double speed){
  resetAngle();
  int power = 50; // starting power level for chair motor.
  
  // busy block to make sure angular velocity is near-zero.
  while(angularVelocity > 0.5){ }
  
  /* Increment power until desired velocity is reached. */
  double prevVelocity = angularVelocity;  // use to check if accelerating
  sendCommandF(chairMotor, power);
  // wait until acceleration is detected
  while( abs(angularVelocity-prevVelocity) < EPS){
    prevVelocity = angularVelocity;
    redraw();
  }
  while( (angularVelocity < speed) && (angleDelta < 90) ){
    // just a precaution...
    if(power >= 150){
      sendCommandF(chairMotor, 10);
      System.err.println("Motor power exceeded safe level.");
      return;
    }
    
    // don't send a new command if chair is accelerating
    if( (angularVelocity-prevVelocity) > EPS){
      prevVelocity = angularVelocity;
      continue;
    }
    else{
      power += acceleration;
      sendCommandF(chairMotor, power);
      // wait until acceleration is detected
      while( (angularVelocity-prevVelocity) < EPS){
        prevVelocity = angularVelocity;
        redraw();
      }
    }
  }
  
  // degrees required for deceleration (should be about same as for acceleration)
  double degs4decel = angleDelta+10;
  
  // maintain speed until time to decelerate
  prevVelocity = angularVelocity;
  while( angleDelta < (180 - degs4decel) ){
    // only send command if chair is slowing down
    if( (angularVelocity-prevVelocity) < -EPS ){
      sendCommand(chairMotor, power);
    }
  }
  
  // decelerate
  while(power > 0 && angleDelta < 180){
    power -= acceleration;
    sendCommand(chairMotor, power);
  }
  
  // send brake command
  sendCommand(chairMotor, 0);
}

/* Format commands to std out for actionbot program.
   Keeps track of time since last command to prevent flooding the motor.
   Returns true when command written, false otherwise.
   Blocks until some time has passed.
*/
boolean sendCommand(int motor, int power){
  long now = millis();
  // make sure "enough" time has elapsed since last command time
  if( (now-lastCommandTime) > COMMAND_INTERVAL ){
    sendCommandF(motor, power);
    return true;
  }
  return false;
}

/* Forceful version of sendCommand.  Writes command immediately. */
void sendCommandF(int motor, int power){
  System.out.println(String.format("%d %d %d", motor, power, COMMAND_INTERVAL));
  lastCommand = power;
  lastCommandTime = millis();
}
